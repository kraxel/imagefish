#!/bin/sh
#
# create virt builder index snippets
#

info="$1"
base="${info%.info}"
dest="${base}.index"
name="${base##*/}"

file="$(jq -r .filename $info)"
if test ! -f "$file"; then
    file="${file}.xz"
fi
if test ! -f "$file"; then
    echo "ERROR: file ${file} not found"
    exit 1
fi

name="${name%-x86_64}"
case "$file" in
    *x86_64*)
	arch="x86_64"
	;;
    *)
	echo "ERROR: unknown arch"
	exit 1
	;;
esac

size="$(jq -r '."virtual-size"' $info)"
csum="$(sha256sum $file | cut -d' ' -f1)"
comp="$(du --bytes $file | cut -d' ' -f1)"

cat <<EOF | tee "$dest"
[${name}]
name=${name}
arch=${arch}
file=${file}
checksum[sha512]=${csum}
format=qcow2
size=${size}
compressed_size=148947524
#expand=/dev/sda<x>

EOF
