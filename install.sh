#!/bin/sh

# set ntp
timedatectl set-ntp true

# select the block device with the lowest storage
TARGET_DISK="/dev/""$(lsblk -nb -o KNAME,TYPE,SIZE|grep disk|sorn -n -k3|head -n1|grep -o '^\w*\w')"

# partition the /dev/sdb
parted -s "$TARGET_DISK" mklabel gpt
# make uefi system partion
parted -s "$TARGET_DISK" mkpart primary fat32 1MiB 551MiB
parted -s "$TARGET_DISK" set 1 esp on
# make swap partition
parted -s "$TARGET_DISK" mkpart primary linux-swap 551MiB 1551MiB
# make / partition
parted -s "$TARGET_DISK" mkpart primary ext4 1551MiB 100%

# format the partitions
# format the esp
mkfs.fat -F32 "$TARGET_DISK"1
# format the swap partition
mkswap "$TARGET_DISK"2
swapon "$TARGET_DISK"2
# format the / partition
mkfs.ext4 "$TARGET_DISK"3

# mount partitions
mount "$TARGET_DISK"3 /mnt

mkdir /mnt/boot
mount "$TARGET_DISK"1 /mnt/boot

# set up greek mirrorlist
curl 'https://www.archlinux.org/mirrorlist/?country=GR&protocol=https' \
    | sed -e 's/#Server/Server/g' \
    > /etc/pacman.d/mirrorlist

# install base packages
pacstrap /mnt base

genfstab -L /mnt >> /mnt/etc/fstab

# chroot into new installation and configure new system
arch-chroot /mnt /bin/sh << 'EOS'

# set timezone
ln -sf /usr/share/zoneinfo/Europe/Athens /etc/localtime

# set locale
sed -i 's/^#\(en_US.UTF-8.*\)/\1/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8

hwclock --systohc

# setup uefi boot with bootctl
bootctl --path=/boot/ install

# create bootctl script
printf "\
title Arch Linux\n\
linux /vmlinuz-linux\n\
initrd /initramfs-linux.img\n\
options root=PARTUUID="$(blkid -o value -s PARTUUID /dev/sda3)" rw\n\
" > /boot/loader/entries/arch.conf

# setup network
cp /etc/netctl/examples/ethernet-dhcp /etc/netctl/eth_config
netctl enable eth_config

# exit chroot
EOS

cat << 'EOS'
Things to set:
    * root password
    * hostname
EOS
