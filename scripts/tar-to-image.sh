#!/bin/sh

######################################################################
# defaults

qcow=""
size="4G"
tarb=""
mode="efi-grub2"

######################################################################
# create work dir

function msg() {
	local txt="$1"
	local bold="\x1b[1m"
	local normal="\x1b[0m"
	echo -e "${bold}### ${txt}${normal}"
}

function do_cleanup() {
	msg "cleaning up ..."
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

# variables
rootfs=""
console=""

######################################################################
# parse args

function print_help() {
cat <<EOF
usage: $0 [ options ]
options:
  setup:
    --tar <tarball>
    --image <image>
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
# uuids

uuid_gpt_efi="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
uuid_gpt_swap="0657fd6d-a4ab-43c4-84e5-0933c84b4f4f"
uuid_gpt_root="FIXME"

uuid_gpt_root_ia32="44479540-f297-41b2-9af7-d131d5f0458a"
uuid_gpt_root_x64="4f68bce3-e8cd-4db1-96e7-fbcaf984b709"
uuid_gpt_root_arm="69dad710-2ce4-4e3c-b16c-21a1d49abed3"
uuid_gpt_root_a64="b921b045-1df0-41c3-af44-4c6f280d3fae"

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
	fish umount-all
}

function fish_partition() {
	local ptype="$1"
	local szfirm="$2"
	local szboot="$3"
	local szswap="$4"
	local pstart=2048
	local pend

	msg "creating partitions"
	fish part-init /dev/sda $ptype
	for size in $szfirm $szboot $szswap; do
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
	local id_uefi id_boot id_swap id_root

	fish_partition gpt 64 384 512

	fish part-set-gpt-type /dev/sda 1 ${uuid_gpt_efi}
	fish part-set-bootable /dev/sda 1 true
	fish part-set-gpt-type /dev/sda 3 ${uuid_gpt_swap}
	fish part-set-gpt-type /dev/sda 4 ${uuid_gpt_root}

	msg "creating filesystems"
	fish mkfs fat	/dev/sda1	label:UEFI
	fish mkfs ext2	/dev/sda2	label:boot
	fish mkswap	/dev/sda3	label:swap
	fish mkfs ext4	/dev/sda4	label:root

	id_uefi=$(guestfish --remote -- vfs-uuid /dev/sda1)
	id_boot=$(guestfish --remote -- vfs-uuid /dev/sda2)
	id_swap=$(guestfish --remote -- vfs-uuid /dev/sda3)
	id_root=$(guestfish --remote -- vfs-uuid /dev/sda4)
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
	UUID=${id_uefi}	/boot/efi	vfat	defaults	0 0
	UUID=${id_swap}	swap		swap	defaults	0 0
EOF
}

function fish_grub2_efi() {
	local term="${1-console}"

	msg "boot setup (root=${rootfs})"
	kver=$(guestfish --remote -- ls /boot \
		| grep -e "^vmlinuz-" | grep -v rescue \
		| sed -e "s/vmlinuz-//")
	echo "### kernel version is $kver"

	echo "### rebuilding initramfs"
	fish command "dracut --force /boot/initramfs-${kver}.img ${kver}"

	echo "### create grub2 boot loader config"
	cat <<-EOF > "$grubdef"
	GRUB_TIMEOUT="5"
	GRUB_TERMINAL_OUTPUT="${term}"
	GRUB_DISABLE_SUBMENU="true"
	GRUB_DISABLE_RECOVERY="true"
	GRUB_CMDLINE_LINUX="ro root=${rootfs} ${console}"
EOF
	fish copy-in $grubdef /etc/default
	fish command "sh -c 'grub2-mkconfig > /etc/grub2-efi.cfg'"
	fish command "sed -i -c -e s/linux16/linuxefi/ /etc/grub2-efi.cfg"
	fish command "sed -i -c -e s/initrd16/initrdefi/ /etc/grub2-efi.cfg"
}

function fish_part_efi_systemd() {
	local id_uefi id_swap id_root

	fish_partition gpt 512 0 512

	fish part-set-gpt-type /dev/sda 1 ${uuid_gpt_efi}
	fish part-set-bootable /dev/sda 1 true
	fish part-set-gpt-type /dev/sda 2 ${uuid_gpt_swap}
	fish part-set-gpt-type /dev/sda 3 ${uuid_gpt_root}

	msg "creating filesystems"
	fish mkfs fat	/dev/sda1	label:UEFI
	fish mkswap	/dev/sda2	label:swap
	fish mkfs ext4	/dev/sda3	label:root

	id_uefi=$(guestfish --remote -- vfs-uuid /dev/sda1)
	id_swap=$(guestfish --remote -- vfs-uuid /dev/sda2)
	id_root=$(guestfish --remote -- vfs-uuid /dev/sda3)
	rootfs="UUID=${id_root}"

	msg "mounting filesystems"
	fish mount	/dev/sda3	/
	fish mkdir			/boot
	fish mount	/dev/sda1	/boot

	cat <<-EOF > "$fstab"
	UUID=${id_root}	/		ext4	defaults	0 0
	UUID=${id_uefi}	/boot		vfat	defaults	0 0
	UUID=${id_swap}	swap		swap	defaults	0 0
EOF
}

function fish_systemd_boot() {
	msg "boot setup (root=${rootfs})"
	kver=$(guestfish --remote -- ls /lib/modules)
	echo "### kernel version is $kver"

	echo "### init systemd-boot"
	fish mkdir-p /etc/kernel
	fish write /etc/kernel/cmdline "ro root=${rootfs} ${console}"
	fish glob rm-f "/boot/*/*/initrd"
	fish command "bootctl --no-variables install"
	fish command "kernel-install add ${kver} /lib/modules/${kver}/vmlinuz"
	fish command "sed -i -e '/timeout/s/^#//' /boot/loader/loader.conf"
}

function fish_part_rpi() {
	local bootpart="${1-2}"

	local id_firm id_boot id_swap id_root
	fish_partition mbr 64 384 512

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
	rootfs="LABEL=root"
	#rootfs="UUID=${id_root}"

	msg "mounting filesystems"
	fish mount	/dev/sda4	/
	fish mkdir			/boot
	fish mount	/dev/sda2	/boot
	fish mkdir			/boot/efi
	fish mount	/dev/sda1	/boot/efi

	cat <<-EOF > "$fstab"
	#LABEL=root	/		ext4	defaults	0 0
	#LABEL=boot	/boot		ext2	defaults	0 0
	#LABEL=firm	/boot/efi	vfat	ro		0 0
	#LABEL=swap	swap		swap	defaults	0 0

	UUID=${id_root}	/		ext4	defaults	0 0
	UUID=${id_boot}	/boot		ext2	defaults	0 0
	UUID=${id_firm}	/boot/efi	vfat	ro		0 0
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
	local cmdline="ro root=${rootfs} ${console}"
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

	# HACK: kraxel's kernel-main.rpm scripts look at this
	echo "### add /boot/cmdline.txt"
	fish write /boot/cmdline.txt "$cmdline"
}

function fish_extlinux_rpi64() {
	local cmdline="ro root=${rootfs} ${console}"
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

	# HACK: kraxel's kernel-main.rpm scripts look at this
	echo "### add /boot/cmdline.txt"
	fish write /boot/cmdline.txt "$cmdline"

	# HACK: 64bit u-boot can't deal with compressed (gzip) kernels.
	# WARN: kernel updates do NOT "just work" b/c of this.
	case "$kernel" in
	vmlinuz-*)
		echo "### HACK ALERT: gunzip 64bit kernel"
		fish cp /boot/vmlinuz-${kver} /boot/vmlinux-${kver}.gz
		fish command "gunzip /boot/vmlinux-${kver}.gz"
	esac
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
	console="console=ttyAMA0,115200 console=tty1"
	uuid_gpt_root="$uuid_gpt_root_arm"
	;;
aarch64)
	console="console=ttyAMA0,115200 console=tty1"
	uuid_gpt_root="$uuid_gpt_root_a64"
	;;
i?86)
	console="console=ttyS0,115200 console=tty1"
	uuid_gpt_root="$uuid_gpt_root_ia32"
	;;
x86_64)
	console="console=ttyS0,115200 console=tty1"
	uuid_gpt_root="$uuid_gpt_root_x64"
	;;
esac

case "$mode" in
efi-grub2)
	fish_init
	fish_part_efi_grub2
	fish_copy_tar
	fish_grub2_efi
	fish_fini
	;;
efi-systemd)
	fish_init
	fish_part_efi_systemd
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
