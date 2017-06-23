
# Imagefish

### What is this?

It's a bunch of scripts to create bootable linux distro images.
I'm using it for both arm toys (raspberry pi) and for qemu.

It's a two-step process.  First the distro is installed to a
directory, then the directory is tar'ed up.  This needs root
priviledges, the scripts use sudo for that.  Second the actual image
is created, using guestfish.  That works without root priviledges.

Optional third step is to tweak the image configuration, again using
guestfish.

### How to use this?

The most interesting stuff is in the `scripts/` directory.

 * `install-redhat.sh` can install Fedora, RHEL and CentOS into a
   directory (first step).
 * `tar-to-image.sh` creates the images (second step).
 * various `config-*.sh` scripts can configure images (third step).

The `repos/` directory has yum/dnf config files for various distros.
They will *not* work out of the box for you as they are tweaked for my
home network.  They use either the mirror or the cachine proxy running
on my local server box.

The short scripts in the root directory call the scripts in `scripts/`
with different parameters to create different images.
