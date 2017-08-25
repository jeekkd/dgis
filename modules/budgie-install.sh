#!/usr/bin/env bash

echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"X jpeg lock session startup-notification -minimal alsa pam tcpd ssl\"" >> /etc/portage/make.conf

# Prepare for emerge
flaggie x11-misc/lightdm-gtk-greeter +branding
flaggie gnome-base/gvfs +udisks
flaggie net-print/cups -dbus
emerge --deselect sys-fs/udev

confUpdate "app-portage/layman"
layman -S
yes Y | layman -a sabayon

echo "* Installing Budgie Desktop Environment..."
confUpdate "gnome-extra/budgie-desktop"

echo
echo "* Display manager installation.."
confUpdate "x11-misc/lightdm"
sed -i 's/xdm/lightdm/g' /etc/conf.d/xdm
