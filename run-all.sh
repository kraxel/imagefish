#!/bin/sh

BASE="$(dirname $0)"

case "$(hostname --short)" in
arm-b32 | cubietruck)
	# rebuild images
	./Fedora-efi-grub2.sh			|| exit 1
	;;

arm-b64)
	# rebuild images
	./Fedora-efi-grub2.sh 			|| exit 1
#	./Fedora-efi-systemd.sh 		|| exit 1
	./CentOS8-efi.sh			|| exit 1
	;;

sirius)
	# rebuild images
	export IMAGEFISH_DESTDIR="/vmdisk/hdd/imagefish"
	./Fedora-efi-grub2.sh			|| exit 1
	./Fedora-efi-systemd.sh			|| exit 1
	./RHEL8-efi.sh		8.3		|| exit 1
	;;

sirius-el7)
	# rebuild images
	export IMAGEFISH_DESTDIR="/vmdisk/hdd/imagefish"
	./RHEL7-efi.sh		7.8		|| exit 1
	./RHEL7-efi.sh		7.9		|| exit 1
	./RHEL8-efi.sh		8.2		|| exit 1
	./RHEL8-efi.sh		8.3		|| exit 1
	;;

*)
	echo "unknown host, don't know what to do"
	exit 1
	;;
esac

#exec $BASE/push-images.sh
