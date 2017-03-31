#!/usr/bin/env bash
# Written by: https://github.com/jeekkd
# Website: https://daulton.ca
# 
# This is a script to install Gentoo in a partially interactive manner, it gives a baseline install 
# configured with Gentoo itself, a kernel, bootloader, some necessary applications, etc. while giving the 
# flexibility to be prompted for desktop environment or window manager (or none at all if you choose), 
# display manager, along with locale, time zone, usernames, passwords, hostname and other user specific 
# selections.
#
# The intended use is that first your partitioning is done as you wish, you run the script and it handles
# everything up the point of configuring the fstab or any additional options your grub configuration may
# require. This is intended as both partitioning and /etc/fstab have a lot of choice and potential for 
# custom configuration and a one size fits all solution does not work for all.
#
# Procedure:
# 1. Mount root on /mnt/gentoo (and other partitions where they belong if they are seperate from root)
# 2. cd to /mnt/gentoo
# 3. untar your stage3 of choice as you normally would
# 4. Clone the repo to get the scripts
# 5. Create and enter a chroot at /mnt/gentoo
# 6. cd to dgis/
# 7. Edit the /etc/fstab with your partitions (or after the script as ran, either way)
# 8. Run the script with bash dgis-launch.sh
# 9. Reboot

################## VARIABLES ##################
# Default nameserver to set in resolv.conf
defaultNameserver="8.8.8.8"

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
	printf "Control-c pressed - exiting NOW"
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
	local package=$1
	local packageTest=
    packageTest=$(equery -q list "$package")
    if [[ -z ${packageTest} ]]; then
		confUpdate "$package"
    fi
}

printf "Install Xorg? Y/N \n"
read -r installXorg
if [[ $installXorg == "Y" ]] || [[ $installXorg == "y" ]]; then	
	printf
	while true ; do
		printf "\n"
		printf "=================================== \n" 
		printf "Desktop Environment Selection menu \n"
		printf "=================================== \n"
		printf "\n"
		printf "A. Xfce \n"
		printf "B. KDE \n"
		printf "C. Ratpoison \n"
		printf "D. LXDE \n"
		printf "E. Xmonad \n"
		printf "F. Gnome \n"
		printf "G. Skip this selection \n"
		printf "\n"
		printf "Enter a selection: \n"
		read -r option			
		case "$option" in				
		[Aa])
			installDesktop=1
			printf "Xfce has been selected for the Desktop Environment \n"
			break
		;;
		[Bb])
			installDesktop=2
			printf "KDE has been selected for the Desktop Environment \n"
			break
		;;
		[Cc])
			installDesktop=3
			printf "Ratpoison has been selected for the Window Manager \n"
			break
		;;
		[Dd])
			installDesktop=4
			printf "LXDE has been selected for the Desktop Environment \n"
			break
		;;
		[Ee])
			installDesktop=5
			printf "Xmonad has been selected for the Window Manager \n"
			break
		;;
		[Ff])
			installDesktop=6
			printf "Gnome has been selected for the Desktop Environment \n"
			break
		;;
		[Gg])
			printf "Skipping desktop environment selection.. \n"
			break
		;;
		*)
			printf "Enter a valid selection from the menu - options include A to G \n"
		;;	
		esac 	
    done
	
	if [[ $installDesktop == "1" ]]; then
        printf "\n"
		printf "Install Vertex GTK and Paper Icons themes? Y/N \n"
		read -r installTheme
		printf "\n"
		printf "Install default set of applications? Y/N \n"
		read -r installApplications	
	fi
fi

# Set DNS server
printf "\n"
printf "Would you like to use the default Google 8.8.8.8 nameserver (Press 1) \n"
printf "or enter one of your own (Press 2)? \n"
read -r nameserverOptions
if [[ $nameserverOptions == "1" ]]; then
	printf "nameserver $defaultNameserver\n" > /etc/resolv.conf
	if [ $? -gt 0 ]; then
		printf "Error: Failed to set nameserver to $nameServer\n"
		exit 1
	fi	
