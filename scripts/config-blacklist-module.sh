#!/bin/sh

image="$1"
module="$2"

if test "$image" = ""; then
	echo "usage: $0 <image> <module>"
	exit 1
fi

if virt-cat -a "$image" /etc/grub2-efi.cfg >/dev/null 2>&1; then
	bootedit="/etc/grub2-efi.cfg:s/^([ \t]*linux[ ]+[^ ]+)/\1 rd.driver.blacklist=${module}/"
else
	bootedit="/boot/extlinux/extlinux.conf:s/append/append rd.driver.blacklist=${module}/"
fi

set -ex
virt-customize -a "$image" --no-network \
	--edit "$bootedit" \
	--write "/etc/modprobe.d/blacklist-${module}.conf:blacklist ${module}"
