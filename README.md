# ASL_rpi_kernel_packager
Kernel packager for Raspberry Pi.  Customized for ASL.

This repository contains the build scripts and patches necessary to automatically build a set of kernel packages for the Raspberry Pi using RaspberryOS (Raspbian) sources.  Unlike the original kernel packages, I've chosen to build separate packages for each of the 3 Raspberry Pi types and a metapackage that replaces/provides the official kernel package.  I've worked around the issue of cross-compiling helper scripts that seems to plague most cross-compiled header packages by quickly cross-compiling the scripts after the kernel build, but before packaging.

The main build script takes care of downloading the cross-compilation tools, libraries, and kernel source.  There are certainly some build depencdencies that I don't remember right now and will have to document later.  Start with the standard kernel build/packaging dependencies.

This particular version is customized for ASL (AllStarLink) and includes the OSS kernel modules necessary for chan_usbradio and chan_simpleusb.  This is a stop-gap measure until those channel modules can be migrated to Alsa.

To use this packager, clone the repository and run the main build script:
<pre>./build_rpi_kernel_package.sh {tag}</pre>

Where {tag} is the tagged version of the RaspberryOS kernel repository you'd like to target.  The current list of tags is available at https://github.com/raspberrypi/linux/tags

As of this writing, the most current tag is raspberrypi-kernel_1.20200811-1


# Building with docker
```
docker run -it debian:buster /bin/bash

apt update && apt install -y build-essential git equivs \
wget \
apt-utils \
flex \
bison \
bc rsync kmod cpio libssl-dev:native

git clone https://github.com/ajpaul25/ASL_rpi_kernel_packager.git

cd ASL_rpi_kernel_packager
./build_rpi_kernel_package.sh raspberrypi-kernel_1.20200811-1
```

