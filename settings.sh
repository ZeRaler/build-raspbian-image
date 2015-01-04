#!/bin/bash

# Options sort by appaerance

_BOOT_PARTITION_SIZE="64M"		# "64M" = 64 MB

###############################################################################

_DEB_RELEASE="wheezy"				# jessie | wheezy | squeeze
# TODO META VARIABLE
# _DEB_DISTRIBUTION=""		# Debian | Rasbian

###################
# Available Debian Mirrors for Installation
_APT_SOURCE_DEBIAN="ftp://ftp.debian.org/debian"
_APT_SOURCE_DEBIAN_CDN="http://http.debian.net/debian"

_APT_SOURCE_RASPBIAN="http://archive.raspbian.org/raspbian"

# _APT_SOURCE_DEB_MULTIMEDIA="http://www.deb-multimedia.org"

# _APT_SOURCE_LOCAL="http://localhost:3142/archive.raspbian.org/raspbian" # Require: apt-cacher-ng # FIXME Fix repo path
###################

# _DEB_SECTION="main contrib non-free rpi"

# _APT_SOURCE_LIST=""

###############################################################################


# TODO
# BOOT_CMDLINE=""

_FSTAB="
proc			/proc	proc	defaults	0	0
/dev/mmcblk0p1	/boot	vfat	defaults	0	0
"

_HOSTNAME=""

_NET_CONFIG=""				# dhcp|static
if [ "${_NET_CONFIG}" == "static" ]; then
	_NET_ADDRESS=""
	_NET_NETMASK=""
	_NET_GATEWAY=""
fi

_MODULES=""

_APT_PACKAGES="locales console-common openssh-server ntp less vim"

_USER_NAME=""
_USER_PASS=""


#######################################
# NOT YET IN USE

_KEYMAP=""
_TIMEZONE=""
_LOCALES=""					#en_US.utf-8 de_DE.utf-8
_ENCODING=""

# _DISK_OPTION=""				# expand rootfs|create new partion from free space|nothing


###############################################################################
# Apply-Functions

get_apt_source_mirror_url () {
	if [ "x${_USE_CACHE}" = "xno" ]; then
		echo "${_APT_SOURCE}"
	else
		HTTP="http://"
		echo -n "http://localhost:3142/${_APT_SOURCE#${HTTP}}"
	fi
}

get_apt_sources_first_stage () {

	echo "
deb $(get_apt_source_mirror_url) ${_DEB_RELEASE} main contrib non-free rpi firmware
#deb-src $(get_apt_source_mirror_url) ${_DEB_RELEASE} main contrib non-free rpi firmware
"
}

get_apt_sources_final_stage () {

	echo "
deb ${_APT_SOURCE} ${_DEB_RELEASE} main contrib non-free rpi
deb-src ${_APT_SOURCE} ${_DEB_RELEASE} main contrib non-free rpi

deb ${_APT_SOURCE} ${_DEB_RELEASE}-updates main contrib non-free

deb http://security.debian.org/ ${_DEB_RELEASE}/updates main contrib non-free
deb-src http://security.debian.org/ ${_DEB_RELEASE}/updates main contrib non-free
"
}

#######################################

# NETWORK CONFIG
set_network_config () {

	if [ -z "$1" ]; then
		echo "Error on set_network_config: No profile specified!"
		exit # TODO Set error code
	fi

	_NET_CONFIG_FILE="etc/network/interfaces"

	case "$1" in
		"dhcp")
			echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
iface eth0 inet6 auto
" > ${_NET_CONFIG_FILE}
				;;

		"static")
			if [ -z ${_NET_ADDRESS} ] || [ -z ${_NET_NETMASK} ] || [ -z ${_NET_GATEWAY} ]; then 
				echo "Error on set_network_config: 'static' was specified, but no values where set."
				exit # TODO Set error code
			fi

			echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address ${_NET_ADDRESS} # 192.0.2.7
	netmask ${_NET_NETMASK} # 255.255.255.0
	gateway ${_NET_GATEWAY} # 192.0.2.254
iface eth0 inet6 auto
" > ${_NET_CONFIG_FILE}
				;;

		*)
				# TODO Debug msg
				exit # TODO Set error code
				;;
	esac

}

