# minimal config
rootpw --plaintext root
firstboot --disable
reboot

# bios/uefi boot partitioning
ignoredisk --only-use=sda
clearpart --all --initlabel --disklabel=gpt --drives=sda
part /boot/efi --size=100 --fstype=efi
part /boot     --size=500 --fstype=xfs --label=boot
part /         --size=999 --fstype=xfs --label=root --grow
bootloader --append="console=ttyS0"

# minimal package list
%packages
@core
shim-x64
grub2-efi-x64
-dracut-config-rescue
dracut-config-generic
%end

%post

# setup discoverable partitions
/usr/sbin/sfdisk --part-type /dev/sda 2 BC13C2FF-59E6-4262-A352-B275FD6F7172  # Linux extended boot
/usr/sbin/sfdisk --part-type /dev/sda 3 4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709  # Linux root (x86-64)

%end
