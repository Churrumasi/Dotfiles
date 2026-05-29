#!/bin/bash
set -e

### CONFIG ###
export LFS=/mnt/lfs

echo "==> Detectando partición root de LFS..."

# 1️⃣ Intentar por LABEL=LFS
ROOT_PART=$(blkid -L LFS 2>/dev/null || true)

# 2️⃣ Fallback: ext4 más grande no montada
if [ -z "$ROOT_PART" ]; then
    ROOT_PART=$(lsblk -pnlo NAME,FSTYPE,MOUNTPOINT,SIZE \
        | awk '$2=="ext4" && $3=="" {print $1,$4}' \
        | sort -hr -k2 \
        | head -n1 \
        | awk '{print $1}')
fi

if [ -z "$ROOT_PART" ]; then
    echo "❌ No se pudo detectar la partición root de LFS"
    exit 1
fi

echo "==> Partición detectada: $ROOT_PART"

echo "==> Montando root LFS"
mkdir -p $LFS
mount | grep -q " $LFS " || mount "$ROOT_PART" "$LFS"

echo "==> Montando pseudo-filesystems"
for dir in dev proc sys run; do
    mkdir -p $LFS/$dir
done

mountpoint -q $LFS/dev || mount --bind /dev $LFS/dev
mountpoint -q $LFS/dev/pts || mount -t devpts devpts $LFS/dev/pts
mountpoint -q $LFS/proc || mount -t proc proc $LFS/proc
mountpoint -q $LFS/sys  || mount -t sysfs sysfs $LFS/sys
mountpoint -q $LFS/run  || mount -t tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
    mkdir -p $LFS/$(readlink $LFS/dev/shm)
else
    mountpoint -q $LFS/dev/shm || mount -t tmpfs tmpfs $LFS/dev/shm
fi

echo "==> Entrando al chroot LFS"
chroot $LFS /usr/bin/env -i \
    HOME=/root \
    TERM="xterm" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    /bin/bash --login
