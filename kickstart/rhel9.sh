#!/bin/sh

# config
name="rhel"
dest="/vmdisk/hdd/imagefish"

base="http://sirius.home.kraxel.org/rhel-9/rel-eng/RHEL-9"
vers="9.0.0"

for v in $vers; do
	repo="${base}/latest-RHEL-${v}/compose/BaseOS/x86_64/os/"

	disk="${dest}/${name}-efi-${v}-ks-x86_64.qcow2"
	../scripts/run-kickstart-install.sh "$disk" "$repo" el9-efi.ks
	sudo chown kraxel.kraxel "$disk"

	disk="${dest}/${name}-${v}-ks-x86_64.qcow2"
	../scripts/run-kickstart-install.sh "$disk" "$repo" el9.ks
	sudo chown kraxel.kraxel "$disk"
done
