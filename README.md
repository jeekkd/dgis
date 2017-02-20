Dgis - Daultons Gentoo Installer Script
---------------------------------------

This is a script to install Gentoo in a partially interactive manner, it gives a baseline install 
configured with Gentoo itself, a kernel, bootloader, some necessary applications, etc. while giving the 
flexibility to be prompted for desktop environment or window manager (or none at all if you choose), display manager, along with locale, time zone, usernames, passwords, hostname and other user specific selections.

The intended use is that first your partitioning is done as you wish, you run the script and it handles
everything up the point of configuring the fstab or any additional options your grub configuration may
require. View the top of `dgis-launch.sh` if things are not clear.

Supported Desktop Environments and Window Managers
===

- KDE
- XFCE
- Ratpoison
- LXDE
- Xmonad

> **Note:** 
> There are more to come, but open an issue to request a specific one or see the Contributing section to
> submit a module for one!

Other Integrated Projects
===

This project features two of my other scripts, [restricted-iptables](https://github.com/jeekkd/restricted-iptables) and [gentoo-kernel-build](https://github.com/jeekkd/gentoo-kernel-build). 

The usage of restricted-iptables is optional, you are prompted at the end if you would to use it. If you choose to use it, it aims to be a configurable iptables firewall script meant to make firewalls easier so it may be of interest you. Additionally, it was written on a Gentoo system so it has excellent support.

The gentoo-kernel-build script is integrated with Dgis, this way you can get the benefits of a featureful build kernel script in a way that seamlessly integrates. For its features [check out the project page.](https://github.com/jeekkd/gentoo-kernel-build)

These two projects can of course be used independently of Dgis, so consider checking them out for your own usage.

How to use
===

- Mount your root at /mnt/gentoo

```
mount /dev/sda1 /mnt/gentoo
```

> **Note:** 
> Replace /dev/sda1 with your root
> 
> If you have a seperate boot partition or moved any other directories then mount those too
>

- Change directories to /mnt/gentoo

```
cd /mnt/gentoo
```

- Untar your stage3 of choice as you normally would. [Link to Gentoo downloads](https://www.gentoo.org/downloads/)

```
tar xvjpf stage3-*.tar.bz2 --xattrs
```

- Lets get the source

```
git clone https://github.com/jeekkd/dgis.git
```

- Create and enter a chroot

```
mount -t proc proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) $PS1"
```

- This will make the script readable, writable, and executable to root and your user. 

```
cd dgis
chmod 770 -R dgis-launch.sh modules/
```

Then launch the script by doing the following as root:

```
bash dgis-launch.sh
```


Pitfalls
===

- OpenRC only at this time unless there becomes some demand for systemd.

- Must assume a variety of input and video devices to support a wider audience of users hardware, feel free to add or remove from VIDEO_CARDS and INPUT_DEVICES at approximately line 300 in `dgis-launch.sh`.

- Supports a limited number of desktop environments and window managers at this moment (See current list above). Requests and pull requests are accepted, see the contributing section or open an issue with your request.

- X only currently, there is no Wayland support yet - it could be supported if requested.

Contributing
===

This section covers contributing, in essence any good pull request will be accepted if the code quality
is good and it fixes something or fulfills a purpose such as adding additional features or making the
script easier and smoother to use.


----------


Areas in which contribution would be highly encouraged especially, is adding additional desktop environment
or window manager support. To create a module for your addition, it must be named in the format of
`<DE or WM name>-install.sh` and in the modules directory. This module is imported and the commands within will execute as a regular script would essentially as a sub-shell.

Offering some premade configuration options rather than just the stock experience would be ideal. As with
the XFCE module as an example, an alternative theme and icon theme are offered. Modifications for such things
to existing modules would be encouraged.

Each new desktop environment or some window manager requires an addition to the selection menu and a
corresponding install section entry. These examples outline such:

- Selection menu

```
[Bb])
	installDesktop=2
	printf "KDE has been selected for the desktop environment \n"
	break
;;
```

Each addition of course requires an increment in installDesktop variable, keeping the echo message similar to the example would be ideal for maintaining consistency.

----------


- Install section

```
if [[ $installDesktop == "2" ]]; then
	import kde-install
fi
```

Use the same value as given above in the installDesktop variable for the if clause. Note that with the import statement `.sh` is implied, adding it is unnecessary as shown here:

```
# import()
# Important module(s) for the purpose of modularizing the script. Usage is simply
# import <name of module>, do not add the file extension.
import() {
	module=$1
	. "$script_dir"/modules/${module}.sh
}
```

----------
After review both the module for your addition of a desktop environment or window manager, and the additions to the main script, `dgis-launch.sh`, will be accepted.


