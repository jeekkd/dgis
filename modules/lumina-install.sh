#!/usr/bin/env bash

echo "* Setting global USE flags in make.conf"
echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"X dbus jpeg lock session startup-notification udev -gnome -systemd -minimal alsa pam tcpd ssl\"" >> /etc/portage/make.conf

emerge --deep --with-bdeps=y --changed-use --update -q @world

# Prepare for emerge
flaggie x11-misc/lightdm +qt5

echo "* Installing Lumina desktop environment"
confUpdate "x11-wm/lumina"

echo
echo "* Display manager installation.."
confUpdate "x11-misc/lightdm"

cp "$script_dir"/configs/xdm /etc/conf.d/
chown root:root /etc/conf.d/xdm
chmod 644 /etc/conf.d/xdm
sed -i 's/xdm/lightdm/g' /etc/conf.d/xdm

emerge --deep --with-bdeps=y --changed-use --update -q @world
