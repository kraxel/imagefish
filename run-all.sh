#!/bin/sh

case "$(hostname --short)" in
cubietruck)
	# quirks
	export SUPERMIN_KERNEL=/boot/vmlinuz-4.9.5-200.fc25.armv7hl+lpae
	export SUPERMIN_KERNEL_VERSION=4.9.5-200.fc25.armv7hl+lpae
	rm -rf /var/tmp/.guestfs-500

	# rebuild images
	./F25-rpi32.sh		|| exit 1
	./F25-efi-armv7.sh	|| exit 1
	;;
arm-b64)
	# rebuild images
	./F25-rpi64-fedora.sh	|| exit 1
	./F25-rpi64-kraxel.sh	|| exit 1
	./F25-efi.sh		|| exit 1
	;;
nilsson)
	# rebuild images
	./RHEL73-efi.sh		|| exit 1
	;;
*)
	echo "unknown host, don't know what to do"
	exit 1
	;;
esac

if test -d "$HOME/repo/images-testing"; then
	echo
	echo "# rsync uncompressed images"
	rsync --verbose --progress \
		*.raw *.qcow2 $HOME/repo/images-testing

	echo "# compress images"
	rm -f *.xz
	xz --verbose --keep *.raw *.qcow2

	echo "# rsync compressed images"
	rsync --verbose --progress \
		*.xz $HOME/repo/images-testing
fi
