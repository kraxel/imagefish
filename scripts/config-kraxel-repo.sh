#!/bin/sh
image="$1"
arch="$2"
if test "$image" = ""; then
	echo "usage: $0 <image> [ <arch> ]"
	exit 1
fi
if test "$arch" = ""; then
	arch="$(uname -m)"
	echo "# ${0##*/}: no arch given, using native ($arch)"
fi

WORK="${TMPDIR-/tmp}/${0##*/}-$$"
mkdir "$WORK" || exit 1
trap 'rm -rf "$WORK"' EXIT

cat <<EOF > "$WORK/kraxel-armv7.repo"
[kraxel-armv7-spunk]
name=kraxels armv7 rpms (rpi2) [spunk]
baseurl=http://spunk.home.kraxel.org/mockify/repos/rpi2/
metadata_expire=5m
gpgcheck=0
throttle=0
enabled=0
cost=90

[kraxel-armv7-public]
name=kraxels armv7 rpms (rpi2) [public]
baseurl=https://www.kraxel.org/repos/rpi2/
gpgcheck=0
enabled=1

EOF

cat <<EOF > "$WORK/kraxel-aarch64.repo"
[kraxel-aarch64-spunk]
name=kraxels aarch64 rpms (rpi3/qcom) [spunk]
baseurl=http://spunk.home.kraxel.org/mockify/repos/qcom/
metadata_expire=5m
gpgcheck=0
throttle=0
enabled=0
cost=90

[kraxel-aarch64-public]
name=kraxels aarch64 rpms (rpi3/qcom) [public]
baseurl=https://www.kraxel.org/repos/qcom/
gpgcheck=0
enabled=1

EOF

case "$arch" in
armv7*)
	virt-copy-in -a "$image" $WORK/kraxel-armv7.repo /etc/yum.repos.d
	;;
aarch64)
	virt-copy-in -a "$image" $WORK/kraxel-aarch64.repo /etc/yum.repos.d
	;;
*)
	echo "unknown arch: $arch"
	exit 1
esac
