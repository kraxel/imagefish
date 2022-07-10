#!/bin/sh

# config
name="rhel"
dest="/vmdisk/hdd/imagefish"

base="http://sirius.home.kraxel.org/rhel-8/rel-eng/RHEL-8"
vers="8.6.0 8.5.0 8.4.0"

for v in $vers; do
	repo="${base}/latest-RHEL-${v}/compose/BaseOS/x86_64/os/"
	disk="${dest}/${name}-${v}-ks-x86_64.qcow2"
	../scripts/run-kickstart-install.sh "$disk" "$repo" el8.ks
	sudo chown kraxel.kraxel "$disk"
done
