#
# fedora 34+ kickstart file to build images which
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
bootloader --append="console=ttyS0"

# minimal package list
%packages
@core
grub2-pc
grub2-efi-x64
shim
-dracut-config-rescue
dracut-config-generic
%end

%post

# setup grub.cfg for uefi boot
grubefi=$(echo /boot/efi/EFI/*/grub*.efi)
grubcfg=${grubefi%/*}/grub.cfg
cat <<EOF > $grubcfg
# find and use grub.cfg on /boot filesystem
search --no-floppy --set boot --file /grub2/grub.cfg
configfile (\$boot)/grub2/grub.cfg
EOF

%end
