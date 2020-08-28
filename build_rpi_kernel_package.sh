#!/bin/bash

TAG=$1
if [ -z "$TAG" ] ; then
  echo "please provide a tag"
  exit 1
fi

#make note of the current directory so we can return back after the script
ORIG_DIR="$(pwd)"

#get the directory the script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#get the cross compilation tools
cd "$DIR"
[ -d tools ] || git clone https://github.com/raspberrypi/tools
export PATH="$PATH:$PWD/tools/arm-bcm2708/arm-linux-gnueabihf/bin"

#get the required suplemental libraries for arm
[ -d includes ] || mkdir includes
cd includes
if [ ! -f usr/include/memory.h ] ; then
  wget http://raspbian.raspberrypi.org/raspbian/pool/main/g/glibc/libc6-dev_2.28-10+rpi1_armhf.deb
  ar p libc6-dev_2.28-10+rpi1_armhf.deb data.tar.xz | tar xJf -
  [ ! -f usr/include/memory.h ] && echo "unable to get libraries" && exit 1
  rm libc6-dev_2.28-10+rpi1_armhf.deb
fi
if [ ! -d usr/include/openssl ] ; then
  wget http://raspbian.raspberrypi.org/raspbian/pool/main/o/openssl/libssl-dev_1.1.1d-0+deb10u3_armhf.deb
  ar p libssl-dev_1.1.1d-0+deb10u3_armhf.deb data.tar.xz | tar xJf -
  [ ! -d usr/include/openssl ] && echo "unable to get libraries" && exit 1
  rm libssl-dev_1.1.1d-0+deb10u3_armhf.deb
fi
if [ ! -f lib/arm-linux-gnueabihf/libc.so.6 ] ; then
  wget http://raspbian.raspberrypi.org/raspbian/pool/main/g/glibc/libc6_2.28-10+rpi1_armhf.deb
  ar p libc6_2.28-10+rpi1_armhf.deb data.tar.xz | tar xJf -
  [ ! -f lib/arm-linux-gnueabihf/libc.so.6 ] && echo "unable to get libraries" && exit 1
fi

#if the repository has already been cloned, update it.  otherwise, clone it
if [ -d "$DIR/linux" ] ; then
  cd "$DIR/linux"
  git fetch
else
  cd "$DIR"
  git clone https://github.com/raspberrypi/linux
  cd linux
fi

#switch to the tag
git checkout $TAG
CUR_TAG=$(git describe --tags)  

#if we're not on the desired tag, exit with error
if [ "$CUR_TAG" != "$TAG" ] ; then
  echo "Unable to find tag: $TAG"
  exit 1
fi

KVERS="$(make kernelversion)"
TAGVERS=$(echo $TAG | sed 's/raspberrypi-kernel_//g')

#work around the deb-pkg bug when cross-compiling
#and
#change the kernel image filename to be rpi-compatible
cd scripts/package
patch < "$DIR/builddeb.patch"
cd ../..


make clean
[ -d debian ] && rm -rf debian
[ -f .version ] && rm .version
KERNEL=kernel
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig
$DIR/customizations.sh
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bindeb-pkg

make clean
[ -d debian ] && rm -rf debian
[ -f .version ] && rm .version
KERNEL=kernel7
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig
$DIR/customizations.sh
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bindeb-pkg

make clean
[ -d debian ] && rm -rf debian
[ -f .version ] && rm .version
KERNEL=kernel7l
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2711_defconfig
$DIR/customizations.sh
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bindeb-pkg

#revert the Makefile back to the original
git checkout Makefile

#revert the builddeb file back to the original
git checkout scripts/package/builddeb


#set up metapackages
cd "$DIR"
sed -i "s/^Depends:.*/Depends: linux-image-$KVERS-asl+,linux-image-$KVERS-v7-asl+,linux-image-$KVERS-v7l-asl+/g" asl-raspberrypi-kernel-metapackage/asl-raspberrypi-kernel
sed -i "s/^Depends:.*/Depends: linux-headers-$KVERS-asl+,linux-headers-$KVERS-v7-asl+,linux-headers-$KVERS-v7l-asl+/g" asl-raspberrypi-kernel-headers-metapackage/asl-raspberrypi-kernel-headers
sed -i "s/^Version:.*/Version: $TAGVERS/g" asl-raspberrypi-kernel-metapackage/asl-raspberrypi-kernel
sed -i "s/^Version:.*/Version: $TAGVERS/g" asl-raspberrypi-kernel-headers-metapackage/asl-raspberrypi-kernel-headers

#build metapackages
equivs-build asl-raspberrypi-kernel-metapackage/asl-raspberrypi-kernel
equivs-build asl-raspberrypi-kernel-headers-metapackage/asl-raspberrypi-kernel-headers

#reset metapackage control files
sed -i "s/^Depends:.*/Depends: /g" asl-raspberrypi-kernel-metapackage/asl-raspberrypi-kernel
sed -i "s/^Depends:.*/Depends: /g" asl-raspberrypi-kernel-headers-metapackage/asl-raspberrypi-kernel-headers
sed -i "s/^Version:.*/Version: /g" asl-raspberrypi-kernel-metapackage/asl-raspberrypi-kernel
sed -i "s/^Version:.*/Version: /g" asl-raspberrypi-kernel-headers-metapackage/asl-raspberrypi-kernel-headers

#return back to the original directory
cd $ORIG_DIR
