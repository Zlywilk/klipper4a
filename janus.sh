#!/bin/bash
: "${DISTRO:=$(sed -n 's/^ID=//p' /etc/os-release)}"

if [ "$DISTRO" == "alpine" ]; then
	sudo apk update && sudo apk add libmicrohttpd jansson-dev sofia-sip-dev glib-dev opus-dev libogg-dev libconfig-dev pkgconfig gengetopt libtool automake libconfig-dev 	gtk-doc cmake
else
sudo apt-get update && sudo apt-get install -y libmicrohttpd-dev libjansson-dev libsofia-sip-ua-dev libglib2.0-dev libopus-dev libogg-dev libini-config-dev libcollection-dev pkg-config gengetopt\
 libtool automake dh-autoreconf libconfig-dev gtk-doc-tools cmake
fi