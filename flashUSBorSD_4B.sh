#!/bin/bash

if [[ ! -v DEV_DEVICE ]]; then
    echo "DEV_DEVICE is not defined or is empty. Exemple: export DEV_DEVICE='/dev/mmcblk0'"
    exit 1
fi

pushd u-boot

BOOT_SIZE=40M  # FAT32 boot partition

# Unmount
sudo umount $DEV_DEVICE

# Create partition table and partitions
sudo parted $DEV_DEVICE --script mklabel msdos
sudo parted $DEV_DEVICE --script mkpart primary fat32 1MiB $BOOT_SIZE
sudo parted $DEV_DEVICE --script mkpart primary ext4 $BOOT_SIZE 100%

# Set boot flag on first partition
sudo parted $DEV_DEVICE --script set 1 boot on

# Check partition layout
sudo fdisk -l $DEV_DEVICE

BOOT_PART=$(sudo fdisk -l "$DEV_DEVICE" | grep "^/dev/" | head -1 | awk '{print $1}')
ROOT_PART=$(sudo fdisk -l "$DEV_DEVICE" | grep "^/dev/" | tail -1 | awk '{print $1}')

echo "BOOT_PART = $BOOT_PART"
echo "ROOT_PART = $ROOT_PART"

# Format partitions
sudo mkfs.vfat -F 32 -n bootfs ${BOOT_PART}
sudo mkfs.ext4 -F -L rootfs ${ROOT_PART}

# Create mount points and mount
mkdir -p /tmp/rpi-boot
sudo mount ${BOOT_PART} /tmp/rpi-boot

# Copy U-Boot binary (from your build output)
sudo cp output/u-boot.bin /tmp/rpi-boot/u-boot.bin
sudo cp output/arch/arm/dts/bcm2711-rpi-4-b.dtb /tmp/rpi-boot/bcm2711-rpi-4-b.dtb

# Get firmware files (MANDATORY for USB boot)
FIRMWARE_SRC="https://github.com/raspberrypi/firmware/raw/master/boot"
echo "Downloading required firmware files..."
sudo wget -q -O /tmp/rpi-boot/start4.elf "$FIRMWARE_SRC/start4.elf"
sudo wget -q -O /tmp/rpi-boot/fixup4.dat "$FIRMWARE_SRC/fixup4.dat"

# Read config.txt bytes      255 hnd 0x00000000
# Read start4cd.elf bytes   849948 hnd 0x00000000
# Read fixup4cd.dat bytes     3272 hnd 0x00000000
# Starting start4cd.elf @ 0xff000200 partition 0

# Create minimal config.txt for U-Boot only boot
cat << EOF | sudo tee /tmp/rpi-boot/config.txt
# Minimal U-Boot configuration for RPi 4
arm_64bit=1
enable_uart=1
uart_2ndstage=1
kernel=u-boot.bin

EOF

echo "Image Boot content"
ls -lh /tmp/rpi-boot/

# Unmount and detach
sudo umount /tmp/rpi-boot
rmdir /tmp/rpi-boot

popd 