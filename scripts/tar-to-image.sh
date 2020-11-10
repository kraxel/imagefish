#!/bin/sh

######################################################################
# defaults

qcow=""
size="4G"
tarb=""
mode="efi-grub2"

size_uefi="128"
size_boot="384"
size_swap="512"

######################################################################
# create work dir

function msg() {
	local txt="$1"
	local bold="\x1b[1m"
	local normal="\x1b[0m"
	echo -e "${bold}### ${txt}${normal}"
}

function do_cleanup() {
	msg "cleaning up"
	if test "$GUESTFISH_PID" != ""; then
		guestfish --remote -- exit >/dev/null 2>&1 || true
	fi
	rm -rf "$WORK"
}

WORK="${TMPDIR-/var/tmp}/${0##*/}-$$"
mkdir "$WORK" || exit 1
trap 'do_cleanup' EXIT

# work files
script="$WORK/imagefish.script"
fstab="$WORK/fstab"
grubdef="$WORK/grub"
grubcfg="$WORK/grub.cfg"

# variables
rootfs=""
console=""
append="loglevel=5"

######################################################################
# parse args

function print_help() {
cat <<EOF
usage: $0 [ options ]
options:
  setup:
    --tar <tarball>
    --image <image>
    --big                         use large partitions
    --size <size>                 (default: $size)
  mode:
    --efi-grub2                   (default)
    --rpi32
    --rpi64
EOF
}

while test "$1" != ""; do
	case "$1" in
	-i | --image)
		qcow="$2"
		shift; shift
		;;
	--big)
		size="15G"
		size_uefi="128"
		size_boot="1024"
		size_swap="1024"
		shift
		;;
	-s | --size)
		size="$2"
		shift; shift
		;;
	-t | --tar | --tarball)
		tarb="$2"
		shift; shift
		;;
	--efi-grub2)
		mode="efi-grub2"
		shift
		;;
	--efi-systemd)
		mode="efi-systemd"
		shift
		;;
	--rpi32)
		mode="rpi32"
		shift
		;;
	--rpi64)
		mode="rpi64"
		shift
		;;
	--force)
		allow_override="yes"
		shift
		;;
	*)	echo "ERROR: unknown arg: $1"
		exit 1
		;;
	esac
done

######################################################################
# sanity checks

if test "$qcow" = ""; then
	echo "ERROR: no image given"
	exit 1
fi
if test -f "$qcow"; then
	if test "$allow_override" = "yes"; then
		rm -f "$qcow"
	else
		echo "ERROR: image exists: $qcow"
		exit 1
	fi
fi
if test ! -f "$tarb"; then
	echo "ERROR: tarball not found: $tarb"
	exit 1
fi

######################################################################
# uuids & other names

uuid_gpt_bios="21686148-6449-6E6F-744E-656564454649"
uuid_gpt_uefi="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
uuid_gpt_swap="0657fd6d-a4ab-43c4-84e5-0933c84b4f4f"
uuid_gpt_boot="BC13C2FF-59E6-4262-A352-B275FD6F7172"
uuid_gpt_root="FIXME"

uuid_gpt_root_ia32="44479540-f297-41b2-9af7-d131d5f0458a"
uuid_gpt_root_x64="4f68bce3-e8cd-4db1-96e7-fbcaf984b709"
uuid_gpt_root_arm="69dad710-2ce4-4e3c-b16c-21a1d49abed3"
uuid_gpt_root_a64="b921b045-1df0-41c3-af44-4c6f280d3fae"

uefi_boot_file="FIXME"
uefi_boot_file_ia32="BOOTIA32.EFI"
uefi_boot_file_x64="BOOTX64.EFI"
uefi_boot_file_arm="BOOTARM.EFI"
uefi_boot_file_a64="BOOTAA64.EFI"

######################################################################
# guestfish script helpers

function fish() {
	echo "#" "$@"
	guestfish --remote -- "$@"		|| exit 1
}

function fish_init() {
	local format

	case "$qcow" in
	*.raw)	format="raw" ;;
	*)	format="qcow2";;
	esac

	msg "creating and adding disk image"
	fish disk-create $qcow $format $size
	fish add $qcow
	fish run
}

function fish_fini() {
	msg "finishing"
	fish umount-all
	fish exit
}

