#!/bin/sh
set -e

#- init Download cache
  mkdir -p dl
  rm -rf buildroot/dl
  ln -s ../dl buildroot/dl

#- initial build
( set -x
  cd buildroot
  make BR2_EXTERNAL="../br2t113pro"  100ask_t113-pro_spinand_core_defconfig
  make V=1

  cp ../bmc4tpi/config/sun8iw20p1*  output/build/linux-5112fdd843715f1615703ca5ce2a06c1abe5f9ee/arch/arm/boot/dts/
  cp ../bmc4tpi/config/kernelconfig output/build/linux-5112fdd843715f1615703ca5ce2a06c1abe5f9ee/.config
)

#- initial build finished - seed output directories
( set -x
  cp bmc4tpi/config/swupdateconfig buildroot/output/build/swupdate-2021.11/.config
  cp bmc4tpi/swupdate/sw-description buildroot/output/images/
  cp bmc4tpi/swupdate/genSWU.sh buildroot/output/images/
  cp bmc4tpi/swupdate/env0.fex buildroot/output/images/
  cp bmc4tpi/swupdate/env1.fex buildroot/output/images/
)

