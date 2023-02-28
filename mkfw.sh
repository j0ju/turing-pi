#!/bin/sh

date=`date +%F`

version="0.1.0-wip"

if [ ! -d "build/${date}" ];then
    echo "mkdir build/${date}"
    mkdir -p "build/${date}"
fi

echo "----- make fw -----" 
echo "Version: ${version}" 
echo "Date: ${date}"

echo "build fw"
make -C buildroot V=1
echo "cp -rf buildroot/output/images/buildroot_linux_nand_uart3.img ./build/${date}/turingpi-${version}.img"
cp -rf buildroot/output/images/buildroot_linux_nand_uart3.img ./build/${date}/turingpi-${version}.img

cd buildroot/output/images/
./genSWU.sh
cd -

cp -rf ./buildroot/output/images/turingpi_.swu ./build/${date}/turingpi-${version}.swu

echo "build turing pi firmware over"

