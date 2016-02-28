#!/bin/bash

# BerryBoot Image Creator V1
# Copyright 2016 Patrick G
# http://geek1011.github.io
# http://github.com/geek1011/BerryBootImageCreator

if [ "$EUID" -ne 0 ]
then 
    echo 1>&2 "Please run as root"
    exit 1
fi

if [ $# -ne 1 ]
then
    echo 1>&2 "No image file specified"
    echo "Usage: $0 PATH/TO/IMAGE.img"
    exit 1
fi

if [ -f "$1" ]
then
    echo "Image to convert: $1"
else
    echo 1>&2  "Invalid image file name: $1"
    exit 1
fi

echo Mounting image file
kpartx=$(kpartx -avs $1) || echo 1>&2 "Could not setup loop-back to $1" ; echo 1>&2
sleep 1
read img_boot_dev img_root_dev <<<$(grep -o 'loop.p.' <<<"$kpartx")

test "$img_boot_dev" -a "$img_root_dev" || echo 1>&2 "Could not extract boot and root loop device from kpartx output: $kpartx" ; echo 1>&2
img_boot_dev=/dev/mapper/$img_boot_dev
img_root_dev=/dev/mapper/$img_root_dev
   
img_root_dir=$(mktemp -d)
mount $img_root_dev $img_root_dir || echo 1>&2 "Cannot mount image root dir" ; echo 1>&2

echo Updating the fstab in the image file
sed -i 's/^\/dev\/mmcblk/#\0/g' $img_root_dir/etc/fstab

echo Making squashfs image
new_file=$(echo berryboot-$(basename $1))
mksquashfs $img_root_dir $new_file -comp lzo -e lib/modules -noappend 2>&1 | grep %

echo Cleaning up
umount $img_root_dir
kpartx -d $1

echo Created BerryBoot image for $1 with filename $new_file

