#!/bin/bash
: "${DISTRO:=$(sed -n 's/^ID=//p' /etc/os-release)}"
export LIBNICE_VERSION="0.1.16"
export LIBSRTP_VERSION="v2.3.0"
export LIBWEBSOCKETS_VERSION="v3.2.2"
export USRSCTP_VERSION="0.9.3.0"
export JANUS_VERSION="v0.10.3"
if [ "$DISTRO" == "alpine" ]; then
	sudo apk update && sudo apk add libmicrohttpd jansson-dev sofia-sip-dev glib-dev opus-dev libogg-dev libconfig-dev pkgconfig gengetopt 	libsrtp-dev libtool automake libconfig-dev gtk-doc cmake autoconf m4 ninja meson libmicrohttpd-dev jansson-dev opus-dev curl-dev libpq-dev libc-dev musl-dev build-base doxygen graphviz gstreamer-dev 	autoconf graphviz doxygen guile flex bison libunwind gcompat
	mkdir "$HOME"/janus && cd "$HOME"/janus || exit 
	wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz && tar xfv v2.2.0.tar.gz && cd libsrtp-2.2.0 && ./configure --enable-openssl && make -j "$(nproc)" shared_library && sudo make install
cd ~/janus && wget https://github.com/warmcat/libwebsockets/archive/refs/tags/v2.4.2.tar.gz && tar zxvf v2.4.2.tar.gz && cd libwebsockets-2.4.2/ && mkdir build && cd build && cmake .. -DLWS_WITH_SSL=OFF -DLWS_WITHOUT_BUILTIN_SHA1=OFF && make -j"$(nproc)" && sudo make install
 
cd ~/janus && git clone https://github.com/sctplab/usrsctp && cd usrsctp && autoupdate && ./bootstrap && ./configure --prefix=/usr --disable-programs --disable-inet --disable-inet6 && make -j"$(nproc)" && sudo make install
cd ~/janus && git clone https://gitlab.freedesktop.org/libnice/libnice && cd libnice && git checkout 0.1.16
sed -i -e 's/NICE_ADD_FLAG(\[-Wcast-align\])/# NICE_ADD_FLAG([-Wcast-align])/g' configure.ac
sed -i -e 's/NICE_ADD_FLAG(\[-Wno-cast-function-type\])/# NICE_ADD_FLAG([-Wno-cast-function-type])/g' configure.ac
meson --prefix=/usr build && ninja -C build && sudo ninja -C build install

cd ~/janus && git clone https://github.com/meetecho/janus-gateway
cd janus-gateway || exit
sh autogen.sh && ./configure --disable-all-plugins --enable-plugin-streaming --disable-all-transports PKG_CONFIG_PATH=/usr/local/opt/openssl/lib/pkgconfig --enable-websockets --enable-rest --disable-docs --prefix=/opt/janus && make -j"$(nproc)" CFLAGS='-std=c99' && sudo make install && sudo make config
cd "$HOME"||exit
git clone https://github.com/Zlywilk/moonraker-obico.git
cd moonraker-obico || exit & git checkout klipper4a
rm moonraker_obico/bin/janus/bin/janus
cp /opt/janus/bin/janus moonraker_obico/bin/janus/bin/
rm -r moonraker_obico/bin/janus/lib/*
cp -r /opt/janus/lib/janus moonraker_obico/bin/janus/lib
cp /usr/lib/libconfig.so.11 moonraker_obico/bin/janus/lib
cp /usr/lib/libjansson.so.4 moonraker_obico/bin/janus/lib
cp /usr/lib/libmicrohttpd.so.12 moonraker_obico/bin/janus/lib
cp /usr/lib/libnice.so.10 moonraker_obico/bin/janus/lib
cp /usr/lib/libsrtp2.so.1 moonraker_obico/bin/janus/lib
cp /usr/lib/libusrsctp.so.2 moonraker_obico/bin/janus/lib
cp /usr/local/lib/libwebsockets.so.12  moonraker_obico/bin/janus/lib
else
sudo apt-get update && sudo apt-get install -y libmicrohttpd-dev libjansson-dev libsofia-sip-ua-dev libglib2.0-dev libopus-dev libogg-dev libini-config-dev libcollection-dev pkg-config gengetopt\
 libtool automake dh-autoreconf libconfig-dev gtk-doc-tools cmake autoconf m4 meson ninja libgstreamer1.0-dev graphviz doxygen flex bison
 	mkdir "$HOME"/janus && cd "$HOME"/janus || exit 
	wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz && tar xfv v2.2.0.tar.gz && cd libsrtp-2.2.0 && ./configure --enable-openssl && make -j"$(nproc)" shared_library && sudo make install
cd ~/janus && wget https://github.com/warmcat/libwebsockets/archive/refs/tags/v2.4.2.tar.gz && tar zxvf v2.4.2.tar.gz && cd libwebsockets-2.4.2/ && mkdir build && cd build && cmake .. -DLWS_WITH_SSL=OFF -DLWS_WITHOUT_BUILTIN_SHA1=OFF && make -j"$(nproc)" && sudo make install
 
cd ~/janus && git clone https://github.com/sctplab/usrsctp && cd usrsctp && autoupdate && ./bootstrap && ./configure --prefix=/usr --disable-programs --disable-inet --disable-inet6 && make -j"$(nproc)" && sudo make install
cd ~/janus && git clone https://gitlab.freedesktop.org/libnice/libnice && cd libnice && git checkout 0.1.16
sed -i -e 's/NICE_ADD_FLAG(\[-Wcast-align\])/# NICE_ADD_FLAG([-Wcast-align])/g' configure.ac
sed -i -e 's/NICE_ADD_FLAG(\[-Wno-cast-function-type\])/# NICE_ADD_FLAG([-Wno-cast-function-type])/g' configure.ac
meson --prefix=/usr build && ninja -C build && sudo ninja -C build install

cd ~/janus && git clone https://github.com/meetecho/janus-gateway
cd janus-gateway || exit
sh autogen.sh && ./configure --disable-all-plugins --enable-plugin-streaming --disable-all-transports --enable-websockets --enable-rest --disable-docs --prefix=/opt/janus && make -j"$(nproc)" CFLAGS='-std=c99' && sudo make install && sudo make configs
cd ..
axel https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-1.20.3.tar.xz
tar -Jxvf gstreamer-1.20.3.tar.xz
cd gstreamer||exit
mkdir build
meson build
cd build||exit
ninja
sudo ninja install
cd "$HOME"||exit
git clone https://github.com/Zlywilk/moonraker-obico.git
cd moonraker-obico || exit & git checkout klipper4a
rm moonraker_obico/bin/janus/bin/janus
cp /opt/janus/bin/janus moonraker_obico/bin/janus/bin/
rm -r moonraker_obico/bin/janus/lib/*
cp -r /opt/janus/lib/janus moonraker_obico/bin/janus/lib
cp /usr/lib/libconfig.so.11 moonraker_obico/bin/janus/lib
cp /usr/lib/libjansson.so.4 moonraker_obico/bin/janus/lib
cp /usr/lib/libmicrohttpd.so.12 moonraker_obico/bin/janus/lib
cp /usr/lib/libnice.so.10 moonraker_obico/bin/janus/lib
cp /usr/lib/libsrtp2.so.1 moonraker_obico/bin/janus/lib
cp /usr/lib/libusrsctp.so.2 moonraker_obico/bin/janus/lib
cp /usr/local/lib/libwebsockets.so.12  moonraker_obico/bin/janus/lib
fi
