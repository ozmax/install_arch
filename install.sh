#!/bin/sh

# set ntp
timedatectl set-ntp true

# partition the /dev/sdb
parted -s /dev/sdb mklabel msdos
parted -s /dev/sdb mkpart primary ext4 1MiB 99%
parted -s /dev/sdb set 1 boot on
# make swap partition
parted -s /dev/sdb mkpart primary linux-swap 99% 100%

# format the partitions
mkfs.ext4 /dev/sdb1
mkswap /dev/sdb2
swapon /dev/sdb2

# mount partitions
mount /dev/sdb1 /mnt

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

# setup network
cp /etc/netctl/examples/ethernet-dhcp /etc/netctl/eth_config

# set up bootloader
pacman --noconfirm -S syslinux
syslinux-install_update -iam


# exit chroot
EOS

cat << 'EOS'
Things to set:
    * root password
    * hostname
    * update interface in netctl config file
EOS
