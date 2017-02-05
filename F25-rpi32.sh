#!/bin/sh
arch="$(uname -m)"
tar="fedora-25-rpi-${arch}.tar.gz"
img="fedora-25-rpi-${arch}.raw"
set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh			\
	--config	repos/fedora-25.repo	\
	--tar		"$tar"			\
	--packages	"kernel bcm283x-firmware" \
	--dnf 
scripts/tar-to-image.sh				\
	--tar		"$tar"			\
	--image		"$img"			\
	--rpi32