elif [[ $nameserverOptions == "2" ]]; then
	printf "Enter a nameserver in dotted decimal format such as 8.8.8.8\n"
	read -r enteredNameserver
	printf "nameserver $enteredNameserver\n" > /etc/resolv.conf
	if [ $? -gt 0 ]; then
		printf "Error: Failed to set nameserver to $answer..\n"
		exit 1
	fi
else
	printf "Error: Enter either the number 1 or 2 as your selection.\n"
fi

# Configuring system basics
mkdir -p /etc/portage/repos.conf/

if [ ! -f /etc/portage/repos.conf/gentoo.conf ]; then
	printf "[gentoo]\n" >> /etc/portage/repos.conf/gentoo.conf
	printf "location = /usr/portage\n" >> /etc/portage/repos.conf/gentoo.conf
	printf "sync-type = rsync\n" >> /etc/portage/repos.conf/gentoo.conf
	printf "sync-uri = rsync://rsync.gentoo.org/gentoo-portage\n" >> /etc/portage/repos.conf/gentoo.conf
	printf "auto-sync = yes\n" >> /etc/portage/repos.conf/gentoo.conf
fi

if [ -f /etc/portage/repos.conf/gentoo.conf ]; then
	chmod 644 /etc/portage/repos.conf/gentoo.conf
else
	printf "Error: gentoo.conf does not exist in /etc/portage/repos.conf/ - exiting\n"
	exit 1
fi

# Adding make.conf at /etc/portage
cp make.conf /etc/portage/
if [ -f /etc/portage/make.conf ]; then
	chmod 644 /etc/portage/make.conf
	detectCores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1)
	printf " \n" >> /etc/portage/make.conf
	printf "# Make concurrency level for emerges \n" >> /etc/portage/make.conf
	MAKEOPTS="-j$detectCores\n" >> /etc/portage/make.conf
	env-update && source /etc/profile && export PS1="(chroot) $PS1" 
else
	printf "Error: make.conf does not exist in /etc/portage/ - exiting \n"
	exit 1
fi

# Updating portage tree with webrsync
printf "\n"
printf "* Syncing then emerging portage.. \n"
emerge-webrsync
if [ $? -eq 0 ]; then
	emerge --oneshot -q sys-apps/portage
else
	printf "Error: emerge sync failed - exiting \n"
	exit 1
fi

# Profile selection
printf "\n"
printf "* Listing profiles... \n"
printf "Note: If you chose Gnome as your desktop environment, just now just select a regular desktop profile and later you will be reprompted to select the Gnome profile. \n"
eselect profile list
printf "\n"
printf "Which profile would you like? Type a number: \n"
read -r inputNumber
eselect profile set "$inputNumber"
env-update && source /etc/profile && export PS1="(chroot) $PS1" 

# Getting time zone data
for (( ; ; )); do
	printf "\n"
	printf "Would you like to use the default Canada/Central timezone (1) or enter your own (2)? \n"
	read -r timezoneOption
	if [[ $timezoneOption == "1" ]]; then
		printf "Canada/Central\n" > /etc/timezone
		break
	elif [[ $timezoneOption == "2" ]]; then
		printf "Reference the Gentoo wiki for help - https://wiki.gentoo.org/wiki/System_time#OpenRC \n"
		printf "Enter a timezone: \n"
		read -r timezoneAnswer
		printf "$timezoneAnswer\n" > /etc/timezone
		break
	else
		printf "Error: Enter either the number 1 or 2 as your selection. \n"
	fi
done
emerge -v --config sys-libs/timezone-data 

# Setting computer hostname
printf "\n"
printf "* Setting hostname... \n"
nano -w /etc/conf.d/hostname

# Setting the root password
printf "\n"
printf "* Enter a password for the root account: \n"
passwd root 

