#!/usr/bin/env bash

echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"-X -gtk -kde -gnome -minimal hardened\"" >> /etc/portage/make.conf

# Assure the sensible network adapter naming scheme is used
sed -i 's/#GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="net.ifnames=0"/' /etc/default/grub

# Ask, and set static addressing if the user wants it
askStaticAddress

# Enable services
rc-update add sshd default