function fish_partition() {
	local ptype="$1"
	local szbios="$2"
	local szuefi="$3"
	local szboot="$4"
	local szswap="$5"
	local pstart=2048
	local pend

	msg "creating partitions"
	fish part-init /dev/sda $ptype
	for size in $szbios $szuefi $szboot $szswap; do
		test "$size" = "0" && continue
		pend=$(( $pstart + $size * 2048 - 1 ))
		fish part-add /dev/sda p $pstart $pend
		pstart=$(( $pend + 1 ))
	done
	fish part-add /dev/sda p $pstart -2048
}

function fish_copy_tar() {
	msg "copying tarball to image"
	fish tar-in	$tarb	/	compress:gzip
	fish copy-in	$fstab	/etc
}

function fish_part_efi_grub2() {
	local mode="$1"
	local id_uefi id_boot id_swap id_root
	local nr_uefi nr_boot nr_swap nr_root

	if test "$mode" = "bios"; then
		fish_partition gpt 4 ${size_uefi} ${size_boot} ${size_swap}
		fish part-set-gpt-type /dev/sda 1 ${uuid_gpt_bios}
		nr_uefi=2
		nr_boot=3
		nr_swap=4
		nr_root=5
	else
		fish_partition gpt 0 ${size_uefi} ${size_boot} ${size_swap}
		nr_uefi=1
		nr_boot=2
		nr_swap=3
		nr_root=4
	fi

	fish part-set-gpt-type /dev/sda ${nr_uefi} ${uuid_gpt_uefi}
	fish part-set-bootable /dev/sda ${nr_uefi} true
	fish part-set-gpt-type /dev/sda ${nr_boot} ${uuid_gpt_boot}
	fish part-set-gpt-type /dev/sda ${nr_swap} ${uuid_gpt_swap}
	fish part-set-gpt-type /dev/sda ${nr_root} ${uuid_gpt_root}

	msg "creating filesystems"
	fish mkfs fat	/dev/sda${nr_uefi}	label:UEFI
	fish mkfs ext2	/dev/sda${nr_boot}	label:boot
	fish mkswap	/dev/sda${nr_swap}	label:swap
	fish mkfs ext4	/dev/sda${nr_root}	label:root

	id_uefi=$(guestfish --remote -- vfs-uuid /dev/sda${nr_uefi})
	id_boot=$(guestfish --remote -- vfs-uuid /dev/sda${nr_boot})
	id_swap=$(guestfish --remote -- vfs-uuid /dev/sda${nr_swap})
	id_root=$(guestfish --remote -- vfs-uuid /dev/sda${nr_root})
	rootfs="UUID=${id_root}"

	msg "mounting filesystems"
	fish mount	/dev/sda${nr_root}	/
	fish mkdir				/boot
	fish mount	/dev/sda${nr_boot}	/boot
	fish mkdir				/boot/efi
	fish mount	/dev/sda${nr_uefi}	/boot/efi

	cat <<-EOF > "$fstab"
	UUID=${id_root}	/		ext4	defaults	0 0
	UUID=${id_boot}	/boot		ext2	defaults	0 0
	UUID=${id_uefi}	/boot/efi	vfat	defaults	0 0
	UUID=${id_swap}	swap		swap	defaults	0 0
EOF
}

