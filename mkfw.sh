#!/bin/sh
set -e

INIT_FLAG=./buildroot/output/.mkfw.init
CLEAN="${CLEAN:-no}"

DATE="$(date +%F)"
VERSION="${1:-}"
if [ -z "${VERSION}" ]; then
  echo "I: no version given as first parameter, auto generating version."
  # compose build version
  # YYYY-MM-DD-GITREV-DIRTYFLAG
  # GITREV is either a short commit hash or tag if tagged

  if git status -s | grep ^ > /dev/null; then
    # dirty check
    VERSION="$(date +%F)-$(git rev-parse --abbrev-ref HEAD 2> /dev/null)-$(git rev-parse --short HEAD 2> /dev/null)+dirty"
    INC=0
    while [ -f ./build/${DATE}/turingpi-${VERSION}~$INC.img ]; do
      INC=$(( INC + 1 ))
    done
    VERSION="$VERSION~$INC"
  else
    VERSION="$(date +%F)-$(git rev-parse --abbrev-ref HEAD 2> /dev/null)-$(git rev-parse --short HEAD 2> /dev/null)"
  fi
fi
echo "I: Using version $VERSION for this build."

cat > app/bmc/version.h <<EOF
/* This file is auto generated. do not modify */
#define BMCVERSION "${VERSION}"
#define BUILDTIME "${DATE}"
EOF

if [ "${CLEAN}" = yes ]; then
  ( cd buildroot
    make distclean
  )
fi

if [ ! -f "$INIT_FLAG" ]; then
  . ./init.sh
  : > "$INIT_FLAG"
fi

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

find "build/$DATE" -type f -exec ls -lt {} + |  grep -E --color '[^ ]+(.swu|.img)$'

