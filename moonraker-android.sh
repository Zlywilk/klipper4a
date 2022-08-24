#!/bin/bash
: "${CONFIG_PATH:="$HOME/config"}"
: "${GCODE_PATH:="$HOME/gcode"}"

: "${KLIPPER_REPO:="https://github.com/KevinOConnor/klipper.git"}"
: "${KLIPPER_PATH:="$HOME/klipper"}"
: "${KLIPPY_VENV_PATH:="$HOME/venv/klippy"}"

: "${MOONRAKER_REPO:="https://github.com/Arksine/moonraker"}"
: "${MOONRAKER_PATH:="$HOME/moonraker"}"
: "${MOONRAKER_VENV_PATH:="$HOME/venv/moonraker"}"

: "${CLIENT_PATH:="$HOME/www"}"
: "${IP:=$(ip route get 8.8.8.8 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | tail -1)}"
: "${BOARDMANUFACTURER:="klipper"}"
: "${DISTRO:=$(sed -n 's/^ID=//p' /etc/os-release)}"
: "${DISTRO_VERSION:=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')}"
: "${OBICO_CFG_FILE:="${CONFIG_PATH}/moonraker-obico.cfg"}"
MAKEFLAGS="-j$(nproc)"
export MAKEFLAGS
if [ "$DISTRO" == "alpine" ]; then
	sudo apk add eudev
else
	sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
	echo "PATH=/usr/sbin:$PATH" | tee -a .bashrc
fi

findserial() {
	for f in /dev/tty*; do
		if [ "$(udevadm info -a -n "${f}" | grep -m1 "{manufacturer}" | cut -d= -f3 | xargs)" == "$BOARDMANUFACTURER" ]; then
			SERIAL="$f"
		fi
	done
}
findserial
COL='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m'
if [ -e "$SERIAL" ]; then
	if [[ -z $(find /dev -maxdepth 1 -name "$SERIAL" ! -user "$USER") ]]; then
		printf "${COL}fix %s\n permissions${NC}"
		sudo chown -R "$USER":"$USER" "$SERIAL"
	fi
	cat >"$HOME"/watchperm.sh <<EOF
#!/bin/bash
: "\${BOARDMANUFACTURER:="$BOARDMANUFACTURER"}"
EOF
	declare -f findserial >>"$HOME"/watchperm.sh
	cat >>"$HOME"/watchperm.sh <<EOF
findserial
if [ "$(stat -c %U "\$SERIAL")" != "\$USER" ]; then
    sudo chown -R "\$USER":"\$USER" "\$SERIAL"
fi
EOF
	chmod +x watchperm.sh
	cat >"$HOME"/start.sh <<EOF
#!/bin/bash
: "\${BOARDMANUFACTURER:="$BOARDMANUFACTURER"}"
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8085
EOF
	declare -f findserial >>start.sh
	cat >>"$HOME"/start.sh <<EOF
findserial
OLDSERIAL=\$(grep "serial:" config/printer.cfg |cut -d":" -f2 )
OLDIP=\$(grep -E -o -m1 "([0-9]{1,3}[\.]){3}[0-9]{1,3}" /etc/nginx/nginx.conf |tail -1)
IP=\$(ip route get 8.8.8.8 |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | tail -1)
if [[ "\$OLDIP" != "\$IP" ]]; then
sudo sed -i "s|\$OLDIP|\$IP|g" /etc/nginx/nginx.conf
fi
if [[ "\$SERIAL" != "\$OLDSERIAL" ]]; then
if [ -e "\$SERIAL" ]
then
sed -i "s|\$OLDSERIAL| \$SERIAL|g" config/printer.cfg
fi
fi

screen -d -m -S permcheck watch -n 10 "$HOME"/watchperm.sh
screen -d -m -S moonraker /home/android/venv/moonraker/bin/python /home/android/moonraker/moonraker/moonraker.py
screen -d -m -S klippy /home/android/venv/klippy/bin/python  /home/android/klipper/klippy/klippy.py /home/android/config/printer.cfg -l /tmp/klippy.log -a /tmp/klippy_uds
screen -d -m -S nginx nginx

EOF
else
	printf "${RED}connect printer and rerun script%s\n${NC}"
	exit
