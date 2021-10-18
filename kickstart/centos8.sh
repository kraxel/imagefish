#!/bin/sh

# config
name="centos"
vers="8"
repo="http://spunk.home.kraxel.org/centos/8/BaseOS/x86_64/os/"
dest="/vmdisk/hdd/imagefish"

disk="${dest}/${name}-${vers}-ks-x86_64.qcow2"
./run-install.sh "$disk" "$repo" el8.ks
sudo chown kraxel.kraxel "$disk"
