#!/bin/bash

set -e -u -o pipefail

packages="libpython3.7-minimal libpython3.7-stdlib python3.7-minimal python3.7 python3"
pypackages="RPi.GPIO adafruit-circuitpython-us100 pyserial"

if [[ "$(uname -m)" != "armv6l" ]]; then
	echo "Please run this on armv6l (e.g. a Raspberry Pi)"
	exit 3
fi

rm -rf .build
mkdir -p .build/root
cd .build

apt-get download $packages
for package in *deb; do dpkg-deb -x $package root; done
virtualenv --python python3 root/virtualenv
root/virtualenv/bin/pip3 install $pypackages
mksquashfs root overlay.squashfs
mv overlay.squashfs ..
cd ..
echo Finished generating overlay.squashfs
