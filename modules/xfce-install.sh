#!/usr/bin/env bash

echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"X gtk -kde -minimal dbus jpeg lock hardened session startup-notification thunar udev -systemd -gnome alsa bindist infinality\"" >> /etc/portage/make.conf
flaggie gnome-base/gvfs +udisks
flaggie sys-auth/consolekit +policykit
echo
echo "* Desktop environment installation.."
confUpdate "xfce-base/xfce4-meta xfce-base/thunar xfce-extra/thunar-archive-plugin xfce-extra/thunar-vcs-plugin xfce-extra/thunar-volman xfce-extra/xfce4-power-manager xfce-extra/xfce4-mount-plugin xfce-extra/xfce4-screenshooter xfce-extra/xfce4-gvfs-mount xfce-extra/xfce4-whiskermenu-plugin xfce-extra/xfce4-battery-plugin xfce-extra/xfce4-mixer"

if [[ $installTheme == "Y" ]] || [[ $installTheme == "y" ]]; then
	echo
	echo "* Installing Vertex-theme and paper-icon-theme..."

	confUpdate "x11-themes/gtk-engines-murrine"

	# Vertex Theme by horst3180
	# https://github.com/horst3180/Vertex-theme
	git clone https://github.com/horst3180/vertex-theme --depth 1 && cd vertex-theme || exit
	./autogen.sh --prefix=/usr --disable-cinnamon --disable-gnome-shell --disable-unity
	make install
	cd ..

	# Paper-icon-theme by snwh
	# https://github.com/snwh/paper-icon-theme
	git clone https://github.com/snwh/paper-icon-theme && cd paper-icon-theme || exit
	./autogen.sh
	make -s
	make install
fi

# Install display manager
if [[ $installLightDM == "Y" ]] || [[ $installLightDM == "y" ]]; then
	echo
	echo "* Display manager installation.."
	confUpdate "x11-misc/lightdm"
	sed -i 's/xdm/lightdm/g' /etc/conf.d/xdm
fi

# Install applications
if [[ $installApplications == "Y" ]] || [[ $installApplications == "y" ]]; then
	echo
	echo "* Beginning to emerge default program set.."

	confUpdate "app-misc/tmux app-editors/vim app-admin/keepassx media-gfx/nomacs sys-block/gparted app-text/evince net-misc/networkmanager-openvpn sys-apps/mlocate net-dialup/minicom app-arch/p7zip"

	flaggie sys-power/suspend +crypt
	flaggie sys-block/gparted +ntfs
	flaggie sys-block/gparted +fat
	flaggie sys-block/gparted +policykit
	flaggie app-text/poppler +cairo

	confUpdate "sys-power/suspend net-irc/hexchat app-arch/file-roller net-p2p/transmission sci-calculators/galculator media-video/gnome-mplayer dev-util/geany x11-terms/guake"

	flaggie net-misc/networkmanager -modemmanager
	flaggie www-client/firefox +bindist
	flaggie www-client/firefox -dbus
	flaggie www-client/firefox +hardened
	flaggie media-libs/libpng +apng

	confUpdate "www-client/firefox net-misc/vinagre app-shells/bash-completion net-misc/networkmanager net-misc/networkmanager-openvpn x11-terms/xfce4-terminal"
	echo
	echo "* Enabling global bash completion.."
	eselect bashcomp enable --global {0..478}
fi

echo
echo "* Adding programs to OpenRC for boot.."
rc-update add iptables default
rc-update add ip6tables default