fi
cat >"$HOME"/stop.sh <<EOF
#!/bin/bash
killall screen nginx
EOF
chmod +x stop.sh
################################################################################
# PRE
################################################################################
printf "${COL}Installing dependencies...%s\n${NC}"
if [ "$DISTRO" == "alpine" ]; then
	sudo apk add git unzip libffi-dev make gcc g++ \
		ncurses-dev avrdude gcc-avr binutils-avr \
		python3 py3-virtualenv \
		python3-dev freetype-dev fribidi-dev harfbuzz-dev jpeg-dev lcms2-dev openjpeg-dev tcl-dev tiff-dev tk-dev zlib-dev \
		jq udev curl-dev libressl-dev curl libsodium iproute2 patch screen wireless-tools axel
else
	sudo apt install wget git psmisc libncurses5-dev unzip libffi-dev make gcc g++ \
		ncurses-dev avrdude gcc-avr binutils-avr \
		python-virtualenv python3 python3-virtualenv \
		python3-dev libfribidi-dev libncurses-dev libcurl4-nss-dev libharfbuzz-dev libjpeg-dev liblcms2-dev libopenjp2-7-dev tcl-dev libtiff-dev tk-dev zlib1g-dev \
		jq udev libssl-dev curl libsodium-dev iproute2 patch screen
fi

################################################################################
# KLIPPER
################################################################################
printf "${COL}install KLIPPER%s\n${NC}"
read -p "Would you like compile klipper on the phone?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	if [ "$DISTRO" == "alpine" ]; then
		if [ "$($DISTRO_VERSION | cut -d. -f2)" -gt 15 ]; then
			export PYTHON_BASE="$HOME/python"
			mkdir -p "$PYTHON_BASE"
			axel https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
			tar -zxf Python-2.7.18.tgz
			rm Python-2.7.18.tgz
			cd Python-2.7.18 || exit
			./configure --prefix="$PYTHON_BASE"/python-2.7.18 --enable-shared --enable-unicode=ucs4 LDFLAGS="-Wl,-rpath=$PYTHON_PREFIX/lib"
			make "$MAKEFLAGS"
			make install
			cd "$HOME"||exit
			rm -rf Python-2.7.18
			"$PYTHON_BASE"/python-2.7.18/bin/python -m ensurepip
			"$PYTHON_BASE"/python-2.7.10/bin/pip install --upgrade setuptools pip
			sudo apk add avr-libc gcc-arm-none-eabi newlib-arm-none-eabi
		else

			sudo apk add avr-libc gcc-arm-none-eabi newlib-arm-none-eabi python2
		fi

	else
		sudo apt install avr-libc gcc-arm-none-eabi libnewlib-arm-none-eabi python2
	fi
fi
mkdir -p "$CONFIG_PATH" "$GCODE_PATH"
touch /tmp/klippy_uds
test -d "$KLIPPER_PATH " || git clone "$KLIPPER_REPO" "$KLIPPER_PATH"
test -d "$KLIPPY_VENV_PATH" || virtualenv -p python3 "$KLIPPY_VENV_PATH"
chmod +x "$KLIPPY_VENV_PATH"/bin/activate
"$KLIPPY_VENV_PATH"/bin/activate
"$KLIPPY_VENV_PATH"/bin/pip install --upgrade pip
"$KLIPPY_VENV_PATH"/bin/pip install -r "$KLIPPER_PATH"/scripts/klippy-requirements.txt
cat >"$CONFIG_PATH"/printer.cfg <<EOF
# replace with your config
EOF
if ! grep -q 'virtual_sdcard' "$CONFIG_PATH"/printer.cfg; then
	read -p "Would you like to use virtual card?[y/n]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		cat >>"$CONFIG_PATH"/printer.cfg <<EOL
[virtual_sdcard]
path: $GCODE_PATH
EOL
	fi
fi

if ! grep -q 'display_status' "$CONFIG_PATH"/printer.cfg; then
	read -p "Would you like to add Display status in GUI?[y/n]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		cat >>"$CONFIG_PATH"/printer.cfg <<EOL
[display_status]
EOL
	fi
fi

if ! grep -q 'gcode_macro PAUSE' "$CONFIG_PATH"/printer.cfg; then
	read -p "Would you like to  add pause and resume?[y/n]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		cat >>"$CONFIG_PATH"/printer.cfg <<EOL
