#!/bin/sh
set -e

INIT_FLAG=./buildroot/output/.mkfw.init

DATE="$(date +%F)"
VERSION=$1

if [ 1 != $# ]; then
	echo 'E: $1 must be version number for this build, ABORT' >&2
  exit 1
fi

if [ ! -f "$INIT_FLAG" ]; then
  . ./init.sh
  : > "$INIT_FLAG"
fi

cat > app/bmc/version.h <<EOF
/* This file is auto generated. do not modify */ 
#define BMCVERSION "${VERSION}"
#define BUILDTIME "${DATE}"
EOF

if [ ! -d "build/${DATE}" ];then
  mkdir -p "build/${DATE}"
fi

echo "----- make fw -----" 
echo "Version: ${VERSION}" 
echo "Date: ${DATE}"

echo "build fw"

#- rebuild all stuff for image
( set -x
  cd buildroot
  make linux-rebuild
  make swupdate-rebuild
  make bmc-rebuild
  make V=1
)

cp -rf buildroot/output/images/buildroot_linux_nand_uart3.img ./build/${DATE}/turingpi-${VERSION}.img

( cd buildroot/output/images/
  ./genSWU.sh
)
mv -f ./buildroot/output/images/turingpi_.swu ./build/${DATE}/turingpi-${VERSION}.swu

echo "build turing pi firmware CLI"
if [ ! -f "build/tpi/linux/tpi" ];then
	mkdir -p build/tpi/linux
	gcc app/tpi/tpi.c -o build/tpi/linux/tpi
fi

