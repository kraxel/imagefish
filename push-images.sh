#!/bin/sh

if test -d "$HOME/repo/images-testing"; then
	echo
	echo "# rsync uncompressed images"
	rsync --verbose --progress \
		*.raw *.qcow2 $HOME/repo/images-testing

	echo
	echo "# compress images"
	rm -f *.xz
	xz --verbose --keep *.raw *.qcow2

	echo
	echo "# rsync compressed images"
	rsync --verbose --progress \
		*.xz $HOME/repo/images-testing
fi