function fish_grub2_efi() {
	local term="${1-console}"
	local havegrubby havegrubpc haveboot
	local grubeficfg grubefi blsentry cmdline

	msg "boot setup (root=${rootfs})"
	cmdline="ro root=${rootfs} ${console} ${append}"
	kver=$(guestfish --remote -- ls /lib/modules)
#	kver=$(guestfish --remote -- ls /boot \
#		| grep -e "^vmlinuz-" | grep -v rescue \
#		| sed -e "s/vmlinuz-//")
	echo "### kernel version is $kver"

	havegrubby=$(guestfish --remote -- is-file /usr/sbin/grubby)
	if test "$havegrubby" = "true"; then
		echo "### create grub2 boot loader config (grubby mode)"
		cat <<-EOF > "$grubdef"
		GRUB_TIMEOUT="5"
		GRUB_TERMINAL_OUTPUT="${term}"
		GRUB_DISABLE_SUBMENU="true"
		GRUB_DISABLE_RECOVERY="true"
		GRUB_CMDLINE_LINUX="${cmdline}"
		GRUB_ENABLE_BLSCFG="false"
EOF
		fish copy-in $grubdef /etc/default
		fish command "sh -c 'grub2-mkconfig > /etc/grub2-efi.cfg'"
		fish command "sed -i -c -e s/linux16/linuxefi/ /etc/grub2-efi.cfg"
		fish command "sed -i -c -e s/initrd16/initrdefi/ /etc/grub2-efi.cfg"
		echo "### rebuilding initramfs"
		fish command "dracut --force /boot/initramfs-${kver}.img ${kver}"
	else
		echo "### create grub2 boot loader config (bls mode)"
		cat <<-EOF > "$grubdef"
		GRUB_TIMEOUT="5"
		GRUB_TERMINAL_OUTPUT="${term}"
		GRUB_DISABLE_SUBMENU="true"
		GRUB_DISABLE_RECOVERY="true"
		GRUB_CMDLINE_LINUX="${cmdline}"
		GRUB_ENABLE_BLSCFG="true"
EOF
		fish copy-in $grubdef /etc/default
		fish command "sh -c 'grub2-mkconfig > /etc/grub2-efi.cfg'"

		havegrubpc=$(guestfish --remote -- is-dir /usr/lib/grub/i386-pc)
		if test "$havegrubpc" = "true"; then
			echo "### setup grub2 for bios boot"
			grubeficfg=$(guestfish --remote -- glob-expand /boot/efi/EFI/*/grub.cfg)
			grubeficfg="${grubeficfg#/boot/efi}"
			cat <<-EOF > "$grubcfg"
			configfile (hd0,gpt2)$grubeficfg
EOF
			fish command "grub2-install --target=i386-pc /dev/sda"
			fish copy-in $grubcfg /boot/grub2
		fi

		echo "### reinstall kernel"
		fish command "kernel-install remove ${kver} /lib/modules/${kver}/vmlinuz"
		fish command "kernel-install add ${kver} /lib/modules/${kver}/vmlinuz"

		echo "### fixup bls entry"
		blsentry=$(guestfish --remote -- glob-expand "/boot/loader/entries/*${kver}*")
		fish command "sed -i -e 's|^options.*|options ${cmdline}|' ${blsentry}"
	fi

	haveboot=$(guestfish --remote -- is-file /boot/efi/EFI/BOOT/${uefi_boot_file})
	if test "$haveboot" = "true"; then
		echo "### have ${uefi_boot_file}, good"
	else
		grubefi=$(guestfish --remote -- glob-expand "/boot/efi/EFI/*/grub*.efi")
		echo "### install ${grubefi} as ${uefi_boot_file}"
		fish cp	${grubefi} /boot/efi/EFI/BOOT/${uefi_boot_file}
	fi
}

function fish_part_efi_systemd() {
	local mode="$1"
	local id_uefi id_swap id_root
	local nr_uefi nr_swap nr_root

	if test "$mode" = "bios"; then
		fish_partition gpt 4 $(( ${size_uefi} + ${size_boot} )) 0 ${size_swap}
		fish part-set-gpt-type /dev/sda 1 ${uuid_gpt_bios}
		nr_uefi=2
		nr_swap=3
		nr_root=4
	else
		fish_partition gpt 0 $(( ${size_uefi} + ${size_boot} )) 0 ${size_swap}
		nr_uefi=1
		nr_swap=2
		nr_root=3
	fi

	fish part-set-gpt-type /dev/sda ${nr_uefi} ${uuid_gpt_uefi}
	fish part-set-bootable /dev/sda ${nr_uefi} true
	fish part-set-gpt-type /dev/sda ${nr_swap} ${uuid_gpt_swap}
	fish part-set-gpt-type /dev/sda ${nr_root} ${uuid_gpt_root}

	msg "creating filesystems"
	fish mkfs fat	/dev/sda${nr_uefi}	label:UEFI
	fish mkswap	/dev/sda${nr_swap}	label:swap
	fish mkfs ext4	/dev/sda${nr_root}	label:root

	id_uefi=$(guestfish --remote -- vfs-uuid /dev/sda${nr_uefi})
	id_swap=$(guestfish --remote -- vfs-uuid /dev/sda${nr_swap})
	id_root=$(guestfish --remote -- vfs-uuid /dev/sda${nr_root})
	rootfs="UUID=${id_root}"

	msg "mounting filesystems"
	fish mount	/dev/sda${nr_root}	/
	fish mkdir				/boot
	fish mount	/dev/sda${nr_uefi}	/boot

	cat <<-EOF > "$fstab"
	UUID=${id_root}	/		ext4	defaults	0 0
	UUID=${id_uefi}	/boot		vfat	defaults	0 0
	UUID=${id_swap}	swap		swap	defaults	0 0
EOF
}

function fish_systemd_boot() {
	local havegrubpc

	msg "boot setup (root=${rootfs})"
	kver=$(guestfish --remote -- ls /lib/modules)
	echo "### kernel version is $kver"

	havegrubpc=$(guestfish --remote -- is-dir /usr/lib/grub/i386-pc)
	if test "$havegrubpc" = "true"; then
		#
		# install grub2 for bios, teach it to use the boot
		# loader spec entries created by systemd-boot.  This
		# gives us an image which boots with both bios and
		# efi.
		#
		# Then uninstall the rpms so the grub2 scripts don't
		# get into the way when updating the systemd-boot
		# config on kernel updates.  Also cleanup files
		# already created by grub2 scripts.
		#
		echo "### grub2 bios boot hack"
		fish command "grub2-install --target=i386-pc /dev/sda"
		grubrpms=$(guestfish --remote -- command "rpm -qa 'grub2*' os-prober")
		grubrpms=$(echo $grubrpms)
		fish command "rpm -e -v $grubrpms"
		cat <<-EOF > "$grubcfg"
		function load_video {
			insmod all_video
		}

		insmod part_gpt
		insmod fat
		insmod serial
		insmod terminal
		insmod blscfg

		serial --unit=0 --speed=115200
		terminal_output console serial
		terminal_input console serial

		set boot='hd0,gpt2'
		set timeout=3
		blscfg
EOF
		fish copy-in $grubcfg /boot/grub2
		fish glob rm "/boot/*$kver"
	fi

	echo "### init systemd-boot"
	fish mkdir-p /etc/kernel
	fish write /etc/kernel/cmdline "ro root=${rootfs} ${console} ${append}"
	fish command "bootctl --no-variables install"
	fish command "sed -i -e '/timeout/s/^#//' /boot/loader/loader.conf"
	echo "### reinstall kernel"
	fish command "kernel-install remove ${kver} /lib/modules/${kver}/vmlinuz"
	fish command "kernel-install add ${kver} /lib/modules/${kver}/vmlinuz"
}

function fish_part_rpi() {
	local bootpart="${1-2}"

	local id_firm id_boot id_swap id_root
	fish_partition mbr 0 64 384 512

	fish part-set-bootable /dev/sda $bootpart true
	fish part-set-mbr-id /dev/sda 1 0x0c
	fish part-set-mbr-id /dev/sda 2 0x83
	fish part-set-mbr-id /dev/sda 3 0x82
	fish part-set-mbr-id /dev/sda 4 0x83

	msg "creating filesystems"
	fish mkfs fat	/dev/sda1	label:firm
	fish mkfs ext2	/dev/sda2	label:boot
	fish mkswap	/dev/sda3	label:swap
	fish mkfs ext4	/dev/sda4	label:root

	id_firm=$(guestfish --remote -- vfs-uuid /dev/sda1)
	id_boot=$(guestfish --remote -- vfs-uuid /dev/sda2)
	id_swap=$(guestfish --remote -- vfs-uuid /dev/sda3)
	id_root=$(guestfish --remote -- vfs-uuid /dev/sda4)
	#rootfs="LABEL=root"
	rootfs="UUID=${id_root}"

	msg "mounting filesystems"
	fish mount	/dev/sda4	/
	fish mkdir			/boot
	fish mount	/dev/sda2	/boot
	fish mkdir			/boot/efi
	fish mount	/dev/sda1	/boot/efi

	cat <<-EOF > "$fstab"
	UUID=${id_root}	/		ext4	defaults	0 0
	UUID=${id_boot}	/boot		ext2	defaults	0 0
	UUID=${id_firm}	/boot/efi	vfat	defaults	0 0
	#UUID=${id_swap}	swap		swap	defaults	0 0
EOF
}

function fish_firmware_rpi32() {
	msg "rpi 32bit firmware setup"
	fish glob cp-a "/usr/share/bcm283x-firmware/*"	/boot/efi
	fish cp	/usr/share/uboot/rpi_2/u-boot.bin	/boot/efi/rpi2-u-boot.bin
	fish cp	/usr/share/uboot/rpi_3_32b/u-boot.bin	/boot/efi/rpi3-u-boot.bin
}

function fish_firmware_rpi64() {
	msg "rpi 64bit firmware setup"
	fish glob cp-a "/usr/share/bcm283x-firmware/*"	/boot/efi
	fish cp	/usr/share/uboot/rpi_3/u-boot.bin	/boot/efi/rpi3-u-boot.bin
	fish rename /boot/efi/config.txt		/boot/efi/config-32.txt
	fish rename /boot/efi/config-64.txt		/boot/efi/config.txt

	# copy kernel dtb to efi partition
	fish mkdir					/boot/efi/dtb
	fish glob cp-a "/boot/dtb-*/broadcom"		/boot/efi/dtb

	# copy grub to boot (workaround u-boot bug)
	fish mkdir					/boot/efi/efi/boot
	fish cp /boot/efi/efi/fedora/grubaa64.efi	/boot/efi/efi/boot
}

function fish_extlinux_rpi32() {
	local cmdline="ro root=${rootfs} ${console} ${append}"
	local kver

	msg "boot setup (root=${rootfs})"
	kver=$(guestfish --remote -- ls /boot \
		| grep -e "^vmlinuz-" | grep -v rescue \
		| sed -e "s/vmlinuz-//")
	echo "### kernel version is $kver"

	echo "### creating extlinux.conf"
	cat <<-EOF >> "$WORK/extlinux.conf"
	menu title Fedora boot menu
	timeout 30
	label Fedora (${kver})
	  kernel /vmlinuz-${kver}
	  append ${cmdline}
	  fdtdir /dtb-${kver}/
	  initrd /initramfs-${kver}.img
EOF
	fish copy-in "$WORK/extlinux.conf" /boot/extlinux

	echo "### rebuilding initramfs"
	fish command "dracut --force /boot/initramfs-${kver}.img ${kver}"
}

function fish_extlinux_rpi64() {
	local cmdline="ro root=${rootfs} ${console} ${append}"
	local kernel kver

	msg "boot setup (root=${rootfs})"
	kernel=$(guestfish --remote -- ls /boot \
		| grep -e "^vmlinu[xz]-" | grep -v rescue)
	echo "### kernel image is $kernel"
	kver=$(echo $kernel | sed -e "s/vmlinu[xz]-//")
	echo "### kernel version is $kver"

	echo "### creating extlinux.conf"
	cat <<-EOF >> "$WORK/extlinux.conf"
	menu title Fedora boot menu
	timeout 30
	label Fedora (${kver})
	  kernel /vmlinux-${kver}
	  append ${cmdline}
	  fdtdir /dtb-${kver}/
	  initrd /initramfs-${kver}.img
EOF
	fish copy-in "$WORK/extlinux.conf" /boot/extlinux

	echo "### rebuilding initramfs"
	fish command "dracut --force /boot/initramfs-${kver}.img ${kver}"
}

######################################################################
# go!

export LIBGUESTFS_BACKEND=direct
eval $(guestfish --listen)
if test "$GUESTFISH_PID" = ""; then
	echo "ERROR: starting guestfish failed"
	exit 1
fi

case "$(uname -m)" in
armv7*)
	console="console=tty1 console=ttyAMA0,115200 earlycon"
	uuid_gpt_root="$uuid_gpt_root_arm"
	uefi_boot_file="$uefi_boot_file_arm"
	uefi_part_mode="pure"
	;;
