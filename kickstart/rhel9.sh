#!/bin/sh

# config
name="rhel"
dest="/vmdisk/hdd/imagefish"

#base="http://sirius.home.kraxel.org/rhel-9/rel-eng/RHEL-9"
base="http://sirius.home.kraxel.org/rhel-9/nightly/RHEL-9-Beta"
vers="9.0.0"

for v in $vers; do
	disk="${dest}/${name}-${v}-ks-x86_64.qcow2"
	repo="${base}/latest-RHEL-${v}/compose/BaseOS/x86_64/os/"
	../scripts/run-kickstart-install.sh "$disk" "$repo" fedora.ks
	sudo chown kraxel.kraxel "$disk"
done
