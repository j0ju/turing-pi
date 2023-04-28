#!/bin/sh
#- defaults
  set -e
  BOARD_DIR="$(dirname $0)"

#- modules to move aside, we have limited space, for external add
  MOD_REMOVE=
  MOD_REMOVE="$MOD_REMOVE ./fs/ext2 ./fs/ext4 ./fs/jbd ./fs/jbd2 ./fs/mbcache.ko"
  MOD_REMOVE="$MOD_REMOVE ./fs/cifs ./fs/btrfs ./fs/fuse ./fs/overlayfs ./fs/autofs ./fs/isofs"
  MOD_REMOVE="$MOD_REMOVE ./fs/cachefiles ./fs/fscache"
  MOD_REMOVE="$MOD_REMOVE ./drivers/net/slip ./drivers/net/dummy.ko ./drivers/net/eql.ko ./drivers/net/geneve.ko ./drivers/net/macsec.ko ./drivers/net/macvlan.ko ./drivers/net/macvtap.ko ./drivers/net/nlmon.ko ./drivers/net/ipvlan"
  MOD_REMOVE="$MOD_REMOVE ./drivers/soc"
  MOD_REMOVE="$MOD_REMOVE ./drivers/block/nbd.ko"
  MOD_REMOVE="$MOD_REMOVE ./net/netfilter ./net/bridge/netfilter ./net/bridge/br_netfilter.ko ./net/bridge/bpfilter ./net/ipv4/netfilter ./net/ipv6/netfilter"
  MOD_REMOVE="$MOD_REMOVE ./net/core"
  MOD_REMOVE="$MOD_REMOVE ./net/llc"

  ROOT_DIR="$BASE_DIR/target"
  MODULES_DIR="$BASE_DIR/target_modules"

  mkdir -p "$MODULES_DIR"

  # there should only be one directory for modules (only one kernel in image)
  cd "$ROOT_DIR/lib/modules"/[0-9]*/kernel
  SRC_REL="${PWD#$ROOT_DIR}"

  for d in $MOD_REMOVE; do
    [ -d "$d" ] || continue
    dst="$MODULES_DIR/$SRC_REL/$d"
    rm -rf "${dst%/*}/${d##*/}"
    mkdir -p "${dst%/*}"
    mv -fv "$d" "${dst%/*}"
  done


#- init re-work
  mkdir -p "$ROOT_DIR/etc/rc.d"

  for f in "$ROOT_DIR/etc/init.d"/rc[SK]; do
    sed -i -e 's|/etc/init.d|/etc/rc.d|g' "$f"
  done

  for f in "$ROOT_DIR/etc/init.d"/[SK][0-9][0-9]*; do
    fname="${f##*/}"
    svc="${fname#???}"
    rcf="$ROOT_DIR/etc/init.d/$svc"
    mv "$f" "$rcf"
    fname="$ROOT_DIR/etc/rc.d/$fname"
    ln -sf "../init.d/$svc" "$fname"
  done

  SRC="$ROOT_DIR/etc/init.d"
  TARGET="$ROOT_DIR/usr/local/sbin"
  mkdir -p "$ROOT_DIR/usr/local/sbin"
  for initfile in "$SRC"/*; do
    file="${initfile##*/}"
    rcfile="${TARGET}/rc${file}"

    if [ -x "$initfile" -a ! -d "$initfile" ]; then
      ln -sf "${initfile#$ROOT_DIR}" "$rcfile" && echo Ok. || echo "failed."
    fi
  done

#- move root's home to /tmp, to lower writes to flash
  sed -i -e '/^root/ s|/root|/tmp|' "$ROOT_DIR/etc/passwd"


#- remove all .keep/.git files files from empty directories and git repos
  find "$ROOT_DIR" -name .keep -exec rm -rf {} +
  find "$ROOT_DIR" -name .git -exec rm -rf {} +


#- original
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
  mkbootimg --kernel zImage  --ramdisk  ramdisk.img --board sun8iw20p1 --base  0x40200000 --kernel_offset  0x0 --ramdisk_offset  0x01000000 -o boot.img
