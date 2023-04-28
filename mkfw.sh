#!/bin/sh
set -e

INIT_FLAG=./buildroot/output/.mkfw.init

date=`date +%F`
version=$1

if [ 1 != $# ]; then
	echo please input version
  exit 1
fi

if [ ! -f "$INIT_FLAG" ]; then
  . ./init.sh
  : > "$INIT_FLAG"
fi

echo  "/* This file is auto generated. do not modify */ 
#define BMCVERSION \"${version}\"
#define BUILDTIME \"${date}\" " > app/bmc/version.h

if [ ! -d "build/${date}" ];then
    echo "mkdir build/${date}"
    mkdir -p "build/${date}"
fi

echo "----- make fw -----" 
echo "Version: ${version}" 
echo "Date: ${date}"

echo "build fw"
make -C buildroot bmc-rebuild V=1
make -C buildroot V=1
( set -x
  cp -rf buildroot/output/images/buildroot_linux_nand_uart3.img ./build/${date}/turingpi-${version}.img
)

cd buildroot/output/images/
./genSWU.sh
cd -

mv -f ./buildroot/output/images/turingpi_.swu ./build/${date}/turingpi-${version}.swu

echo "build turing pi firmware over"
if [ ! -f "build/tpi/linux/tpi" ];then
	mkdir -p build/tpi/linux
	echo "build tpi cli"
	gcc app/tpi/tpi.c -o build/tpi/linux/tpi
	echo "build tpi cli over"
fi

