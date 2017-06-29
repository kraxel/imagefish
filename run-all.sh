#!/bin/sh

BASE="$(dirname $0)"

case "$(hostname --short)" in
arm-b32 | cubietruck)
	# rebuild images
	./Fedora-rpi32.sh		|| exit 1
	./Fedora-efi-armv7.sh		|| exit 1
	;;
arm-b64)
	# rebuild images
	./Fedora-rpi64-fedora.sh	|| exit 1
	./Fedora-rpi64-kraxel.sh	|| exit 1
	./Fedora-efi-grub2.sh		|| exit 1
#	./Fedora-efi-systemd.sh		|| exit 1
	;;
nilsson)
	# rebuild images
	export IMAGEFISH_DESTDIR="/vmdisk/ext/imagefish"
	./RHEL73-efi.sh			|| exit 1
	./CentOS7-efi.sh		|| exit 1
	./Fedora-efi-grub2.sh		|| exit 1
	./Fedora-efi-systemd.sh		|| exit 1
	linux32 ./Fedora-efi-grub2.sh	|| exit 1
	linux32 ./Fedora-efi-systemd.sh	|| exit 1
	;;
sirius)
	# rebuild images
	export IMAGEFISH_DESTDIR="/vmdisk/hdd/imagefish"
#	./RHEL73-efi.sh			|| exit 1
#	./Fedora-efi-grub2.sh	25	|| exit 1
	./Fedora-efi-systemd.sh	25	|| exit 1
#	./Fedora-efi-grub2.sh	26	|| exit 1
	./Fedora-efi-systemd.sh	26	|| exit 1
	;;
*)
	echo "unknown host, don't know what to do"
	exit 1
	;;
esac

exec $BASE/push-images.sh
