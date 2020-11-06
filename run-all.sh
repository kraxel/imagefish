#!/bin/sh

BASE="$(dirname $0)"
FVER="31"

case "$(hostname --short)" in
arm-b32 | cubietruck)
	# rebuild images
	./Fedora-efi-grub2.sh		$FVER	|| exit 1
	;;

arm-b64)
	# rebuild images
	./Fedora-efi-grub2.sh 		$FVER	|| exit 1
#	./Fedora-efi-systemd.sh 	$FVER	|| exit 1
	./CentOS8-efi.sh			|| exit 1
	;;

fedora)
	# rebuild images
	export IMAGEFISH_DESTDIR="$HOME/imagefish"
	./Fedora-efi-grub2.sh		$FVER	|| exit 1
	./Fedora-efi-systemd.sh		$FVER	|| exit 1
	;;

sirius)
	# rebuild images
	export IMAGEFISH_DESTDIR="/vmdisk/hdd/imagefish"

	./RHEL7-efi.sh		7.6		|| exit 1
	./RHEL7-efi.sh		7.7		|| exit 1
	./RHEL8-efi.sh		8.0.0		|| exit 1
	./RHEL8-efi.sh		8.1.0		|| exit 1
	./CentOS7-efi.sh			|| exit 1
	./CentOS8-efi.sh	8		|| exit 1
	./CentOS8-efi.sh	8-stream	|| exit 1
	;;

*)
	echo "unknown host, don't know what to do"
	exit 1
	;;
esac

#exec $BASE/push-images.sh
