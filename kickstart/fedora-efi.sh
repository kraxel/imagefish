#!/bin/sh

# config
name="fedora-efi"
vers="36"
repo="http://spunk.home.kraxel.org/mirror/fedora/rsync/f${vers}-release/Server/x86_64/os/"
dest="/vmdisk/hdd/imagefish"

disk="${dest}/${name}-${vers}-ks-x86_64.qcow2"
../scripts/run-kickstart-install.sh "$disk" "$repo" "fedora-efi.ks"
sudo chown kraxel.kraxel "$disk"
boot-efi-image "$disk"