# Creating the user account and setting its password
for (( ; ; )); do
	printf "\n"
	printf "* Enter a username for your user: \n"
	read -r inputUser
	printf "\n"
	printf "Confirm that $inputUser is the desired username. Press Y/N \n"
	read -r usernameConfirm
	if [[ $usernameConfirm == "Y" || $usernameConfirm == "y" ]]; then
		useradd -m -G users,usb,video,portage,audio -s /bin/bash "$inputUser"
		printf "\n"
		printf "* Enter a password for $inputUser \n"
		passwd "$inputUser"
		break
	elif [[ $usernameConfirm == "N" || $usernameConfirm == "n" ]]; then
		printf "No was selected, re-asking for correct username\n"
	else
		printf "Error: Enter either the number Y or N as your selection. \n"
	fi
done

# Setting keymaps
for (( ; ; )); do
	printf "\n"
	printf "* Do you need to edit keymaps? Default is en-US. Select Y/N \n"
	read -r answerKeymaps
	if [[ $answerKeymaps == "Y" || $answerKeymaps == "y" ]]; then
		nano -w /etc/conf.d/keymaps
		break
	elif [[ $answerKeymaps == "N" || $answerKeymaps == "n" ]]; then
		printf "Skipping editing keymaps \n"
		break
	else
		printf "Error: Invalid selection, enter either Y or N \n"
	fi
done

# Updating world
printf "\n"
printf "* Updating world.. \n"
confUpdate " --deep --with-bdeps=y --newuse --update @world"

# Setting CPU flags in /etc/portage/make.conf
printf "* Setting CPU flags in /etc/portage/make.conf \n"
emerge --oneshot -q app-portage/cpuid2cpuflags
cpuFlags=$(cpuinfo2cpuflags-x86)
printf " \n" >> /etc/portage/make.conf
printf "# Supported CPU flags \n" >> /etc/portage/make.conf
printf "$cpuFlags \n" >> /etc/portage/make.conf

# Getting system basics
printf "\n"
printf "* Emerging git, flaggie, dhcpcd... \n"
confUpdate "dev-vcs/git app-portage/flaggie net-misc/dhcpcd app-portage/gentoolkit"

# Install and build kernel
printf "\n"
printf "* Cloning repo for my gentoo_kernel_build script to build the kernel \n"
printf "\n"
git clone https://github.com/jeekkd/gentoo-kernel-build.git && cd gentoo-kernel-build
if [ $? -eq 0 ]; then	
	chmod 770 build_kernel.sh
	bash build_kernel.sh
	if [ $? -gt 0 ]; then	
		for (( ; ; )); do
			printf "Error: build_kernel.sh failed - try again? Y/N \n"
			read -r kernelBuildRetry
			if [[ $kernelBuildRetry == "Y" ]] || [[ $kernelBuildRetry == "y" ]]; then	
				bash build-kernel.sh
			elif [[ $kernelBuildRetry == "N" ]] || [[ $kernelBuildRetry == "n" ]]; then	
				printf "No selected, skipping retrying kernel build. \n"
				break
			else
				printf "Error: Invalid selection, enter either Y or N \n"
			fi
		done
	else
		cd ..
	fi
else
	printf "Error: git clone failed for retrieving kernel build script from the following location https://github.com/jeekkd/gentoo-kernel-build \n"
	exit 1
fi

# Locale configuration
printf "\n"
printf "* Locale selection.. \n"
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
. /etc/profile

# Hardware clock configuration
for (( ; ; )); do
	printf "\n"
	printf "* Do you need to edit hwclock options?. Select Y/N \n"
	read -r editHwclock
	if [[ $editHwclock == "Y" || $editHwclock == "y" ]]; then
		nano -w /etc/conf.d/hwclock
		break
	elif [[ $editHwclock == "N" || $editHwclock == "n" ]]; then
		printf "Skipping editing hwclock settings \n"
		break
	else
		printf "Error: Invalid selection, enter either Y or N \n"
	fi
done

