#
# rhel8 kickstart file to build images which
# boot in both bios and uefi mode
#
# usage:
#  - run install in bios mode
#  - run install with virtio-scsi disk (so /dev/sda exists)
#

# minimal config
rootpw --plaintext root
firstboot --disable
reboot

# bios/uefi boot partitioning
ignoredisk --only-use=sda
clearpart --all --initlabel --disklabel=gpt --drives=sda
part biosboot  --size=1   --fstype=biosboot
part /boot/efi --size=100 --fstype=efi
part /boot     --size=500 --fstype=xfs --label=boot
part /         --size=999 --fstype=xfs --label=root --grow
bootloader --location=mbr --append="console=ttyS0"

# minimal package list
%packages
@^minimal-environment
grub2-pc
grub2-efi-x64
shim
-dracut-config-rescue
dracut-config-generic
%end

%post

# setup uefi boot
grub2-mkconfig -o /etc/grub2-efi.cfg
parted /dev/sda disk_set pmbr_boot off

# setup bios boot
grubcfg=$(echo /boot/efi/EFI/*/grub.cfg)
grubcfg=${grubcfg#/boot/efi}
cat <<EOF > /etc/grub2.cfg
search --no-floppy --set efi --file $grubcfg
configfile (\$efi)$grubcfg
EOF

%end
