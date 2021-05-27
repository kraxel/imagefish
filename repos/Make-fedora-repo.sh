#!/bin/sh

# config
mirror="http://spunk.home.kraxel.org/mirror/fedora/rsync"

basepri="http://fedora.mirror.kraxel.org/fedora/linux"
proxy="http://spunk.home.kraxel.org:3128"

################################################################################

function makerepo() {
	local basearch="$1"
	local releasever="$2"
	local kraxel=""

	case "$basearch" in
	aarch64)	base="$basepri"					;;
	armhfp)		base="$basepri"					;;
	x86_64)		base="$basepri"					;;
	*)		echo "unknown basearch: $basearch"; exit 1	;;
	esac

	cat <<EOF
[mkimage-fedora-${releasever}-server-mirror]
name=Fedora ${releasever} server mirror
baseurl=${mirror}/f${releasever}-release/Server/${basearch}/os/
cost=90

[mkimage-fedora-${releasever}-everything]
name=Fedora ${releasever} everything
baseurl=${base}/releases/${releasever}/Everything/${basearch}/os/
proxy=${proxy}

[mkimage-fedora-${releasever}-updates]
name=Fedora ${releasever} updates
baseurl=${base}/updates/${releasever}/Everything/$basearch/
proxy=${proxy}

EOF

	if test "$kraxel" != ""; then
		cat <<EOF
[mkimage-kraxel-${basearch}]
name=kraxels ${basearch} packages
baseurl=${kraxel}
enabled=1

EOF
	fi
}

################################################################################

rels="33 34"
archs="aarch64 armhfp x86_64"

for rel in $rels; do
	if test "$rel" = "$reldev"; then devel=1; else devel=0; fi
	for arch in $archs; do
		repofile="fedora-${rel}-${arch}.repo"
		echo "# writing $repofile"
		makerepo "$arch" "$rel" > "$repofile"
	done
done
