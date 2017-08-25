#!/usr/bin/env bash

echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"qt5 -qt4 X dbus jpeg lock session startup-notification udev -gnome -systemd -minimal alsa pam tcpd ssl\"" >> /etc/portage/make.conf

# Prepare for emerge
flaggie x11-misc/lightdm-gtk-greeter +branding

mkdir -p /etc/portage/package.accept_keywords/
echo "lxqt-base/*" >> /etc/portage/package.accept_keywords/lxqt
echo "media-gfx/lximage-qt" >> /etc/portage/package.accept_keywords/lxqt
echo "x11-misc/obconf-qt" >> /etc/portage/package.accept_keywords/lxqt
echo "x11-misc/pcmanfm-qt" >> /etc/portage/package.accept_keywords/lxqt

echo "* Installing LXQt Desktop Environment..."
confUpdate "lxqt-base/lxqt-meta"

echo
echo "* Display manager installation.."
confUpdate "x11-misc/lightdm"
sed -i 's/xdm/lightdm/g' /etc/conf.d/xdm
