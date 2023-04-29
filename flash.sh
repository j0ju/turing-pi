#!/bin/sh

# flash BMC via SSH
#  * only rootfs, no kernel
usage() {
cat >&2 <<EOF

${0##*/} [IMAGE] [HOSTSPEC]

  * IMAGE must be a readable file
  * HOSTSPEC can be either just a host or USER@HOST

EOF
}


IMAGE="$1"
if ! [ -r "$IMAGE" ]; then
  echo "E: IMAGE '$1' does not exist or is empty." >&2
  usage
  exit 1
fi

HOST="$2"
if [ -z "$HOST" ]; then
  echo "E: HOST not given." >&2
  usage
  exit 1
fi

ssh "$HOST" < "$IMAGE" '
  set -e
  set -x

  ROOTDEV="$(awk "\$2 == \""/\"" {print \$1}" /proc/mounts)"
  case "$ROOTDEV" in
    ubi0_5 ) 
      SWUPDATE_TARGET=upgrade_ubi6
      UBOOT_TARGET=ubi0_6
      ;;
    ubi0_6 )
      SWUPDATE_TARGET=upgrade_ubi5
      UBOOT_TARGET=ubi0_5
      ;;
    * ) 
      echo "E: /dev/$ROOTDEV cannot be updated this way." >&2 
      exit 1
      ;;
  esac

  # transfer the firmware file
  trap "rm -f \"\$TMPFW\"" EXIT TERM KILL USR1 USR2 HUP QUIT INT
  TMPFW="$(mktemp)"
  cat > "$TMPFW"

  # prevent writes on that device
  mount -o remount,ro /
  echo s > /proc/sysrq-trigger
  echo u > /proc/sysrq-trigger

  cd /tmp
  swupdate -i "$TMPFW" -e stable,$SWUPDATE_TARGET
  fw_setenv nand_root $UBOOT_TARGET
  reboot
'
