#!/usr/bin/env bash
# Written by: https://github.com/jeekkd
# Website: https://daulton.ca
# 
# This is a script to install Gentoo in a partially interactive manner, it gives a baseline install 
# configured with Xorg, a display manager, a supported desktop environment or window manager, 
# etc. while giving the flexability to be set your own values for locale, timezone, usernames, 
# passwords, hostname, etc.
#
# The intended use is that first your partitioning is done as you wish, you run the script and it handles
# everything up the point of configuring the fstab or any additional options your grub configuration may
# require. This is intended as both partitioning and /etc/fstab have a lot of choice and potential for 
# custom configuration and a one size fits all solution does not work for all.
#
# Procedure:
# 1. Mount root on /mnt/gentoo
# 2. cd to /mnt/gentoo
# 3. untar your stage3 of choice as you normally would
# 4. Clone the repo to get the source
# 5. Create and enter a chroot at /mnt/gentoo
# 6. Edit the /etc/fstab with your partitions
# 7. Run the script

################## VARIABLES ##################
# Default nameserver to set in resolv.conf
nameServer="8.8.8.8"

# Default timezone
timezone="Canada/Central"
###############################################

# get_script_dir()
# Gets the directory the script is being ran from. To be used with the import() function
# so the configuration is imported from its absolute path
get_script_dir() {
	script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
}

# Leave here to get scripts running location
get_script_dir

control_c() {
	echo "Control-c pressed - exiting NOW"
	exit $?
}

trap control_c SIGINT

# import()
# Important module(s) for the purpose of modularizing the script. Usage is simply
# import <name of module>, do not add the file extension.
import() {
  module=$1
  . "$script_dir"/modules/${module}.sh
}

# confUpdate()
# if a configuration file needs to be updated during an emerge it will update it then retry the emerge
confUpdate() {
	emerge --autounmask-write -q $1
	if [ $? -eq 1 ]; then
		etc-update --automode -5
		emerge --autounmask-write -q $1
	fi
	env-update && source /etc/profile && export PS1="(chroot) $PS1"	
}

# isInstalled
# If given a valid package atom it will check if the package is installed on the local system
# Example: isInstalled "sys-kernel/genkernel-next" 
# If the package is not installed it will call confUpdate and install the package
isInstalled() {
	package=$1
    packageTest=$(equery -q list "$package")
    if [[ -z ${packageTest} ]]; then
		confUpdate "$package"
    fi
}

echo "Install Xorg? Y/N"
read -r installXorg
if [[ $installXorg == "Y" ]] || [[ $installXorg == "y" ]]; then	
	echo
	while true ; do
		echo
		echo "----------------------------------"
		echo "Desktop Environment Selection menu"
		echo "----------------------------------"
		echo
		echo "A. Xfce"
		echo "B. KDE"
		echo "C. Skip this selection"
		echo
		echo -n "Enter a selection: "
		read -r option
			
		case "$option" in
				
		[Aa])
			installDesktop=1
			echo "Xfce has been selected for the desktop environment"
			break
		;;
		[Bb])
			installDesktop=2
			echo "KDE has been selected for the desktop environment"
			break
		;;
		[Cc])
			echo "Skipping desktop environment selection.."
			break
		;;
		*)
			echo "Enter a valid selection from the menu - options include A to C"
		;;	
		esac 	
    done
	
	if [[ $installDesktop == "1" ]]; then
        echo
        echo "Install lightdm display manager? Y/N"
        read -r installLightDM
        echo
		echo "Install Vertex and Paper Icons theme? Y/N"
		read -r installTheme
		echo
		echo "Install default set of applications? Y/N"
		read -r installApplications	
	fi
fi

# Set DNS server
echo
echo "Would you like to use the default nameserver (1) or enter one (2)?"
read -r answer
if [[ $answer == "1" ]]; then
	echo "nameserver $nameServer" > /etc/resolv.conf
	if [ $? -eq 0 ]; then
		echo "Success: Set nameserver to $nameServer"
	else
		echo "Error: Failed to set nameserver to $nameServer"
		exit 1
	fi	
elif [[ $answer == "2" ]]; then
	echo "Enter a nameserver in dotted decimal format such as 0.0.0.0"
	read -r answer
	echo "nameserver $answer" > /etc/resolv.conf
	if [ $? -gt 0 ]; then
		echo "Error: Failed to set nameserver to $answer.."
		exit 1
	fi
else
	echo "Error: Enter either the number 1 or 2 as your selection."
fi

# Configuring system basics
mkdir -p /etc/portage/repos.conf/

