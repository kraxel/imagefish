#!/bin/sh

# config
name="fedora"
vers="34"
repo="http://spunk.home.kraxel.org/mirror/fedora/rsync/f${vers}-release/Server/x86_64/os/"
dest="/vmdisk/hdd/imagefish"

disk="${dest}/${name}-${vers}-ks-x86_64.qcow2"
./run-install.sh "$disk" "$repo" "fedora.ks"
sudo chown kraxel.kraxel "$disk"
