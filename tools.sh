#!/bin/bash

reduce_image() {
    # Sanity check
    local IMAGE_PATH=$1
    if [ ! -w ${IMAGE_PATH} ]; then
        echo "Cant access file"
        exit 1
    fi

    # Try to open or recover device & part
    local toDrop=false
    local loop=$(losetup -a | grep "${IMAGE_PATH}")
    local rootp=""
    local DEVICE=""
    if [ -z ${loop} ] ; then
        toDrop=true
        loop=$(kpartx -vas "${IMAGE_PATH}" | tail -n1)
        DEVICE=$(echo ${loop} | cut -d' ' -f 8)
        rootp="/dev/mapper/"$(echo ${loop} | cut -d' ' -f 3)
    else
        toDrop=false
        DEVICE=$(echo ${loop} | cut -d':' -f 1)
        rootp="/dev/mapper/"$(echo ${DEVICE} | cut -d'/' -f3)"p2"
    fi


    # Shrink filesystem
    e2fsck -f ${rootp}
    resize2fs ${rootp} -M -p

    # Shrink partition
    BLOCK_COUNT=$(dumpe2fs -h ${rootp} | grep "Block count" | cut -d ':' -f2 | tr -d ' ')
    BLOCK_SIZE=$(dumpe2fs -h ${rootp} | grep "Block size" | cut -d ':' -f2 | tr -d ' ')
    NEW_ROOTFS_SIZE=$(( ${BLOCK_COUNT} * ${BLOCK_SIZE} * 105 / 100 / 1024 + 1 ))
    fdisk ${DEVICE} << EOF
d
2
n
p


+${NEW_ROOTFS_SIZE}K
w
EOF

    kpartx -us "${DEVICE}"

    if [ "x${toDrop}" = "xtrue" ]; then
        kpartx -ds "${IMAGE_PATH}"
    fi

    # Shrink image file
    MAX_USED_SECTOR=$(fdisk -l -u ${IMAGE_PATH} | grep Linux | awk '{ print $3}')
    SECTOR_SIZE=$(fdisk -l -u ${IMAGE_PATH} | grep Units | sed 's/.* = \([0-9]*\) bytes/\1/')
    truncate --size=$(( ( ${MAX_USED_SECTOR} + 1 ) * ${SECTOR_SIZE} )) ${IMAGE_PATH}
}