if [ ! -f /etc/portage/repos.conf/gentoo.conf ]; then
	echo "[gentoo]" >> /etc/portage/repos.conf/gentoo.conf
	echo "location = /usr/portage" >> /etc/portage/repos.conf/gentoo.conf
	echo "sync-type = rsync" >> /etc/portage/repos.conf/gentoo.conf
	echo "sync-uri = rsync://rsync.gentoo.org/gentoo-portage" >> /etc/portage/repos.conf/gentoo.conf
	echo "auto-sync = yes" >> /etc/portage/repos.conf/gentoo.conf
fi

if [ -f /etc/portage/repos.conf/gentoo.conf ]; then
	chmod 644 /etc/portage/repos.conf/gentoo.conf
else
	echo "Error: gentoo.conf does not exist in /etc/portage/repos.conf/ - exiting"
	exit 1
fi

# Adding make.conf at /etc/portage
cp make.conf /etc/portage/
if [ -f /etc/portage/make.conf ]; then
	chmod 644 /etc/portage/make.conf
	detectCores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1)
	echo " " >> /etc/portage/make.conf
	echo "# Make concurrency level for emerges" >> /etc/portage/make.conf
	MAKEOPTS="-j$detectCores" >> /etc/portage/make.conf
	env-update && source /etc/profile && export PS1="(chroot) $PS1" 
else
	echo "Error: make.conf does not exist in /etc/portage/ - exiting"
	exit 1
fi

# Updating portage tree with webrsync
echo
echo "* Syncing then emerging portage.."
emerge --sync
if [ $? -eq 0 ]; then
	emerge --oneshot -q sys-apps/portage
else
	echo "Error: emerge sync failed - exiting"
	exit 1
fi

# Profile selection
echo
echo "* Listing profiles..."
eselect profile list
echo
echo "Which profile would you like? Type a number: "
read -r inputNumber
eselect profile set "$inputNumber"
env-update && source /etc/profile && export PS1="(chroot) $PS1" 

# Updating world
echo
echo "* Updating world.."
confUpdate " --deep --with-bdeps=y --newuse --update @world"

echo "* Setting CPU flags in /etc/portage/make.conf"
emerge --oneshot -q app-portage/cpuid2cpuflags
flags=$(cpuinfo2cpuflags-x86)
echo " " >> /etc/portage/make.conf
echo "# Supported CPU flags" >> /etc/portage/make.conf
echo "$flags" >> /etc/portage/make.conf

# Getting time zone data 
echo "Would you like to use the default Canada/Central timezone (1) or enter your own (2)?"
read -r answer
if [[ $answer == "1" ]]; then
	echo "Canada/Central" > /etc/timezone
elif [[ $answer == "2" ]]; then
	echo "Reference the Gentoo wiki for help - https://wiki.gentoo.org/wiki/System_time#OpenRC"
	echo "Enter a timezone: "
	read -r answer
	echo "$answer" > /etc/timezone
else
	echo "Error: Enter either the number 1 or 2 as your selection."
fi
emerge -v --config sys-libs/timezone-data 

# Getting system basics
echo
echo "* Emerging git, flaggie, dhcpcd..."
confUpdate "dev-vcs/git app-portage/flaggie net-misc/dhcpcd"

# Setting computer hostname
echo
echo "* Setting hostname..."
nano -w /etc/conf.d/hostname

# Setting the root password
echo
echo "* Enter a password for the root account: "
passwd root 

# Creating the user account and setting its password
echo
echo "* Enter a username for your user: "
read -r inputUser
useradd -m -G users,usb,video,portage,audio -s /bin/bash "$inputUser"
echo
echo "* Enter a password for $inputUser"
passwd "$inputUser"

# Locale configuration
echo
echo "* Locale selection.."
nano -w /etc/locale.gen 
locale-gen 
localeUtf=$(eselect locale list | awk '/utf8/{print $1}' | sed 's/.*\[//;s/\].*//;')
localeC=$(eselect locale list | awk '/C/{print $1}' | sed 's/.*\[//;s/\].*//;')
if [[ $localeUtf -ge 1 && $localeUtf -le 9 ]]; then	
	eselect locale set "$localeUtf"
else
	eselect locale set "$localeC"
	if [ $? -gt 0 ]; then	
		eselect locale set 1
	fi
fi 
env-update && source /etc/profile && export PS1="(chroot) $PS1" 

# Setting keymaps
echo
echo "* Do you need to edit keymaps? Default is en-US. Select Y/N"
read -r answer
if [[ $answer == "Y" || $answer == "y" ]]; then
	nano -w /etc/conf.d/keymaps
fi

# Hardware clock configuration
echo
echo "* Hardware clock configuration.."
nano -w /etc/conf.d/hwclock

