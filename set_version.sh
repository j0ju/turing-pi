#!/bin/bash

sed -i "s/version: .*$/version: $1/" app/board/rootfs_overlay/etc/init.d/s99hello.sh
sed -i "s/version=.*$/version=\"$1\"/" mkfw.sh
sed -i "s/CONTAINER_VER=.*$/CONTAINER_VER=\"$1\"/" bmc4tpi/swupdate/genSWU.sh
