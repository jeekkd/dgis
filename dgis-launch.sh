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
# 3. clone repo
# 4. Run the script with bash dgis-launch.sh
# 5. Edit the /etc/fstab with your partitions
# 6. Reboot

# Default root mount directory
DESTINATION=/mnt/gentoo

# mountChroot()
# mount necessary filesystems for chroot environment
function mountChroot() {
	printf "\n"
	printf "* Creating and entering chroot environment... \n"
	printf "\n"
	mkdir -p "$DESTINATION/proc"
	mkdir -p "$DESTINATION/sys"
	mkdir -p "$DESTINATION/dev"
	
	mount -t proc none "$DESTINATION/proc"
	mount --rbind /sys "$DESTINATION/sys"
	mount --make-rslave "$DESTINATION/sys"
	mount --rbind /dev "$DESTINATION/dev"
	mount --make-rslave "$DESTINATION/dev"
	
	chroot /mnt/gentoo dgis/chroot-commands.sh
	. /etc/profile
	export PS1="(chroot) $PS1"
	export PS1="(chroot) $PS1"
}

# stage3Download()
# Download the latest stage3 tarball
function stage3Download() {
	printf "\n"
	printf "Downloading the stage 3 tarball... \n"	
	LATEST=$(wget --quiet http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64.txt -O-| tail -n 1 | cut -d " " -f 1)
	BASENAME=$(basename "$LATEST")
	wget -q --show-progress "http://distfiles.gentoo.org/releases/amd64/autobuilds/$LATEST" -O "$DESTINATION/$BASENAME"
		
	BASENAME=$(basename "$STAGE3")
	wget -q --show-progress "$STAGE3" -O "$DESTINATION/$BASENAME"

	ARG ARCH=amd64
	ARG MICROARCH=amd64
	ARG SUFFIX
	ARG DIST="https://ftp-osl.osuosl.org/pub/gentoo/releases/${ARCH}/autobuilds"
	ARG SIGNING_KEY="0xBB572E0E2D182910"
	STAGE3PATH="$(wget -O- "${DIST}/latest-stage3-${MICROARCH}${SUFFIX}.txt" | tail -n 1 | cut -f 1 -d ' ')"
	STAGE3="$(basename ${STAGE3PATH})"
	
	wget -q "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS.gz" "${DIST}/${STAGE3PATH}.DIGESTS.asc"
	gpg --keyserver hkps://keys.gentoo.org --recv-keys ${SIGNING_KEY}
	gpg --verify "${STAGE3}.DIGESTS.asc"
	awk '/# SHA512 HASH/{getline; print}' ${STAGE3}.DIGESTS.asc | sha512sum -c
}

printf "\n"
printf "============================================================= \n"
printf "Dgis - Daultons Gentoo Installer Script \n"
printf "https://github.com/jeekkd/dgis \n"
printf "============================================================= \n"
printf "\n"
printf "If you run into any problems, please open an issue so it can fixed. Thanks! \n"
printf "\n"

isRootMounted=$(mount | grep "on /mnt/gentoo")
if [ -z "$isRootMounted" ]; then
	printf "Error: nothing is mounted at /mnt/gentoo. Mount your desired root drive there and launch again \n"
	exit 1
else
	cd /mnt/gentoo
	stage3Download
	printf "\n"
	printf "Extracting stage 3 tarball... \n"
	tar xpf "${STAGE3}" --xattrs-include='*.*' --numeric-owner
	mountChroot
fi
