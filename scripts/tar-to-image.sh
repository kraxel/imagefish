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

######################################################################
# parse args

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
# go!

p0=1
p1=$(( $p0 + 200 ))
p2=$(( $p1 + 300 ))
p3=$(( $p2 + 500 ))

cat <<EOF > "$WORK/mkimage.fish"
disk-create $qcow qcow2 $size
add $qcow
run

# create partitions
part-init /dev/sda gpt
part-add /dev/sda primary $(( 2048 * $p0)) $(( 2048 * $p1 - 1 )) 
part-add /dev/sda primary $(( 2048 * $p1)) $(( 2048 * $p2 - 1 )) 
part-add /dev/sda primary $(( 2048 * $p2)) $(( 2048 * $p3 - 1 )) 
part-add /dev/sda primary $(( 2048 * $p3)) -2048

# tag EFI System partition
part-set-gpt-type /dev/sda 1 C12A7328-F81F-11D2-BA4B-00A0C93EC93B

# create filesystems
mkfs fat	/dev/sda1	label:uefi
mkfs ext2	/dev/sda2	label:boot
mkswap		/dev/sda3	label:swap
mkfs ext4	/dev/sda4	label:root

# make dirs & mount
mount	/dev/sda4	/
mkdir			/boot
mount	/dev/sda2	/boot
mkdir			/boot/efi
mount	/dev/sda1	/boot/efi

# populate image
tar-in	$tarb	/	compress:gzip
EOF

export LIBGUESTFS_BACKEND=direct
set -ex
guestfish -x --progress-bars -f "$WORK/mkimage.fish"
