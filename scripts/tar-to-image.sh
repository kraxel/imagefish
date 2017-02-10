#!/bin/sh

######################################################################
# defaults

qcow=""
size="4G"
tarb=""
mode="efi"

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
    --efi                         (default)
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
	--efi)
		mode="efi"
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
	fish write /.autorelabel ""
}

function fish_part_efi() {
	local uuid_efi="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"

	fish_partition gpt 64 384 512

	fish part-set-gpt-type /dev/sda 1 ${uuid_efi}
	fish part-set-bootable /dev/sda 1 true

	msg "creating filesystems"
	fish mkfs fat	/dev/sda1	label:UEFI
	fish mkfs ext2	/dev/sda2	label:boot
	fish mkswap	/dev/sda3	label:swap
	fish mkfs ext4	/dev/sda4	label:root

	msg "mounting filesystems"
	fish mount	/dev/sda4	/
	fish mkdir			/boot
	fish mount	/dev/sda2	/boot
	fish mkdir			/boot/efi
	fish mount	/dev/sda1	/boot/efi

	cat <<-EOF > "$fstab"
	LABEL=root	/		ext4	defaults	0 0
	LABEL=boot	/boot		ext2	defaults	0 0
	LABEL=UEFI	/boot/efi	vfat	defaults	0 0
	LABEL=swap	swap		swap	defaults	0 0
EOF
}

function fish_grub2_efi() {
	cat <<-EOF > "$grubdef"
	GRUB_TIMEOUT="5"
	GRUB_TERMINAL_OUTPUT="console"
	GRUB_DISABLE_SUBMENU="true"
	GRUB_DISABLE_RECOVERY="true"
	GRUB_CMDLINE_LINUX="ro root=LABEL=root"
EOF

	msg "create grub2 boot loader config"
	fish copy-in	$grubdef /etc/default
	fish command "grub2-mkconfig -o /etc/grub2-efi.cfg"
	fish command "sed -i -c -e s/linux16/linuxefi/ /etc/grub2-efi.cfg"
	fish command "sed -i -c -e s/initrd16/initrdefi/ /etc/grub2-efi.cfg"
}

function fish_part_rpi() {
	fish_partition mbr 64 384 512

	fish part-set-bootable /dev/sda 2 true
	fish part-set-mbr-id /dev/sda 1 0x0c
	fish part-set-mbr-id /dev/sda 2 0x83
	fish part-set-mbr-id /dev/sda 3 0x82
	fish part-set-mbr-id /dev/sda 4 0x83

	msg "creating filesystems"
	fish mkfs fat	/dev/sda1	label:firmware
	fish mkfs ext2	/dev/sda2	label:boot
	fish mkswap	/dev/sda3	label:swap
	fish mkfs ext4	/dev/sda4	label:root

	msg "mounting filesystems"
	fish mount	/dev/sda4	/
	fish mkdir			/boot
	fish mount	/dev/sda2	/boot
	fish mkdir			/boot/fw
	fish mount	/dev/sda1	/boot/fw

	cat <<-EOF > "$fstab"
	LABEL=root	/		ext4	defaults	0 0
	LABEL=boot	/boot		ext2	defaults	0 0
	LABEL=firmware	/boot/fw	vfat	ro		0 0
	LABEL=swap	swap		swap	defaults	0 0
EOF
}

function fish_firmware_rpi32() {
	msg "rpi 32bit firmware setup"
	fish glob cp-a "/usr/share/bcm283x-firmware/*"	/boot/fw
	fish cp	/usr/share/uboot/rpi_2/u-boot.bin	/boot/fw/rpi2-u-boot.bin
	fish cp	/usr/share/uboot/rpi_3_32b/u-boot.bin	/boot/fw/rpi3-u-boot.bin
}

function fish_firmware_rpi64() {
	msg "rpi 64bit firmware setup"
	fish glob cp-a "/usr/share/bcm283x-firmware/*"	/boot/fw
	fish cp	/usr/share/uboot/rpi_3/u-boot.bin	/boot/fw/rpi3-u-boot.bin

	# HACK: config.txt from bcm283x-firmware.rpm works for 32bit only
	cat <<EOF > "$WORK/config.txt"
	init_uart_clock=48000000
	gpu_mem=16
	boot_delay=1
EOF
	fish copy-in	"$WORK/config.txt"		/boot/fw
}

function fish_extlinux_rpi32() {
	local cmdline="ro root=LABEL=root console=ttyAMA0,115200 console=tty1"
	local kver

	msg "boot setup"
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
	local cmdline="ro root=LABEL=root console=ttyAMA0,115200 console=tty1"
	local kernel kver

	msg "boot setup"
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
	  fdtdir /dtb-${kver}/broadcom/
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

case "$mode" in
efi)
	fish_init
	fish_part_efi
	fish_copy_tar
	fish_grub2_efi
	;;
rpi32)
	fish_init
	fish_part_rpi
	fish_copy_tar
	fish_firmware_rpi32
	fish_extlinux_rpi32
	;;
rpi64)
	fish_init
	fish_part_rpi
	fish_copy_tar
	fish_firmware_rpi64
	fish_extlinux_rpi64
	;;
*)
	# should not happen
	echo "Oops"
	exit 1
	;;
esac

msg "all done."
