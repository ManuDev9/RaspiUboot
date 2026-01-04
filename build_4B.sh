#!/bin/bash

if [ ! -d "u-boot" ]; then
    git clone https://source.denx.de/u-boot/u-boot.git
fi

pushd u-boot

make V=1 O=output distclean
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

make V=1 O=output rpi_4_defconfig
make V=1 O=output -j$(nproc)

popd
