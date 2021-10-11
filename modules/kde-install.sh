#!/usr/bin/env bash

echo "* Setting global USE flags in make.conf"
echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"qt5 -qt4 X dbus jpeg lock session startup-notification udev -gnome -systemd -minimal alsa pam tcpd ssl\"" >> /etc/portage/make.conf

emerge --deep --with-bdeps=y --changed-use --update -q @world

# Prepare for emerge
flaggie net-libs/libvncserver +ssl
flaggie net-libs/libvncserver +threads
flaggie app-text/poppler +qt4

echo "* Installing KDE desktop environment and extras"
confUpdate "kde-plasma/plasma-meta kde-plasma/kdeplasma-addons kde-apps/kde-apps-meta kde-plasma/kwallet-pam"

echo "* Changing default display manager to SDDM"
sed -i 's/xdm/sddm/g' /etc/conf.d/xdm
