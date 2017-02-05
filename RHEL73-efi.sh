#!/bin/sh
arch="$(uname -m)"
tar="rhel-73-efi-${arch}.tar.gz"
img="rhel-73-efi-${arch}.qcow2"
set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh			\
	--config	repos/rhel-73.repo	\
	--tar		"$tar"			\
	--packages	"grub2-efi shim kernel"	\
	--yum
scripts/tar-to-image.sh				\
	--tar		"$tar"			\
	--image		"$img"			\
	--efi
