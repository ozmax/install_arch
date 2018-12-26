#!/bin/sh

# set ntp
timedatectl set-ntp true

# partition the /dev/sda
parted /dev/sda mklabel gpt
# make uefi system partion
parted /dev/sda mkpart primary fat32 1MiB 551MiB
parted /dev/sda set 1 esp on
# make swap partition
parted /dev/sda mkpart primary linux-swap 551MiB 1551MiB
# make / partition
parted /dev/sda mkpart primary ext4 1551MiB 100%

# format the partitions
# format the esp
mkfs.fat -F32 /dev/sda1
# format the swap partition
mkswap /dev/sda2
swapon /dev/sda2
# format the / partition
mkfs.ext4 /dev/sda3

# mount partitions
mount /dev/sda3 /mnt

mkdir /mnt/efi
mount /dev/sda1 /mnt/efi

# set up greek mirrorlist
curl 'https://www.archlinux.org/mirrorlist/?country=GR&protocol=https' \
    | sed -e 's/#Server/Server/g' \
    > /etc/pacman.d/mirrorlist

# install base packages
pacstrap /mnt base

genfstab -L /mnt >> /mnt/etc/fstab

# cp chroot commands inside /mnt
cp chroot_commands.sh /mnt

# run chroot commands
arch-chroot /mnt /chroot_commands.sh
