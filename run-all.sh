#!/bin/sh

BASE="$(dirname $0)"

case "$(hostname --short)" in
arm-b32 | cubietruck)
	# rebuild images
#	./Fedora-rpi32.sh		29	|| exit 1
	./Fedora-efi-armv7.sh		29	|| exit 1
	;;
arm-b64)
	# rebuild images
#	./Fedora-rpi64.sh		29	|| exit 1
	./Fedora-efi-grub2.sh 		29	|| exit 1
	./Fedora-efi-systemd.sh 	29	|| exit 1
	;;
sirius)
	# rebuild images
	export IMAGEFISH_DESTDIR="/vmdisk/hdd/imagefish"

	./Fedora-efi-grub2.sh		29	|| exit 1
	./Fedora-efi-systemd.sh		29	|| exit 1
	linux32 ./Fedora-efi-systemd.sh	29	|| exit 1

	./RHEL75-efi.sh				|| exit 1
	./RHEL76-efi.sh				|| exit 1
	./RHEL80-efi.sh				|| exit 1
	./CentOS7-efi.sh			|| exit 1
	;;
*)
	echo "unknown host, don't know what to do"
	exit 1
	;;
esac

exec $BASE/push-images.sh
