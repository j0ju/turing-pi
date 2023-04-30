## Install the necessary dependent packages

On Ubuntu or Debian-alikes you can install needed packages:

```
sudo apt-get install build-essential subversion git-core libncurses5-dev zlib1g-dev gawk flex quilt libssl-dev xsltproc libxml-parser-perl mercurial bzr ecj cvs unzip lib32z1 lib32z1-dev lib32stdc++6 libstdc++6 libncurses-dev u-boot-tools mkbootimg -y
```

## Features

 * random stable MAC address as long only `.swu` files are flashed
 * tpi tool is able 
 * adb and most of the image works on a to read-only filesystem eg. on full flash, besides ssh, eg.
   the webinterface and flashin via web interface, and adb for LiveSuit
 * Kernel is updated in case of `.img` flashes extending the kernel with some features for playing around.

## Build

This script builds the buildroot image and adds the tiny bits from the 
original documentation at https://github.com/wenyi0421/turing-pi and 
TinaLinux for the Allwinn T113-S3 CPU to build an image to flash.

The BMC displays a version number via WebInterface or API. Currently you have 
to specify as version string. e.g build you own images based with own version
scheme.

The output of this process is stored in `./build/<CURRENT DATE yyyy-mm-dd>/`.
The files built are:
 * `turingpi-<VERSION>.swu`, this file only contains the root file system for
   update via the webinterface.
   (see https://help.turingpi.com/hc/en-us/articles/8686945524893-Baseboard-Management-Controller-BMC-#f4364f3c)
 * `turingpi-<VERSION>.img`, this file is an full flash image to be flashed 
    via LiveSuit.
    (see https://help.turingpi.com/hc/en-us/articles/8686945524893-Baseboard-Management-Controller-BMC-#fcaef23)

```
sh mkfw.sh <VERSION>
```

VERSION is optional, currently it genereates a version number out the date and git informations.
 * if you are on a clean repository, the auto version string will be DATE-GITREV-GITHASH, where GITREV is either tag or branch
 * is the repository dirty on call of `mkfs.sh` the versioning scheme is DATE-GITREV-GITHASH+dirty~BUILDNUM, where GITREV is a branch

### Notes

 * Persisten Random MAC address is store in UBoot in this image. As long you only do
   upgrades via the BMC web interface, the MAC address is retained.

 * Limited sizes, Flash partitioning: We currently only have 32MB, root file system is in
   an UBI container `ubi0_5` and `ubi0_6`. The latter is the recovery 
   partition, which has some megabyte less space available.
   If the root filesystem is to big, because eg. to many more packages 
   have been added, then either the build process fails, the the image does
   not boot or flashing via BMC web interface might not be able to flash 
   images anymore.
   If the root filesystem is too large the recovery partition might not be
   created in the .img file.

 * The kernel will only be updated by flashing the `.img`.
 
### Adding own stuff

After doing an initial build via `mkfw.sh`, you can add more packages.
Change into the `buildroot` directory.

 * `make menuconfig` - Add and remove packages
 * `make linux-menuconfig` - Change kernel or module config

### Flash via SSH

 `flash.sh` allows to flash the `.swu` via SSH.

 Usage:
 > `flash.sh IMAGE HOSTSPEC`

 Where IMAGE is the PATH to an image file and HOSTSPEC is a SSH compatible string to login to the BMC, like root@turing.example.com.


## Troubleshooting

 * Serial Console: if you cannot enter the serial console of UBoot although
   a bootdelay>0 is configured flash the `.img` once.
 * Brick/UBoot: if you flashed an image the does not boot anymore, so that
   upgrades via BMC or flashing the `.img` are not possible anymore. You can
   try to enter UBoot via connected serial console.
   The UBoot contains an command to enter the `Android Upgrade Mode` for flashing
   via PhoenixSuit or LiveSuit. The command is `efex`.

