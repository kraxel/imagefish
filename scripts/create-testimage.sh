#!/bin/sh

# args
qcow="${1-testimage.qcow2}"
name="${2-testimage}"
size="${3-1G}"

function msg() {
	local txt="$1"
	local bold="\x1b[1m"
	local normal="\x1b[0m"
	echo -e "${bold}### ${txt}${normal}"
}

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

function fish_format() {
	local label="$1"

	msg "creating partition"
	fish part-init /dev/sda mbr
	fish part-add /dev/sda p 2048 -2048
	fish part-set-mbr-id /dev/sda 1 0x0c

	msg "creating filesystem"
	fish mkfs fat	/dev/sda1	"label:$label"
}

function fish_fini() {
	fish umount-all
}

######################################################################
# go!

#export LIBGUESTFS_BACKEND=direct
eval $(guestfish --listen)
if test "$GUESTFISH_PID" = ""; then
	echo "ERROR: starting guestfish failed"
	exit 1
fi

rm -f "$qcow"
fish_init
fish_format "$name"
fish_fini
msg "all done."
