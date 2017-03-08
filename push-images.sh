#!/bin/sh

dest="$HOME/repo/images-testing"

if test -d "$dest"; then
	echo
	echo "# rsync uncompressed images"
	rsync --verbose --progress		\
		${IMAGEFISH_DESTDIR-.}/*.raw	\
		${IMAGEFISH_DESTDIR-.}/*.qcow2	\
		$dest

	echo
	echo "# compress images"
	rm -f ${IMAGEFISH_DESTDIR-.}/*.xz
	xz --verbose --keep			\
		${IMAGEFISH_DESTDIR-.}/*.raw	\
		${IMAGEFISH_DESTDIR-.}/*.qcow2

	echo
	echo "# rsync compressed images"
	rsync --verbose --progress		\
		${IMAGEFISH_DESTDIR-.}/*.xz	\
		$dest
fi
