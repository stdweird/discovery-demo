# discovery-demo

Demo boot discovery pxe boot images based on live iso

Based on work done for hpcugent (https://github.com/hpcugent)

# What is it?

Generate a customised image that can be pxe booted. The example `discovery` service gathers some basic host info and sends it to a syslog server.
The discovery script can also run other scripts.

# Customise

Add files and symlnks to the src directory, and run the `mkdiscovery.sh` script to generate the image.
The end result is in the `/var/tmp/squashy/images` directory.

E.g. add repository files in `src/etc/yum.config.d/some.repo`.

One can also modify the `discovery.sh` script that is the main service unit (it is run the system update unit).

# Example pxelinux.cfg

Example `pxelinux.cfg` configuration. The required kernel and vmlinuz files (and the generated image) are in `/var/tmp/squashy/images` directory.

  default discovery gnome
  label discovery gnome
    kernel discovery/vmlinuz-minimal
    append selinux=0 ip=dhcp rd.writable.fsimg=1 initrd=discovery/initrd-minimal.img root=live:http://some.ip.example/discovery/squashfs-gnome.img discovery_update_firmware=1

## more append options

See http://man7.org/linux/man-pages/man7/dracut.cmdline.7.html
