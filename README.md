# RaspiUboot
A few bash scripts to generate a working image, sd card, or usb to boot uboot on a raspi

NOTE: Only for the Raspi 4B.

## How to use

Build the required files with

``` 
./build_4B.sh
``` 


Then put the SD Card or USB on your PC and check which device it is

``` 
lsblk
```

Run the the flasher

``` 
DEV_DEVICE=/dev/sda ./flashUSBorSD_4B.sh 
``` 

NOTE:Change with the name of your device

Insert the SD card or the USB on the raspi and power it on.

## Console

The output will be on the Primary UART pins:
https://www.raspberrypi.com/documentation/computers/configuration.html#primary-uart


You will need something to connect the pins to your PC like this:

* FTDI - TTL-232R-3V3 - USB TO SERIAL CONVERTER CABLE, 3.3V, 6WAY 

## Create Image

The `createImage_4B.sh` is a script that creates an image file with what is needed.
Useful in case you have a system that can expose the image file on a USB-A male cable 