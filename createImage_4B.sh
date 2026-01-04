#!/bin/bash

pushd u-boot

# Create a 42MB image (enough for U-Boot testing)
IMAGE="rpi4-u-boot-only.img"
BOOT_SIZE=40M  # FAT32 boot partition
IMAGE_SIZE=42M # Total image size

# Clean up old image
rm -f $IMAGE

# Create empty image file
dd if=/dev/zero of=$IMAGE bs=1M count=$(echo $IMAGE_SIZE | sed 's/M//') status=progress

# Create partition table and partitions
sudo parted $IMAGE --script mklabel msdos
sudo parted $IMAGE --script mkpart primary fat32 1MiB $BOOT_SIZE
sudo parted $IMAGE --script mkpart primary ext4 $BOOT_SIZE 100%

# Set boot flag on first partition
sudo parted $IMAGE --script set 1 boot on

# Check partition layout
sudo fdisk -l $IMAGE

# Find next available loop device
LOOPDEV=$(sudo losetup -f)

# Setup loop device with partitions
sudo losetup -P $LOOPDEV $IMAGE

# Format partitions
sudo mkfs.vfat -F 32 -n bootfs ${LOOPDEV}p1
sudo mkfs.ext4 -L rootfs ${LOOPDEV}p2

# Create mount points and mount
mkdir -p /tmp/rpi-boot
sudo mount ${LOOPDEV}p1 /tmp/rpi-boot

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
sudo losetup -d $LOOPDEV
rmdir /tmp/rpi-boot

# Show image info
echo "=== Image Created ==="
ls -lh $IMAGE

mv $IMAGE ../

popd