[pause_resume]
[gcode_macro PAUSE]
description: Pause the actual running print
rename_existing: PAUSE_BASE
# change this if you need more or less extrusion
variable_extrude: 1.0
gcode:
  ##### read E from pause macro #####
  {% set E = printer["gcode_macro PAUSE"].extrude|float %}
  ##### set park positon for x and y #####
  # default is your max posion from your printer.cfg
  {% set x_park = printer.toolhead.axis_maximum.x|float - 5.0 %}
  {% set y_park = printer.toolhead.axis_maximum.y|float - 5.0 %}
  ##### calculate save lift position #####
  {% set max_z = printer.toolhead.axis_maximum.z|float %}
  {% set act_z = printer.toolhead.position.z|float %}
  {% if act_z < (max_z - 2.0) %}
      {% set z_safe = 2.0 %}
  {% else %}
      {% set z_safe = max_z - act_z %}
  {% endif %}
  ##### end of definitions #####
  PAUSE_BASE
  G91
  {% if printer.extruder.can_extrude|lower == 'true' %}
    G1 E-{E} F2100
  {% else %}
    {action_respond_info("Extruder not hot enough")}
  {% endif %}
  {% if "xyz" in printer.toolhead.homed_axes %}
    G1 Z{z_safe} F900
    G90
    G1 X{x_park} Y{y_park} F6000
  {% else %}
    {action_respond_info("Printer not homed")}
  {% endif %}
EOL
	fi
fi

if ! grep -q 'gcode_macro CANCEL_PRINT' "$CONFIG_PATH"/printer.cfg; then
	read -p "Would you like to add cancel macro?[y/n]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		cat >>"$CONFIG_PATH"/printer.cfg <<EOL
[gcode_macro CANCEL_PRINT]
description: Cancel the actual running print
rename_existing: CANCEL_PRINT_BASE
gcode:
  TURN_OFF_HEATERS
  CANCEL_PRINT_BASE
EOL
	fi
fi
if ! grep -q adxl "$CONFIG_PATH"/printer.cfg; then
	read -p "Would you like to use accelerometer?[y/n](it took long time)" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		if [ "$DISTRO" == "alpine" ]; then
			sudo apk add gfortran blas-dev lapack-dev py3-matplotlib py3-numpy
		else
			sudo apt install libblas-dev liblapack-dev python3-numpy python3-matplotlib
		fi

		"$KLIPPY_VENV_PATH"/bin/activate
		"$KLIPPY_VENV_PATH"/bin/pip install numpi
		cat >>"$CONFIG_PATH"/printer.cfg <<EOL
[include adxl.cfg]
EOL
		cat >>"$CONFIG_PATH"/adxl.cfg <<EOL
[mcu adxl]
serial: /dev/ACM0 #PUT SERIAL DEVICE HERE!!

[adxl345]
cs_pin: adxl:gpio1
spi_bus: spi0a
axes_map: x,z,y

[resonance_tester]
accel_chip: adxl345
probe_points:
    150,150, 20  # middle of bed as an example
##
EOL
	fi
fi

################################################################################
# MOONRAKER
################################################################################
printf "${COL}install MOONRAKER%s\n${NC}"
test -d "$MOONRAKER_PATH" || git clone "$MOONRAKER_REPO" "$MOONRAKER_PATH"
test -d "$MOONRAKER_VENV_PATH" || virtualenv -p python3 "$MOONRAKER_VENV_PATH"
chmod +x "$MOONRAKER_VENV_PATH"/bin/activate
"$MOONRAKER_VENV_PATH"/bin/activate
"$MOONRAKER_VENV_PATH"/bin/pip install --upgrade pip
"$MOONRAKER_VENV_PATH"/bin/pip install -r "$MOONRAKER_PATH"/scripts/moonraker-requirements.txt
read -p "choose GUI fluidd(1) or  mainsail(2)" -r CLIENT
case $CLIENT in
1 | fluidd)
	CLIENT="fluidd"
	CLIENT_RELEASE_URL=$(curl -sL https://api.github.com/repos/cadriel/fluidd/releases | jq -r ".[0].assets[0].browser_download_url")
	;;
2 | mainsail)
	CLIENT="mainsail"
	CLIENT_RELEASE_URL=$(curl -sL https://api.github.com/repos/meteyou/mainsail/releases | jq -r ".[0].assets[0].browser_download_url")
	;;
*)
	echo "Unknown client $CLIENT (choose fluidd or mainsail)"
	exit 2
	;;
esac
test -d "$CLIENT_PATH" && rm -rf "$CLIENT_PATH"
mkdir -p "$CLIENT_PATH"
(cd "$CLIENT_PATH" && wget -q -O $CLIENT.zip "$CLIENT_RELEASE_URL" && unzip $CLIENT.zip && rm $CLIENT.zip)
read -p 'set trust ip [192.168.0.0/24 ip2 ]: ' -r TRUSTIP
if [ -z "$TRUSTIP" ]; then
	TRUSTIP="192.168.0.0/24"
