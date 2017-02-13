#!/bin/sh
image="$1"
if test "$image" = ""; then
	echo "usage: $0 <image>"
	exit 1
fi

WORK="${TMPDIR-/tmp}/${0##*/}-$$"
mkdir "$WORK" || exit 1
trap 'rm -rf "$WORK"' EXIT

cat <<EOF > "$WORK/ethernet.network"

[Match]
Name=e*

[Network]
DHCP=v4

EOF

cat <<EOF > "$WORK/script"

# turn off NetworkManager
delete /etc/systemd/system/multi-user.target.wants/NetworkManager.service
delete /etc/systemd/system/dbus-org.freedesktop.NetworkManager.service
delete /etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service

# create dirs
mkdir /etc/systemd/network
mkdir /etc/systemd/system/multi-user.target.wants
mkdir /etc/systemd/system/sockets.target.wants
mkdir /etc/systemd/system/sysinit.target.wants

# turn on systemd networking
link /usr/lib/systemd/system/systemd-networkd.service:/etc/systemd/system/multi-user.target.wants/systemd-networkd.service
link /usr/lib/systemd/system/systemd-networkd.socket:/etc/systemd/system/sockets.target.wants/systemd-networkd.socket
link /usr/lib/systemd/system/systemd-resolved.service:/etc/systemd/system/multi-user.target.wants/systemd-resolved.service

# turn on systemd timesyncd
link /usr/lib/systemd/system/systemd-timesyncd.service:/etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service

# symlink resolv.conf
delete /etc/resolv.conf
link /run/systemd/resolve/resolv.conf:/etc/resolv.conf

# configure networking
copy-in $WORK/ethernet.network:/etc/systemd/network

EOF

set -ex
virt-customize -a "$image" --commands-from-file "$WORK/script"
