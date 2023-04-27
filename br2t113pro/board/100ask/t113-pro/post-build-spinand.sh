#!/bin/sh
BOARD_DIR="$(dirname $0)"

MOD_REMOVE=
MOD_REMOVE="$MOD_REMOVE ./fs/cifs"
MOD_REMOVE="$MOD_REMOVE ./fs/btrfs"
MOD_REMOVE="$MOD_REMOVE ./fs/fuse"
MOD_REMOVE="$MOD_REMOVE ./fs/overlayfs"
MOD_REMOVE="$MOD_REMOVE ./fs/autofs"
MOD_REMOVE="$MOD_REMOVE ./mm"
MOD_REMOVE="$MOD_REMOVE ./net"
MOD_REMOVE="$MOD_REMOVE ./drivers/net"


ROOT_DIR="$BASE_DIR/target"
MODULES_DIR="$BASE_DIR/target_modules"

rm -rf "$MODULES_DIR"
mkdir "$MODULES_DIR"

# there should only be one directory for modules (only one kernel in image)
cd "$ROOT_DIR/lib/modules"/[0-9]*/kernel
SRC_REL="${PWD#$ROOT_DIR}"

for d in $MOD_REMOVE; do
  [ -d "$d" ] || continue
  dst="$MODULES_DIR/$SRC_REL/$d"
  mkdir -p "${dst%/*}"
  mv -fv "$d" "${dst%/*}"
done

# For debug
echo "Target binary dir $BOARD_DIR"

cp $BOARD_DIR/env-spinand.cfg -rfvd  $BINARIES_DIR
cp $BOARD_DIR/boot_package.cfg -rfvd  $BINARIES_DIR
cp $BOARD_DIR/bootlogo.bmp.lzma -rfvd  $BINARIES_DIR
cp $BOARD_DIR/bootlogo.bmp -rfvd  $BINARIES_DIR
cp $BOARD_DIR/ramdisk.img -rfvd  $BINARIES_DIR

# Copy some system bins.
cp $BOARD_DIR/../pack_img/* -rfvd  $BINARIES_DIR

#Copy tina pack tools
cp $BOARD_DIR/../tina-pack-tools/* -rfvd  $BINARIES_DIR

#cd buildroot/output/images/
cd $BINARIES_DIR

#build env.fex bootargs.
mkenvimage -r -p 0x00 -s 0x20000 -o env.fex env-spinand.cfg

#build uboot optee files.
$BINARIES_DIR/dragonsecboot  -pack boot_package.cfg

#buildroot kernel boot images.
mkbootimg --kernel zImage  --ramdisk  ramdisk.img --board sun8iw20p1 --base  0x40200000 --kernel_offset  0x0 --ramdisk_offset  0x01000000 -o  boot.img