fi
if [[ $TRUSTIP == *" "* ]]; then
	TRUSTIP=$(echo "$TRUSTIP" | tr ' ' '\n')
fi
cat >"$HOME"/moonraker.conf <<EOF
[server]
host: 0.0.0.0
[authorization]
trusted_clients:
  $TRUSTIP
[octoprint_compat]
[update_manager]
enable_system_updates: False
[file_manager]
config_path: $CONFIG_PATH
EOF

if [ "$CLIENT" = "fluidd" ]; then
	cat >>"$HOME"/moonraker.conf <<EOL
[update_manager client fluidd]
type: web
repo: cadriel/fluidd
path: ~/www
EOL
else
	cat >>"$HOME"/moonraker.conf <<EOL
[update_manager client mainsail]
type: web
repo: mainsail-crew/mainsail
path: ~/www
EOL
fi
read -p "Would you like to add domains?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	read -p '[domain1 domain2 domain3]: ' -r DOMAINS
	if [[ $DOMAINS == *" "* ]]; then
		DOMAINS=$(echo "$DOMAINS" | tr ' ' '\n')
	fi
	cat >>"$HOME"/moonraker.conf <<EOL
cors_domains:
$DOMAINS
EOL
fi
################################################################################
# MAINSAIL/FLUIDD
################################################################################
printf "${COL}install NGINX%s\n${NC}"

if [ "$DISTRO" == "alpine" ]; then
	sudo apk add nginx
else
	sudo apt install nginx
	sudo touch /var/log/nginx/error.log && sudo chown -R "$USER":"$USER" /var/log/nginx/error.log
	sudo touch /var/log/nginx/logs/access.log && sudo chown -R "$USER":"$USER" /var/log/nginx/access.log
