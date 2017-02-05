#!/bin/sh

######################################################################
# defaults

dest=""
tarb=""
tool="dnf"
grps="core"
rpms=""
conf=""

######################################################################
# create work dir

WORK="${TMPDIR-/var/tmp}/${0##*/}-$$"
mkdir "$WORK" || exit 1
trap 'sudo rm -rf "$WORK"' EXIT

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
    --packages <rpms>
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
	echo "ERROR: tarball exists: $tarb"
	exit 1
fi

######################################################################
# go!

case "$tool" in
dnf)
	tool="$tool -y --quiet --installroot ${dest}"
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

inst=""
for item in $grps; do inst="${inst} @${item}"; done
for item in $rpms; do inst="${inst} ${item}"; done
echo "### dnf install to $dest ..."
(set -x; sudo $tool install $inst)					|| exit 1
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
	echo "### create tarball ..."
	(cd $dest; sudo tar --create $topt .) > "$tarb"
fi

echo "### done, cleanup ..."

