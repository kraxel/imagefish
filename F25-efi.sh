#!/bin/sh
arch="$(uname -m)"
tar="fedora-25-efi-${arch}.tar.gz"
img="fedora-25-efi-${arch}.qcow2"
set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh			\
	--config	repos/fedora-25.repo	\
	--tar		"$tar"			\
	--packages	"grub2-efi shim kernel"	\
	--dnf 
scripts/tar-to-image.sh				\
	--tar		"$tar"			\
	--image		"$img"			\
	--efi
