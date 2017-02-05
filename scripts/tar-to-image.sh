#!/bin/sh

######################################################################
# defaults

qcow=""
size="2G"
tarb=""

######################################################################
# create work dir

WORK="${TMPDIR-/var/tmp}/${0##*/}-$$"
mkdir "$WORK" || exit 1
trap 'rm -rf "$WORK"' EXIT

# work files
script="$WORK/imagefish.script"
fstab="$WORK/fstab"

######################################################################
# parse args

function print_help() {
cat <<EOF
usage: $0 [ options ]
options:
  --tar <tarball>
  --image <image>
  --size <size>                 (default: $size)
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
	echo "ERROR: image exists: $qcow"
	exit 1
fi
if test ! -f "$tarb"; then
	echo "ERROR: tarball not found: $tarb"
	exit 1
fi

######################################################################
# fish script helpers

function fish_init() {
	cat <<-EOF >> "$script"

	# init image, start guestfish with it
	disk-create $qcow qcow2 $size
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
	echo "# create partitions"				>> "$script"
	echo "part-init /dev/sda $ptype"			>> "$script"
	for size in $szfirm $szboot $szswap; do
		test "$size" = "0" && continue
		pend=$(( $pstart + $size * 2048 - 1 ))
		echo "part-add /dev/sda p $pstart $pend"	>> "$script"
		pstart=$(( $pend + 1 ))
	done
	echo "part-add /dev/sda p $pstart -2048"		>> "$script"
}

function fish_part_efi() {
	local uuid_efi="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"

	fish_partition gpt 200 300 500

	cat <<-EOF >> "$script"

	# efi partition init
	part-set-gpt-type /dev/sda 1 ${uuid_efi}
	part-set-bootable /dev/sda 1 true

	# create filesystems
	mkfs fat	/dev/sda1	label:uefi
	mkfs ext2	/dev/sda2	label:boot
	mkswap		/dev/sda3	label:swap
	mkfs ext4	/dev/sda4	label:root

	# mount filesystems
	mount	/dev/sda4	/
	mkdir			/boot
	mount	/dev/sda2	/boot
	mkdir			/boot/efi
	mount	/dev/sda1	/boot/efi
EOF

	cat <<-EOF > "$fstab"
	LABEL=root	/		ext4	defaults	0 0
	LABEL=boot	/boot		ext2	defaults	0 0
	LABEL=uefi	/boot/efi	vfat	defaults	0 0
	LABEL=swap	swap		swap	defaults	0 0
EOF
}

function fish_copy_tar() {
	cat <<-EOF >> "$script"

	# populate image
	tar-in	$tarb	/	compress:gzip
	copy-in	$fstab	/etc
EOF
}

function fish_grub2() {
	local cfg="$1"

	cat <<-EOF >> "$script"

	# grub2 boot loader config
	command grub2-mkconfig -o /etc/grub2-efi.cfg
EOF
}

######################################################################
# go!

fish_init
fish_part_efi
fish_copy_tar
fish_grub2 /etc/grub2-efi.cfg

echo "==="
cat $script
echo "==="

export LIBGUESTFS_BACKEND=direct
guestfish -x --progress-bars -f "$script"
