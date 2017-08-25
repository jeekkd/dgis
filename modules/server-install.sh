#!/usr/bin/env bash

echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"-X -gtk -kde -gnome -minimal hardened\"" >> /etc/portage/make.conf

# Assure the sensible network adapter naming scheme is used
sed -i 's/#GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="net.ifnames=0"/' /etc/default/grub

for (( ; ; )); do
	printf " * Would you like to statically set your IP address? Enter [y/n] \n"
	read -r staticAddressAnswer
	if [[ $staticAddressAnswer == "Y" || $staticAddressAnswer == "y" ]]; then
		ip link
		printf "\n"
		printf "Type the adapter name to configure. Ex: eth0 \n"
		read -r adapterName
		printf "\n"
		printf "Enter the address this adapter should have. Ex: 172.16.53.10 \n"
		read -r adapterAddress
		printf "\n"
		printf "Enter the netmask of the address. Ex: 255.255.255.0 \n"
		read -r adapterNetmask
		printf "\n"
		printf "Enter the gateway to use. Ex: 172.16.53.1 \n"
		read -r adapterGateway
		printf "\n"
		printf "Enter the DNS server to use. Ex: 8.8.4.4 \n"
		read -r adapterDNS
		printf "\n"
		echo "config_$adapterName=\"$adapterAddress netmask $adapterNetmask\"" >> /etc/conf.d/net
		echo "routes_$adapterName=\"default via $adapterGateway\"" >> /etc/conf.d/net
		echo "dns_servers_$adapterName=\"$adapterDNS\"" >> /etc/conf.d/net
		
		ln -s /etc/init.d/net.lo /etc/init.d/net."$adapterName"
		/etc/init.d/net."$adapterName" start
		rc-update del dhcpcd default
		break
	elif [[ $firmwareAnswer == "N" || $firmwareAnswer == "n" ]]; then
		printf "No was selected, keeping DHCP as the default. \n"
		break
	else
		printf "Error: Invalid selection, Enter [y/n] \n"
	fi
done

# Enable services
rc-update add sshd default
