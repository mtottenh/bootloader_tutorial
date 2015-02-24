#!/bin/bash

# Force refreshing the image
if [ -e hdd_image ]; then rm hdd_image; fi

make hdd_image

echo -e "\n\n\n####### FIRING UP QEMU #######"
qemu-system-x86_64 hdd_image