# Installing Xorg
# Add or remove contents of VIDEO_CARDS and INPUT_DEVICES as necessary, this current configuration is
# meant to encompass a variety of setups for ease of use to the user
if [[ $installXorg == "Y" ]] || [[ $installXorg == "y" ]]; then	
	printf " \n" >> /etc/portage/make.conf
	printf "# Video and input devices for Xorg \n" >> /etc/portage/make.conf
	printf "VIDEO_CARDS=\"amndgpu fbdev radeon radeonsi nouveau intel\" \n" >> /etc/portage/make.conf
	printf "INPUT_DEVICES=\"keyboard mouse synaptics evdev\" \n" >> /etc/portage/make.conf
	env-update && source /etc/profile
	printf "\n"
	printf "* Xorg installation.. \n"
	emerge --changed-use --deep @world
fi

# Installing desktop environment or window manager selection
if [[ $installDesktop == "1" ]]; then
	import xfce-install
elif [[ $installDesktop == "2" ]]; then
	import kde-install
elif [[ $installDesktop == "3" ]]; then
	import ratpoison-install
elif [[ $installDesktop == "4" ]]; then
	import lxde-install
elif [[ $installDesktop == "5" ]]; then
	import xmonad-install
elif [[ $installDesktop == "6" ]]; then
	import gnome-install
fi

printf "* Beginning to emerge helpful and necessary programs such as hwinfo, usbutils, sudo, rsyslog... \n"
flaggie app-admin/logrotate +acl
flaggie app-admin/logrotate +cron

confUpdate "sys-process/fcron app-admin/logrotate sys-apps/hwinfo app-admin/sudo app-admin/rsyslog net-firewall/iptables sys-apps/usbutils"
if [ $? -gt 0 ]; then	
    usermod -aG wheel "$inputUser"
    usermod -aG cron "$inputUser"
    usermod -aG cron root
fi
    
printf "\n"
printf "* Adding startup items to OpenRC for boot.. \n"
rc-update add consolekit default
rc-update add xdm default
rc-update add dbus default
rc-update add dhcpcd default
rc-update add rsyslog default
rc-update add fcron default

for (( ; ; )); do
	printf "\n"
	printf "* Would you like to install linux-firmware? Y/N \n"
	printf "Some devices require additional firmware to be installed on the system before they work. This is often the case for network interfaces, especially wireless network interfaces \n"
	read -r firmwareAnswer
	if [[ $firmwareAnswer == "Y" || $firmwareAnswer == "y" ]]; then
		confUpdate "sys-kernel/linux-firmware"
		break
	elif [[ $firmwareAnswer == "N" || $firmwareAnswer == "n" ]]; then
		printf "No was selected, skipping linux-firmware installation. \n"
		break
	else
		printf "Error: Invalid selection, enter either Y or N \n"
	fi
done

printf "\n"
printf "* Cleaning up stage3 install tar.. \n"
rm /stage3-*.tar.bz2*

for (( ; ; )); do
	printf "\n"
	printf "Would you be interested in my restricted-iptables script as well? Y/N \n"
	printf "It is a configurable iptables firewall script meant to make firewalls easier \n"
	printf "Reference the repo at: https://github.com/jeekkd/restricted-iptables \n"
	read -r iptablesAnswer
	if [[ $iptablesAnswer == "Y" || $iptablesAnswer == "y" ]]; then
		isInstalled "net-firewall/iptables"
		printf
		git clone https://github.com/jeekkd/restricted-iptables
		printf "\n"
		printf "Note: Reference README for configuration information and usage, and assure to read carefully through configuration.sh when doing configuration. \n"
		printf "\n"
		printf "* Adding iptables and ip6tables to OpenRC for boot.. \n"
		rc-update add iptables default
		rc-update add ip6tables default
	elif [[ $iptablesAnswer == "N" || $iptablesAnswer == "n" ]]; then
		printf "\n"
		printf "Skipping installation of restricted-iptables script \n"
		break
	else
		printf "\n"
		printf "Error: Invalid selection, enter either Y or N \n"
	fi
done

printf "\n"
printf "* Complete! \n"
printf "Note: remember to set your /etc/fstab to reflect your specific system \n"

