# minimal config
rootpw --plaintext root
firstboot --disable
reboot

# experimental bits: edk2-ext4 + edk2-shell + kernel-initrd-virt
repo --name=kraxel --baseurl=http://sirius.home.kraxel.org/repo/

# bios/uefi boot partitioning
ignoredisk --only-use=sda
clearpart --all --initlabel --disklabel=gpt --drives=sda
part /boot/efi --size=100 --fstype=efi
part /boot     --size=500 --fstype=ext4 --label=boot
part /         --size=999 --fstype=xfs --label=root --grow
bootloader --append="console=ttyS0"

# minimal package list
%packages
@core
-shim-x64
-grub2-efi-x64
-dracut-config-rescue
dracut-config-generic
efibootmgr

kernel-core
kernel-initrd-virt
-kernel
-kernel-modules
%end

%post

if test ! -f /boot/efi/EFI/BOOT/BOOTX64.EFI; then
    # no bootloader present -> go install systemd-boot
    /usr/bin/bootctl install
fi

kver=$(cd /lib/modules; echo *)
if test -f /lib/modules/${kver}/initrd; then
    # anaconda ignores the pre-generated initrd -> fixup
    cp /lib/modules/${kver}/initrd /boot/initramfs-${kver}.img
fi

# setup discoverable partitions
/usr/sbin/sfdisk --part-type /dev/sda 2 BC13C2FF-59E6-4262-A352-B275FD6F7172  # Linux extended boot
/usr/sbin/sfdisk --part-type /dev/sda 3 4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709  # Linux root (x86-64)

# anaconda refuses to use vfat for /boot -> fixup
set -x
tmpboot="/tmp/boot.fs"
umount -v /boot/efi
mkdir ${tmpboot}
mv -v /boot/* ${tmpboot}
umount -v /boot
mkfs.vfat -n boot /dev/sda2
sed -i -e '/ext4/s|.*|LABEL=boot /boot vfat defaults,uid=0,gid=0,umask=022,shortname=winnt 1 2|' /etc/fstab
cat /etc/fstab
mount -v /boot
mv -v ${tmpboot}/* /boot
rmdir ${tmpboot}
mount -v /boot/efi

%end
