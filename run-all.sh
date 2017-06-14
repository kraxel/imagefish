#!/bin/sh

BASE="$(dirname $0)"

case "$(hostname --short)" in
arm-b32 | cubietruck)
	# rebuild images
	./F25-rpi32.sh		|| exit 1
	./F25-efi-armv7.sh	|| exit 1
	;;
arm-b64)
	# rebuild images
	./F25-rpi64-fedora.sh	|| exit 1
	./F25-rpi64-kraxel.sh	|| exit 1
	./F25-efi-grub2.sh	|| exit 1
#	./F25-efi-systemd.sh	|| exit 1
	;;
nilsson)
	# rebuild images
	export IMAGEFISH_DESTDIR="/vmdisk/ext/imagefish"
	./RHEL73-efi.sh			|| exit 1
	./CentOS7-efi.sh		|| exit 1
	./F25-efi-grub2.sh		|| exit 1
	./F25-efi-systemd.sh		|| exit 1
	linux32 ./F25-efi-grub2.sh	|| exit 1
	linux32 ./F25-efi-systemd.sh	|| exit 1
	;;
sirius)
	# rebuild images
	export IMAGEFISH_DESTDIR="/vmdisk/hdd/imagefish"
	./RHEL73-efi.sh			|| exit 1
	;;
*)
	echo "unknown host, don't know what to do"
	exit 1
	;;
esac

exec $BASE/push-images.sh
