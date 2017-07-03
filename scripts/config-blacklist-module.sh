#!/bin/sh

image="$1"
module="$2"

if test "$image" = ""; then
	echo "usage: $0 <image> <module>"
	exit 1
fi

set -ex
virt-customize -a "$image" --no-network \
	--edit "/boot/extlinux/extlinux.conf:s/append/append rd.driver.blacklist=${module}/" \
	--write "/etc/modprobe.d/blacklist-${module}.conf:blacklist ${module}"
