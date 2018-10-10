#!/bin/sh

# args
match="$1"

# config
src="/vmdisk/hdd/pool-iso"
dst="/vmdisk/hdd/pool-disk"

iso="$(ls -t $src/Clover-*${match}*-X64.iso | head -1)"
img="${iso#$src/}"
img="${img%.iso}"

# rebuild clover image
for config in clover/*.plist; do
	variant="${config}"
	variant="${variant%.plist}"
	variant="${variant#clover/}"
	variant="${variant#config}"
	variant="${variant#-}"
	if test "$variant" = ""; then variant="default"; fi
	out="${dst}/${img}-${variant}.qcow2"

	echo
	echo "#"
	echo "# $config => $out"
	echo "#"
	rm -f "$out"
	(set -x; scripts/clover-image.sh	\
		--cfg "$config"			\
		--iso "$iso"			\
		--drv "$src/apfs.efi"		\
		--img "$out")
done
