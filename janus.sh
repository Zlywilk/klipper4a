#!/bin/bash
: "${DISTRO:=$(sed -n 's/^ID=//p' /etc/os-release)}"
export LIBNICE_VERSION="0.1.16"
export LIBSRTP_VERSION="v2.3.0"
export LIBWEBSOCKETS_VERSION="v3.2.2"
export USRSCTP_VERSION="0.9.3.0"
export JANUS_VERSION="v0.10.3"
if [ "$DISTRO" == "alpine" ]; then
	sudo apk update && sudo apk add libmicrohttpd jansson-dev sofia-sip-dev glib-dev opus-dev libogg-dev libconfig-dev pkgconfig gengetopt 	libsrtp-dev libtool automake libconfig-dev gtk-doc cmake autoconf m4 ninja meson libmicrohttpd-dev jansson-dev opus-dev curl-dev ibpq-dev libc-dev musl-dev build-base doxygen graphviz gstreamer-dev
	mkdir ~/janus && cd ~/janus || exit 
	wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz && tar xfv v2.2.0.tar.gz && cd libsrtp-2.2.0 && ./configure --enable-openssl && make -j2 shared_library && sudo make install
cd ~/janus && wget https://github.com/warmcat/libwebsockets/archive/refs/tags/v2.4.2.tar.gz && tar zxvf v2.4.2.tar.gz && cd libwebsockets-2.4.2/ && mkdir build && cd build && cmake .. -DLWS_WITH_SSL=OFF -DLWS_WITHOUT_BUILTIN_SHA1=OFF && make -j2 && sudo make install
 
cd ~/janus && git clone https://github.com/sctplab/usrsctp && cd usrsctp && ./bootstrap && ./configure --prefix=/usr --disable-programs --disable-inet --disable-inet6 && make -j2 && sudo make install
cd ~/janus && git clone https://gitlab.freedesktop.org/libnice/libnice && cd libnice && git checkout 0.1.16
sed -i -e 's/NICE_ADD_FLAG(\[-Wcast-align\])/# NICE_ADD_FLAG([-Wcast-align])/g' configure.ac
sed -i -e 's/NICE_ADD_FLAG(\[-Wno-cast-function-type\])/# NICE_ADD_FLAG([-Wno-cast-function-type])/g' configure.ac
meson --prefix=/usr build && ninja -C build && sudo ninja -C build install

cd ~/janus && git clone https://github.com/TheSpaghettiDetective/janus-gateway.git
cd janus-gateway && git checkout tsd-stable
sh autogen.sh && ./configure --disable-all-plugins --enable-plugin-streaming --disable-all-transports --enable-websockets --enable-rest --disable-docs --prefix=/opt/janus && make -j"${nproc}" CFLAGS='-std=c99' && sudo make install && sudo make configs


else
sudo apt-get update && sudo apt-get install -y libmicrohttpd-dev libjansson-dev libsofia-sip-ua-dev libglib2.0-dev libopus-dev libogg-dev libini-config-dev libcollection-dev pkg-config gengetopt\
 libtool automake dh-autoreconf libconfig-dev gtk-doc-tools cmake autoconf m4 meson ninja libgstreamer1.0-dev
fi