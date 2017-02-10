#!/bin/sh

######################################################################
# defaults

dest=""
tarb=""
tool="dnf"
grps="core"
rpms=""
krnl="kernel"
conf=""
quiet="--quiet"

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
#	sudo umount -v "$dest/dev"
	sudo rm -rf "$WORK"
}

WORK="${TMPDIR-/var/tmp}/${0##*/}-$$"
mkdir "$WORK" || exit 1
trap 'do_cleanup' EXIT

BASE="$(dirname $0)"

######################################################################
# parse args

function print_help() {
cat <<EOF
usage: $0 [ options ]
options:
  what to create (one must be specified)
    --tar <tarball>
    --dest <dir>
  what to install
    --groups <groups>               (default: $grps)
    --packages <rpms>               (default: $rpms)
    --kernel <kernel>               (default: $krnl)
  package manager setup
    --config <repos>
    --dnf                           (default)
    --yum
EOF
}

while test "$1" != ""; do
	case "$1" in
	-d | --dest)
		dest="$2"
		shift; shift
		;;
	-t | --tar | --tarball)
		tarb="$2"
		dest="$WORK/install"
		shift; shift
		;;
	-g | --groups)
		grps="$2"
		shift; shift
		;;
	-p | --packages)
		rpms="$2"
		shift; shift
		;;
	-k | --kernel)
		krnl="$2"
		shift; shift
		;;
	-c | --config)
		conf="$2"
		shift; shift
		;;
	--dnf)
		tool="dnf"
		shift
		;;
	--yum)
		tool="yum"
		shift
		;;
	--force)
		allow_override="yes"
		shift
		;;
	--verbose)
		quiet=""
		shift
		;;
	-h | --help)
		print_help
		exit 1
		;;
	*)	echo "ERROR: unknown arg: $1 (try --help)"
		exit 1
		;;
	esac
done

######################################################################
# sanity checks

if test "$dest" = ""; then
	echo "ERROR: no dest given"
	exit 1
fi
if test -d "$dest"; then
	echo "ERROR: directory exists: $dest"
	exit 1
fi
if test "$conf" != "" -a ! -f "$conf"; then
	echo "ERROR: not found: $conf"
	exit 1
fi
if test "$tarb" != "" -a -f "$tarb"; then
	if test "$allow_override" = "yes"; then
		rm -f "$tarb"
	else
		echo "ERROR: tarball exists: $tarb"
		exit 1
	fi
fi

######################################################################
# go!

case "$tool" in
dnf)
	tool="$tool -y --installroot ${dest}"
	if test "$conf" != ""; then
		tool="$tool --config ${conf}"
		tool="$tool --disablerepo=*"
		tool="$tool --enablerepo=mkimage-*"
	fi
	;;
yum)
	tool="$tool -y --installroot ${dest}"
	if test "$conf" != ""; then
		tool="$tool --config ${conf}"
	fi
	# with this yum uses the (empty) installroot repos dir,
	# so we don't have to hop through enablerepo/disablerepo
	# loops to disable the host repos
	mkdir -p ${dest}/etc/yum.repos.d
	;;
*)
	# should not happen
	echo "Oops"
	exit 1
	;;
esac

mkdir -p ${dest}/{dev,proc,sys,mnt}
$BASE/makedev.sh "${dest}/dev"
inst=""
for item in $grps; do inst="${inst} @${item}"; done
for item in $rpms; do inst="${inst} ${item}"; done
msg "dnf install packages to $dest ..."
#sudo mount --bind /dev $dest/dev
#sudo mount -o remount,bind,ro $dest/dev
(set -x; sudo $tool $quiet install $inst)				|| exit 1
if test "$krnl" != ""; then
	msg "dnf install $krnl to $dest ..."
	(set -x; sudo $tool install $krnl)				|| exit 1
fi
sudo rm -rf "${dest}/var/cache/"{dnf,yum}

if test "$tarb" != ""; then
	case "$tarb" in
	*.gz)	topt="--gzip"
		;;
	*.xz)	topt="--xz"
		;;
	*)	topt=""
		;;
	esac
	msg "create tarball $tarb ..."
	(cd $dest; sudo tar --create $topt .) > "$tarb"
fi

msg "all done."
