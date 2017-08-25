#!/usr/bin/env bash

firstUser=$(grep "1000" /etc/passwd | cut -f 1 -d :)

isInstalled "dev-vcs/git"

cp configs/dantrell-gnome*.conf /etc/portage/repos.conf/
if [ -f /etc/portage/repos.conf/dantrell-gnome.conf ]; then
	emaint sync -a
else
	echo "Error: the file dantrell-gnome.conf does not exist at /etc/portage/repos.conf/"
	exit  1
fi

# Profile selection menu
selectProfile

# Prepare for emerge
flaggie media-libs/mesa +gles2
flaggie sys-apps/busybox -static
flaggie media-plugins/alsa-plugins +pulseaudio
flaggie x11-base/xorg-server +glamor
flaggie x11-libs/libdrm +video_cards_amdgpu
flaggie gnome-base/gvfs +udisks
flaggie net-print/cups -dbus
emerge --deselect sys-fs/udev
echo -e "# required for GNOME\n>=media-plugins/grilo-plugins-0.2.13 upnp-av" >> /etc/portage/package.use/grilo-plugins
echo -e "# required for GNOME\n>=www-servers/apache-2.2.31 apache2_mpms_prefork" >> /etc/portage/package.use/apache
echo -e "# required for GNOME\n>=net-fs/samba-4.2.14 client" >> /etc/portage/package.use/samba
echo -e "# required for GNOME\n>=sys-libs/ntdb-1.0-r1 python" >> /etc/portage/package.use/ntdb
echo -e "# required for GNOME\n>=sys-libs/tdb-1.3.8 python" >> /etc/portage/package.use/tdb
echo -e "# required for GNOME\n>=sys-libs/tevent-0.9.28 python" >> /etc/portage/package.use/tevent

printf "\n"
echo "* Setting global USE flags in make.conf"
echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"X -gt4 -qt5 -kde jpeg lock session startup-notification gnome networkmanager -minimal alsa pam tcpd ssl\"" >> /etc/portage/make.conf
env-update && source /etc/profile && export PS1="(chroot) $PS1" 

printf "\n"
echo "* Installing Gnome desktop environment.."
confUpdate "--deep --with-bdeps=y --changed-use --update -q @world"
confUpdate "media-sound/alsa-utils"
confUpdate "gnome-base/gnome"

printf "\n"
printf "* Changing default display manager to GDM \n"
sed -i 's/xdm/gdm/g' /etc/conf.d/xdm

printf "\n"
printf "* Adding startup items to OpenRC for boot.. \n"
rc-update add acpid default
rc-update add NetworkManager default
rc-update add alsasound boot
rc-update del dhcpcd default

usermod -aG plugdev "$firstUser"