fi
CLIENT=$(echo "$CLIENT" | tr '[:upper:]' '[:lower:]')
sudo touch /var/log/nginx/"$CLIENT"-access.log && sudo chown -R "$USER":"$USER" /var/log/nginx/"$CLIENT"-access.log
sudo touch /var/log/nginx/"$CLIENT"-error.log && sudo chown -R "$USER":"$USER" /var/log/nginx/"$CLIENT"-error.log
sudo touch /var/run/nginx.pid && sudo chown -R "$USER":"$USER" /var/run/nginx.pid
sudo touch /var/lib/nginx/logs/error.log && sudo chown -R "$USER":"$USER" /var/lib/nginx/logs/error.log
sudo touch /var/lib/nginx/logs/access.log && sudo chown -R "$USER":"$USER" /var/lib/nginx/logs/access.log
sudo chown -R "$USER":"$USER" /var/lib/nginx
sudo tee /etc/nginx/http.d/default.conf <<EOF
server {
    listen 8085 default_server;

    access_log /var/log/nginx/$CLIENT-access.log;
    error_log /var/log/nginx/$CLIENT-error.log;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_proxied expired no-cache no-store private auth;
    gzip_comp_level 4;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/x-javascript application/json application/xml;

    # web_path from mainsail static files
    root $HOME/www;

    index index.html;
    server_name _;

    # disable max upload size checks
    client_max_body_size 0;

    # disable proxy request buffering
    proxy_request_buffering off;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location = /index.html {
        add_header Cache-Control "no-store, no-cache, must-revalidate";
    }

    location /websocket {
        proxy_pass http://apiserver/websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }

    location ~ ^/(printer|api|access|machine|server)/ {
        proxy_pass http://apiserver\$request_uri;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Scheme \$scheme;
    }

    location /webcam/ {
        proxy_pass http://mjpgstreamer1/;
    }

    location /webcam2/ {
        proxy_pass http://mjpgstreamer2/;
    }

    location /webcam3/ {
        proxy_pass http://mjpgstreamer3/;
    }

    location /webcam4/ {
        proxy_pass http://mjpgstreamer4/;
    }
}
EOF
if [ "$DISTRO" == "alpine" ]; then
	if ! grep -q mjpgstreamer1 /etc/nginx/nginx.conf; then
		sudo sed -i 's/user nginx;//g' /etc/nginx/nginx.conf

		sudo sed -i "/^http.*/a \
upstream apiserver {\
    ip_hash;\
    server ""$IP"":7125;\
}\
\
upstream mjpgstreamer1 {\
    ip_hash;\
    server ""$IP"":8080;\
}\
\
upstream mjpgstreamer2 {\
    ip_hash;\
    server ""$IP"":8081;\
}\
\
upstream mjpgstreamer3 {\
    ip_hash;\
    server ""$IP"":8082;\
}\
\
upstream mjpgstreamer4 {\
    ip_hash;\
    server ""$IP"":8083;\
}" /etc/nginx/nginx.conf
		echo "pid        /var/run/nginx.pid;" | sudo tee -a /etc/nginx/nginx.conf
	fi
else
	sudo tee /etc/nginx/conf.d/upstreams.conf <<EOF
upstream apiserver {
    ip_hash;
    server $IP:7125;
}

upstream mjpgstreamer1 {
    ip_hash;
    server $IP:8080;
}

upstream mjpgstreamer2 {
    ip_hash;
    server $IP:8081;
}

upstream mjpgstreamer3 {
    ip_hash;
    server $IP:8082;
}

upstream mjpgstreamer4 {
    ip_hash;
    server $IP:8083;
}
EOF
	if ! grep -q mjpgstreamer1 /etc/nginx/nginx.conf; then
		sudo sed -i 's/user www-data;//g' /etc/nginx/nginx.conf
		sudo sed -i 's/pid /run/nginx.pid;//g' /etc/nginx/nginx.conf
		echo "pid        /var/run/nginx.pid;" | sudo tee -a /etc/nginx/nginx.conf
	fi
fi

###obico(TheSpaghettiDetective)
if wget --spider "$IP":8080/video 2>/dev/null || wget --spider "$IP":8080/video/mjpeg 2>/dev/null; then
	read -p "Would you like to use obico(SpaghettiDetective)[y/n]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		[ ! -d "$HOME/moonraker-obico" ] && git clone https://github.com/TheSpaghettiDetective/moonraker-obico.git
		"$MOONRAKER_VENV_PATH"/bin/pip install -r moonraker-obico/requirements.txt
		[ ! -d "$HOME/klipper_logs" ] && mkdir ~/klipper_logs
		cp -r moonraker-obico/moonraker_obico "$MOONRAKER_VENV_PATH"/lib/python3.9/site-packages
		cp moonraker-obico/moonraker-obico.cfg.sample "${OBICO_CFG_FILE}"
		echo -e "Now tell us what Obico Server you want to link your printer to."
		echo -e "You can use a self-hosted Obico Server or the Obico Cloud. For more information, please visit: https://obico.io\n"
		read -p "The Obico Server (Don't change unless you are linking to a self-hosted Obico Server): " -e -i "${OBICO_SERVER}" -r SERVER_ADDRES
		[[ -n $SERVER_ADDRES ]] && sed -i "s|https://app.obico.io|$SERVER_ADDRES|g" "$OBICO_CFG_FILE"
		CURRENT_URL=$(grep -w url "$OBICO_CFG_FILE" | cut -d" " -f3)
		read -rp "Enter your 6 digt code: " CODE
		AUTH_TOKEN=$(curl --location --request POST "${CURRENT_URL}"/api/v1/octo/verify/?code="$CODE" | jq -r .printer.auth_token)
		sed -i "s|# auth_token: <let the link command set this, see more in readme>|auth_token: $AUTH_TOKEN|g" "$OBICO_CFG_FILE"
		sed -i "s|127.0.0.1|$IP|g" "$OBICO_CFG_FILE"
		sed -i "s|pi|$USER|g" "$OBICO_CFG_FILE"
		if wget --spider "$IP":8080/jpeg 2>/dev/null; then
			sed -i "s|# snapshot_url.*|snapshot_url = http://$IP:8080/jpeg|g" "$OBICO_CFG_FILE"
			sed -i "s|# stream_url.*|stream_url = http://$IP:8080/video/mjpeg|g" "$OBICO_CFG_FILE"
		else
			sed -i "s|# snapshot_url.*|snapshot_url = http://$IP:8080/webcam/shot.jpg|g" "$OBICO_CFG_FILE"
			sed -i "s|# stream_url.*|stream_url = http://$IP:8080/webcam/video|g" "$OBICO_CFG_FILE"
		fi
		FOUND=$(grep -c "moonraker-obico" -F "$HOME"/start.sh)
		if [ "$FOUND" -eq 0 ]; then
			echo "cd $HOME/moonraker_obico" >>"$HOME"/start.sh
			echo "screen -d -m -S moonraker-obico ""$HOME""/venv/moonraker/bin/python -m moonraker_obico.app -c ${OBICO_CFG_FILE}" >>"$HOME"/start.sh
		fi
	fi
fi

chmod +x start.sh
sh start.sh