# Installing Xorg
if [[ $installXorg == "Y" ]] || [[ $installXorg == "y" ]]; then	
	echo "# Video and input devices for Xorg"
	echo "VIDEO_CARDS=\"radeon radeonsi nouveau intel\"" >> /etc/portage/make.conf
	echo "INPUT_DEVICES=\"keyboard mouse synaptics evdev\"" >> /etc/portage/make.conf
	env-update && source /etc/profile && export PS1="(chroot) $PS1" 
	echo
	echo "* Xorg installation.."
	confUpdate "x11-base/xorg-drivers x11-drivers/xf86-video-fbdev x11-drivers/xf86-video-vesa"
fi

# Installing desktop environment or window manager selection
if [[ $installDesktop == "1" ]]; then
	import xfce-install
fi

if [[ $installDesktop == "2" ]]; then
	import kde-install
fi

# Install and build kernel
echo
echo "* Cloning repo for my gentoo_kernel_build script to build the kernel"
echo
git clone https://github.com/jeekkd/gentoo-kernel-build.git && cd gentoo-kernel-build
if [ $? -eq 0 ]; then	
	chmod 770 build_kernel.sh
	bash build_kernel.sh
	if [ $? -gt 0 ]; then	
		echo "Error: build_kernel.sh failed - exiting"
		exit 1
	else
		cd ..
	fi
else
	echo "Error: git clone failed for retrieving kernel build script"
	exit 1
fi

echo "* Beginning to emerge helpful and necessary programs such as hwinfo and usbutils..."
flaggie app-admin/logrotate +acl
flaggie app-admin/logrotate +cron

confUpdate "sys-process/fcron app-admin/logrotate sys-apps/hwinfo app-admin/sudo app-admin/rsyslog net-firewall/iptables app-portage/gentoolkit sys-apps/usbutils"
if [ $? -gt 0 ]; then	
    # Put created user in cron group now that fcron is installed
    usermod -aG cron "$inputUser"
    usermod -aG cron root
fi
    
echo
echo "* Adding programs to OpenRC for boot.."
rc-update add consolekit default
rc-update add xdm default
rc-update add dbus default
rc-update add dhcpcd default
rc-update add rsyslog default
rc-update add fcron default

echo
echo "* Would you like to install linux-firmware? Y/N"
echo "Some devices require additional firmware to be installed on the system before they work. This is often 
the case for network interfaces, especially wireless network interfaces"
read -r answer
if [[ $answer == "Y" || $answer == "y" ]]; then
	confUpdate "sys-kernel/linux-firmware"
fi

echo "* Install and configure GRUB? Y/N"
read -r answer
if [[ $answer == "Y" || $answer == "y" ]]; then
	isInstalled "sys-boot/grub:2"
	isInstalled "sys-boot/os-prober"
	lsblk
	echo
	echo "Which disk would you like to install grub onto? Ex: /dev/sda"
	read -r whichDisk
	
	echo
	echo "Is this a regular mbr install (press 1) or efi (press 2)?"
	read -r answer
	if [[ $answer == "1" ]]; then
		grub-install "$whichDisk"
	elif [[ $answer == "2" ]]; then
		grub-install --target=x86_64-efi
	else
		echo "Error: Enter a number that is either 1 or 2"
	fi

	# Sometimes grub saves new config with .new extension so this is assuring that an existing config is removed
	# and the new one is renamed after installation so it can be used properly		
	if [ -f /boot/grub/grub.cfg ]; then
		rm -f /boot/grub/grub.cfg
	fi
	
	grub-mkconfig -o /boot/grub/grub.cfg
	if [ $? -eq 0 ]; then
		if [ -f /boot/grub/grub.cfg.new ]; then
			mv /boot/grub/grub.cfg.new /boot/grub/grub.cfg
		fi 
	fi
fi

# Clean up
if [[ $installDesktop == "1" ]]; then
	cd ..
	echo
	echo "* Cleaning up folders for downloaded themes.."
	rm -rf vertex-theme paper-icon-theme
fi

echo
echo "* Cleaning up stage3 install tar.."
rm /stage3-*.tar.bz2*

echo
echo "Would you be interested in my restricted-iptables script as well? Y/N"
echo "It is a configurable iptables firewall script meant to make firewalls easier"
echo "Reference the repo at: https://github.com/jeekkd/restricted-iptables"
read -r iptablesAnswer
if [[ $iptablesAnswer == "Y" || $iptablesAnswer == "y" ]]; then
	git clone https://github.com/jeekkd/restricted-iptables
	echo
	echo "Note: Reference README for configuration information"
fi

echo
echo "* Complete!"
echo "Note: remember to set your /etc/fstab to reflect your specific system"

