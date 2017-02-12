#!/bin/sh
image="$1"
passwd="$2"
if test "$image" = ""; then
	echo "usage: $0 <image> <root-password>"
	exit 1
fi
set -ex
virt-customize -a "$image"		\
	--timezone "Europe/Berlin"	\
	--edit "/etc/vconsole.conf:s/KEYMAP=.*/KEYMAP=de-nodeadkeys/"
