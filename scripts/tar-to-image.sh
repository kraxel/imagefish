#!/bin/sh

######################################################################
# defaults

qcow=""
size="2G"
tarb=""
mode="efi"

######################################################################
# create work dir

WORK="${TMPDIR-/var/tmp}/${0##*/}-$$"
mkdir "$WORK" || exit 1
trap 'rm -rf "$WORK"' EXIT

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
# fish script helpers

function fish_init() {
	local format

	case "$qcow" in
	*.raw)	format="raw" ;;
	*)	format="qcow2";;
	esac

	cat <<-EOF >> "$script"

	# init image, start guestfish with it
	disk-create $qcow $format $size
	add $qcow
	run
EOF
}

function fish_partition() {
	local ptype="$1"
	local szfirm="$2"
	local szboot="$3"
	local szswap="$4"
	local pstart=2048
	local pend

	echo ""							>> "$script"
	echo "!echo \"### creating partitions\""		>> "$script"
	echo "part-init /dev/sda $ptype"			>> "$script"
	for size in $szfirm $szboot $szswap; do
		test "$size" = "0" && continue
		pend=$(( $pstart + $size * 2048 - 1 ))
		echo "part-add /dev/sda p $pstart $pend"	>> "$script"
		pstart=$(( $pend + 1 ))
	done
	echo "part-add /dev/sda p $pstart -2048"		>> "$script"
}

function fish_copy_tar() {
	cat <<-EOF >> "$script"

	!echo "### copying tarball to image"
	tar-in	$tarb	/	compress:gzip
	copy-in	$fstab	/etc
	write /.autorelabel ""
EOF
}

function fish_part_efi() {
	local uuid_efi="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"

	fish_partition gpt 200 300 500

	cat <<-EOF >> "$script"

	part-set-gpt-type /dev/sda 1 ${uuid_efi}
	part-set-bootable /dev/sda 1 true

	!echo "### creating filesystems"
	mkfs fat	/dev/sda1	label:UEFI
	mkfs ext2	/dev/sda2	label:boot
	mkswap		/dev/sda3	label:swap
	mkfs ext4	/dev/sda4	label:root

	!echo "### mounting filesystems"
	mount	/dev/sda4	/
	mkdir			/boot
	mount	/dev/sda2	/boot
	mkdir			/boot/efi
	mount	/dev/sda1	/boot/efi
EOF

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
	GRUB_DISABLE_SUBMENU="true"
	GRUB_DISABLE_RECOVERY="true"
	#GRUB_CMDLINE_LINUX="root=LABEL=root"
EOF

	cat <<-EOF >> "$script"

	!echo "### create grub2 boot loader config"
	copy-in	$grubdef /etc/default
	command "grub2-mkconfig -o /etc/grub2-efi.cfg"
	command "sed -i -c -e s/linux16/linuxefi/ /etc/grub2-efi.cfg"
	command "sed -i -c -e s/initrd16/initrdefi/ /etc/grub2-efi.cfg"
EOF
}

function fish_part_rpi() {
	fish_partition mbr 200 300 500

	cat <<-EOF >> "$script"

	!echo "### creating filesystems"
	mkfs fat	/dev/sda1	label:FIRMWARE
	mkfs ext2	/dev/sda2	label:boot
	mkswap		/dev/sda3	label:swap
	mkfs ext4	/dev/sda4	label:root

	!echo "### mounting filesystems"
	mount	/dev/sda4	/
	mkdir			/boot
	mount	/dev/sda2	/boot
	mkdir			/boot/fw
	mount	/dev/sda1	/boot/fw
EOF

	cat <<-EOF > "$fstab"
	LABEL=root	/		ext4	defaults	0 0
	LABEL=boot	/boot		ext2	defaults	0 0
	LABEL=FIRMWARE	/boot/fw	vfat	ro		0 0
	LABEL=swap	swap		swap	defaults	0 0
EOF
}

function fish_firmware_rpi32() {
	cat <<-EOF >> "$script"

	!echo "### rpi2 firmware setup"
	glob cp-a /usr/share/bcm283x-firmware/*		/boot/fw
	cp	/usr/share/uboot/rpi_2/u-boot.bin	/boot/fw/rpi2-u-boot.bin
	cp	/usr/share/uboot/rpi_3_32b/u-boot.bin	/boot/fw/rpi3-u-boot.bin
	ls -l	/boot/fw
EOF
}

######################################################################
# go!

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
	;;
rpi64)
	fish_init
	fish_part_rpi
	fish_copy_tar
	;;
*)
	# should not happen
	echo "Oops"
	exit 1
	;;
esac
echo "!echo \"### all done\"" >> "$script"

export LIBGUESTFS_BACKEND=direct
if guestfish --progress-bars -f "$script"; then
	true # nothing
else
	echo "guestfish error, here is the script"
	echo "==="
	cat $script
	echo "==="
fi
