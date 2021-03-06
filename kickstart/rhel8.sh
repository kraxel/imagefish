#!/bin/sh

# config
name="rhel"
base="http://spunk.home.kraxel.org/mirror/rhel/redhat/rhel-8/rel-eng/RHEL-8"
dest="/vmdisk/hdd/imagefish"
vers="8.2.0 8.1.0 8.0.0"

for v in $vers; do
	disk="${dest}/${name}-${v}-ks-x86_64.qcow2"
	repo="${base}/latest-RHEL-${v}/compose/BaseOS/x86_64/os/"
	./run-install.sh "$disk" "$repo"
	sudo chown kraxel.kraxel "$disk"
done