aarch64)
	console="console=tty1 console=ttyAMA0,115200 earlycon"
	uuid_gpt_root="$uuid_gpt_root_a64"
	uefi_boot_file="$uefi_boot_file_a64"
	uefi_part_mode="pure"
	;;
i?86)
	console="console=tty1 console=ttyS0,115200"
	uuid_gpt_root="$uuid_gpt_root_ia32"
	uefi_boot_file="$uefi_boot_file_ia32"
	uefi_part_mode="bios"
	;;
x86_64)
	console="console=tty1 console=ttyS0,115200"
	uuid_gpt_root="$uuid_gpt_root_x64"
	uefi_boot_file="$uefi_boot_file_x64"
	uefi_part_mode="bios"
	;;
esac

case "$mode" in
efi-grub2)
	fish_init
	fish_part_efi_grub2 ${uefi_part_mode}
	fish_copy_tar
	fish_grub2_efi
	fish_fini
	;;
efi-systemd)
	fish_init
	fish_part_efi_systemd ${uefi_part_mode}
	fish_copy_tar
	fish_systemd_boot
	fish_fini
	;;
rpi32)
	fish_init
	fish_part_rpi	2
	fish_copy_tar
	fish_firmware_rpi32
	fish_extlinux_rpi32
	fish_fini
	;;
rpi64)
	fish_init
	fish_part_rpi	1
	fish_copy_tar
	fish_firmware_rpi64
#	fish_extlinux_rpi64
	fish_grub2_efi	gfxterm
	fish_fini
	;;
*)
	# should not happen
	echo "Oops"
	exit 1
	;;
esac

msg "all done."
