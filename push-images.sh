#!/bin/sh

if test -d "$HOME/repo/images-testing"; then
	echo
	echo "# rsync uncompressed images"
	rsync --verbose --progress		\
		${IMAGEFISH_DESTDIR-.}/*.raw	\
		${IMAGEFISH_DESTDIR-.}/*.qcow2	\
		$HOME/repo/images-testing

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
		$HOME/repo/images-testing
fi
