#!/bin/sh
image="$1"
if test "$image" = ""; then
	echo "usage: $0 <image>"
	exit 1
fi

WORK="${TMPDIR-/tmp}/${0##*/}-$$"
mkdir "$WORK" || exit 1
trap 'rm -rf "$WORK"' EXIT

cat <<EOF > "$WORK/script"

# turn off initial-setup
delete /etc/systemd/system/multi-user.target.wants/initial-setup.service
delete /etc/systemd/system/graphical.target.wants/initial-setup.service

EOF

set -ex
virt-customize -a "$image" --no-network --commands-from-file "$WORK/script"
