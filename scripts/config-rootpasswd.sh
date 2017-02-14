#!/bin/sh
image="$1"
passwd="$2"
if test "$image" = "" -o "$passwd" = ""; then
	echo "usage: $0 <image> <root-password>"
	exit 1
fi
set -ex
virt-customize -a "$image" --no-network --root-password "password:$passwd"
