#!/bin/bash

set -x

# get tools
sudo yum install -y squashfs-tools zerofree


# Create the squashfs file from the original
#   Original in the minimal iso


git=$PWD

mode=${1:-gnome}

if [ "$mode" == "gnome" ]; then
    isoname=CentOS-7-x86_64-LiveGNOME-1908.iso
    imagepath=isolinux
    imagesuffix=0
    rootfsname=ext3fs
else
    mode=minimal
    isoname=CentOS-7-x86_64-Minimal-1908.iso
    imagepath=images/pxeboot
    imagesuffix=""
    rootfsname=rootfs
fi

basedir=/var/tmp/squashy

iso=$basedir/$isoname

mntpt=$basedir/mntpt
images=$basedir/images
workdir=$basedir/workdir

unpack=$workdir/unpack
rootfs=$workdir/rootfs
sqorig=$workdir/sq.orig

sqnew=$images/squashfs-$mode.img



sudo rm -Rf $mntpt $images $workdir
mkdir -p $basedir $mntpt $images $workdir

if [ ! -f $iso ]; then
    wget -O $iso "http://centos.mirror.nucleus.be/7.7.1908/isos/x86_64/$isoname"
fi

# get data from iso
sudo mount -o loop "$iso"  $mntpt

cp $mntpt/$imagepath/initrd$imagesuffix.img $images/initrd-$mode.img
cp $mntpt/$imagepath/vmlinuz$imagesuffix $images/vmlinuz-$mode

cp $mntpt/LiveOS/squashfs.img $sqorig

sudo umount $mntpt

# unpack squashfs
cd $workdir
# make sure it does not exist
sudo rm -Rf $unpack
sudo unsquashfs -d $unpack $sqorig

mkdir -p $rootfs
rootfsimg=$unpack/LiveOS/$rootfsname.img
sudo mount -o loop $rootfsimg $rootfs

# remove some stuff
sudo chroot $rootfs yum remove -y gnome* libreoffice*

# customise from git repo

# git does not always do the right thing
chmod 700 $git/src/root/.ssh
chmod 400 $git/src/root/.ssh/authorized_keys

sudo cp -R --preserve=mode $git/src/* $rootfs

# recreate squashfs
sudo umount $rootfs

sudo e2fsck -E discard $rootfsimg
sudo zerofree $rootfsimg

sudo mksquashfs $unpack $sqnew

sudo rm -Rf $workdir
