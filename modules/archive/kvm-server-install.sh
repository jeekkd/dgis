#!/usr/bin/env bash

firstUser=$(grep "1000" /etc/passwd | cut -f 1 -d :)

echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"-X -gtk -kde -gnome -minimal hardened\"" >> /etc/portage/make.conf

echo " " >> /etc/portage/make.conf
echo "# QEMU target declaration" >> /etc/portage/make.conf
echo "QEMU_SOFTMMU_TARGETS=\"arm x86_64\"" >> /etc/portage/make.conf
echo "QEMU_USER_TARGETS=\"x86_64\"" >> /etc/portage/make.conf

# Assure the sensible network adapter naming scheme is used
sed -i 's/#GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="net.ifnames=0"/' /etc/default/grub
touch /etc/udev/rules.d/80-net-name-slot.rules
grub-mkconfig -o /boot/grub/grub.cfg

# Ask, and set static addressing if the user wants it
askStaticAddress

# Package installation
confUpdate "app-emulation/qemu net-firewall/iptables sys-apps/usermode-utilities bridge-utils app-emulation/libvirt"

# Enable services
rc-update add sshd default

# Virtual network setup
modprobe tun

if [[ $staticAddressAnswer == "Y" || $staticAddressAnswer == "y" ]]; then
echo "tuntap_tap0=\"tap\" #Configure TUN/TAP interface
config_tap0=null # tap0 defined empty to avoid DHCP being run for their configuration
config_$adapterName=\"null\" # any other interfaces you want to bridge
bridge_br0=\"$adapterName\"
config_br0=\"$adapterAddress netmask $adapterNetmask\"  # the ip of the original eth0, or dhcp
brctl_br0=\"setfd 0 sethello 30 stp off\"
rc_net_br0_need=\"net.$adapterName net.tap0\" # we need run eth0 and tap0 before create bridge!" > /etc/conf.d/net
			
elif [[ $staticAddressAnswer == "N" || $staticAddressAnswer == "n" ]]; then
echo "tuntap_tap0=\"tap\" #Configure TUN/TAP interface
config_tap0=null # tap0 defined empty to avoid DHCP being run for their configuration
config_eth0=\"null\" # any other interfaces you want to bridge
bridge_br0=\"eth0\"
config_br0=\"dhcp\"  # the ip of the original eth0, or dhcp
brctl_br0=\"setfd 0 sethello 30 stp off\"
rc_net_br0_need=\"net.eth0 net.tap0\" # we need run eth0 and tap0 before create bridge!" > /etc/conf.d/net			
fi

ln -s /etc/init.d/net.lo /etc/init.d/net.br0 && /etc/init.d/net.br0 start
ln -s /etc/init.d/net.lo /etc/init.d/net.tap0 && /etc/init.d/net.tap0 start
rc-update add net.br0 default
rc-update add net.tap0 default

echo "net.ipv4.conf.tap0.proxy_arp=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.eth0.proxy_arp=1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o br0 -j MASQUERADE
iptables -A FORWARD -i br0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o br0 -j ACCEPT
/etc/init.d/iptables save

cpuManufacturer=$(lscpu | grep "Model name" | cut -d " " -f 14)
if [[ $cpuManufacturer == "AMD" ]]; then
	modprobe kvm-amd
	echo "modules=\"tun kvm-amd\"" >> /etc/conf.d/modules
else [[ $cpuManufacturer == "Intel(R)" ]]; then
	modprobe kvm-intel
	echo "modules=\"tun kvm-intel\"" >> /etc/conf.d/modules
fi

# Group permissions
usermod -aG kvm "$firstUser"

echo "Note!"
echo "1. Guest configuration must contain the following: -net nic,vlan=0 -net tap,ifname=tap0,script=no,downscript=no"
echo "2. I advise using /etc/local.d/ to run VMs at boot"
echo "3. If you flush the iptables configuration to set your own rules, assure to reset the rules from here: https://wiki.gentoo.org/wiki/QEMU#Packet_forwarding_and_NAT"
echo "4. Look into the virt-install tool for managing VMs"
echo "5. When launching VMs with virt-install or qemu, consider using an open VNC connection to connect from another machine"
