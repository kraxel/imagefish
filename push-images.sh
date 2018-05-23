#!/bin/sh

dest="$HOME/repo/images-testing"

if test ! -d "$dest"; then
	echo "# destdir not found ($dest)"
	exit
fi

images=$(ls	${IMAGEFISH_DESTDIR-.}/*.raw	\
		${IMAGEFISH_DESTDIR-.}/*.qcow2	\
		2>/dev/null)
count=$(echo $images | wc -w)

if test "$count" = "0"; then
	echo "# no images found"
	exit
fi

echo
echo "### rsync $count uncompressed image(s)"
echo
rsync --verbose --progress --implace	\
	$images $dest

echo
echo "### compress $count image(s)"
echo
rm -f ${IMAGEFISH_DESTDIR-.}/*.xz
xz --verbose --keep $images

echo
echo "### rsync compressed image(s)"
echo
rsync --verbose --progress --inplace	\
	${IMAGEFISH_DESTDIR-.}/*.xz	\
	$dest
