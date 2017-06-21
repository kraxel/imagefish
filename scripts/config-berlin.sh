#!/bin/sh
image="$1"
if test "$image" = ""; then
	echo "usage: $0 <image>"
	exit 1
fi
set -ex
virt-customize -a "$image"		\
	--no-network			\
	--timezone "Europe/Berlin"	\
	--write "/etc/vconsole.conf:KEYMAP=de-nodeadkeys"
