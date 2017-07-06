#!/bin/sh

dest="$HOME/repo/images-testing"

if test ! -d "$dest"; then
	echo "# not found: $dest"
	exit
fi

images=$(ls	${IMAGEFISH_DESTDIR-.}/*.raw	\
		${IMAGEFISH_DESTDIR-.}/*.qcow2	\
		2>/dev/null)
count=$(echo $images | wc -w)

if test "$count" = "0"; then
	echo "# no images"
	exit
fi

echo
echo "# rsync $count uncompressed images"
rsync --verbose --progress $images $dest

echo
echo "# compress $count images"
rm -f ${IMAGEFISH_DESTDIR-.}/*.xz
xz --verbose --keep $images

echo
echo "# rsync compressed images"
rsync --verbose --progress		\
	${IMAGEFISH_DESTDIR-.}/*.xz	\
	$dest
