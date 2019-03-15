#!/bin/sh

# set ntp
timedatectl set-ntp true

# partition the /dev/sda
parted -s /dev/sda mklabel gpt
# make uefi system partion
parted -s /dev/sda mkpart primary fat32 1MiB 551MiB
parted -s /dev/sda set 1 esp on
# make swap partition
parted -s /dev/sda mkpart primary linux-swap 551MiB 1551MiB
# make / partition
parted -s /dev/sda mkpart primary ext4 1551MiB 100%

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

mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

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

# set temporarily root password to "pass"
printf "pass\npass" | passwd

# exit chroot
EOS
