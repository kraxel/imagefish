#!/bin/sh
image="$1"
if test "$image" = ""; then
	echo "usage: $0 <image>"
	exit 1
fi

set -ex
virt-customize -a "$image" --no-network \
	--delete /etc/systemd/system/multi-user.target.wants/initial-setup.service \
	--delete /etc/systemd/system/graphical.target.wants/initial-setup.service
