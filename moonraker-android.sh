#!/bin/sh
: "${CONFIG_PATH:="$HOME/config"}"
: "${GCODE_PATH:="$HOME/gcode"}"

: "${KLIPPER_REPO:="https://github.com/KevinOConnor/klipper.git"}"
: "${KLIPPER_PATH:="$HOME/klipper"}"
: "${KLIPPY_VENV_PATH:="$HOME/venv/klippy"}"

: "${MOONRAKER_REPO:="https://github.com/Arksine/moonraker"}"
: "${MOONRAKER_PATH:="$HOME/moonraker"}"
: "${MOONRAKER_VENV_PATH:="$HOME/venv/moonraker"}"

: "${CLIENT_PATH:="$HOME/www"}"
: "${IP:=$(ip route get 8.8.8.8 |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |tail -1)}"
: "${BOARDMANUFACTURER:="klipper"}"
sudo apk add 	eudev
findserial() {
for f in /dev/tty*;
do
if [ "$(udevadm info -a -n "${f}" | grep "{manufacturer}" | head -n1|cut -d== -f3|tr -d '"'=="$BOARDMANUFACTURER")" ]
then
SERIAL="$f"
fi
done;
}
findserial
COL='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m'
if [ -e "$SERIAL" ]; then
if [[ $(ls -l "$SERIAL" | awk '{print $4}') = "root" ]]
then
    printf "${COL}fix permissions\n${NC}"
    sudo chown -R "$USER":"$USER" "$SERIAL"
fi
cat > "$HOME"/watchperm.sh <<EOF
#!/bin/sh
: \"\${BOARDMANUFACTURER:=\""$BOARDMANUFACTURER"\"}\"
findserial() {
for f in /dev/tty*;
do
if [ "\$(udevadm info -a -n "\${f}" | grep "{manufacturer}" | head -n1|cut -d== -f3|tr -d '"'=="\$BOARDMANUFACTURER")" ]
then
SERIAL="\$f"
fi
done;
}
findserial
if [[ \$(ls -l "\$SERIAL" | awk '{print \$4}') = "root" ]]
then
    sudo chown -R "\$USER":"\$USER" "\$SERIAL"
fi
EOF
chmod +x watchperm.sh
cat > "$HOME"/start.sh <<EOF
#!/bin/sh
: \"\${BOARDMANUFACTURER:=\""$BOARDMANUFACTURER"\"}\"
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8085
findserial() {
for f in /dev/tty*;
do
if [ "\$(udevadm info -a -n "\${f}" | grep "{manufacturer}" | head -n1|cut -d== -f3|tr -d '"'==\""\$BOARDMANUFACTURER"\")" ]
then
SERIAL="\$f"
fi
done;
}
findserial
OLDSERIAL=\$(cat config/printer.cfg  |grep "serial:" |cut -d":" -f2)
OLDIP=\$(cat /etc/nginx/nginx.conf |grep "server " |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1)
IP=\$(ip route get 8.8.8.8 |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |tail -1)
if [[ "\$OLDIP" != "\$IP" ]]
then
sudo sed -i "s|\$OLDIP|\$IP|g" /etc/nginx/nginx.conf
fi
if [[ "\$SERIAL" != "\$OLDSERIAL" ]]
then
sed -i "s|\$OLDSERIAL|\$SERIAL|g" config/printer.cfg
fi

screen -d -m -S permcheck watch -n 10 "$HOME"/watchperm.sh
screen -d -m -S moonraker /home/android/venv/moonraker/bin/python /home/android/moonraker/moonraker/moonraker.py
screen -d -m -S klippy /home/android/venv/klippy/bin/python  /home/android/klipper/klippy/klippy.py /home/android/config/printer.cfg -l /tmp/klippy.log -a /tmp/klippy_uds
screen -d -m -S nginx nginx

EOF
else
printf "${RED}connect printer and rerun script\n${NC}"
exit
fi
cat > "$HOME"/stop.sh <<EOF
#!/bin/sh
killall screen nginx
EOF
chmod +x stop.sh
################################################################################
# PRE
################################################################################
printf "${COL}Installing dependencies...\n${NC}"
sudo apk add git unzip  libffi-dev make gcc g++ \
ncurses-dev avrdude gcc-avr binutils-avr \
python3 py3-virtualenv \
python3-dev freetype-dev fribidi-dev harfbuzz-dev jpeg-dev lcms2-dev openjpeg-dev tcl-dev tiff-dev tk-dev zlib-dev \
jq udev curl-dev libressl-dev curl libsodium iproute2 patch screen


################################################################################
# KLIPPER
################################################################################
printf "${COL}install KLIPPER\n${NC}"
read -p "Would you like compile klipper on the phone(works only on alpine last)?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
sudo apk add avr-libc gcc-arm-none-eabi newlib-arm-none-eabi python2 openssh
fi
mkdir -p "$CONFIG_PATH" "$GCODE_PATH"
touch /tmp/klippy_uds
test -d "$KLIPPER_PATH "|| git clone "$KLIPPER_REPO" "$KLIPPER_PATH"
test -d "$KLIPPY_VENV_PATH" || virtualenv -p python3 "$KLIPPY_VENV_PATH"
source "$KLIPPY_VENV_PATH"/bin/activate
"$KLIPPY_VENV_PATH"/bin/pip install --upgrade pip
"$KLIPPY_VENV_PATH"/bin/pip install -r "$KLIPPER_PATH"/scripts/klippy-requirements.txt
cat > "$CONFIG_PATH"/printer.cfg <<EOF
# replace with your config
EOF
read -p "Would you like to use virtual card?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
      cat >> "$CONFIG_PATH"/printer.cfg <<EOL
[virtual_sdcard]
path: $GCODE_PATH
EOL
fi
read -p "Would you like to add Display status in GUI?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
      cat >> "$CONFIG_PATH"/printer.cfg <<EOL
[display_status]
EOL
fi
read -p "Would you like to  add pause and resume?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
      cat >> "$CONFIG_PATH"/printer.cfg <<EOL
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
read -p "Would you like to add cancel macro?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
      cat >> "$CONFIG_PATH"/printer.cfg  <<EOL
[gcode_macro CANCEL_PRINT]
description: Cancel the actual running print
rename_existing: CANCEL_PRINT_BASE
gcode:
  TURN_OFF_HEATERS
  CANCEL_PRINT_BASE
EOL
fi
################################################################################
# MOONRAKER
################################################################################
printf "${COL}install MOONRAKER\n${NC}"
test -d "$MOONRAKER_PATH"|| git clone "$MOONRAKER_REPO" "$MOONRAKER_PATH"
test -d "$MOONRAKER_VENV_PATH" || virtualenv -p python3 "$MOONRAKER_VENV_PATH"
source "$MOONRAKER_VENV_PATH"/bin/activate
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
if  [[ "$TRUSTIP" == *" "* ]]
then
TRUSTIP=$(echo "$TRUSTIP"|tr ' ' '\n')
fi
cat > "$HOME"/moonraker.conf <<EOF
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

if [ "$CLIENT" = "fluidd" ]
then
  cat >> "$HOME"/moonraker.conf <<EOL
[update_manager client fluidd]
type: web
repo: cadriel/fluidd
path: ~/www
EOL
else
  cat >> "$HOME"/moonraker.conf <<EOL
[update_manager client mainsail]
type: web
repo: mainsail-crew/mainsail
path: ~/www
EOL
fi
read -p "Would you like to add domains?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
read -p '[domain1 domain2 domain3]: ' -r DOMAINS
if [[ "$DOMAINS" == *" "* ]]
then
DOMAINS=$(echo "$DOMAINS"|tr ' ' '\n')
fi
      cat >> "$HOME"/moonraker.conf <<EOL
cors_domains:
$DOMAINS
EOL
fi
################################################################################
# MAINSAIL/FLUIDD
################################################################################
printf "${COL}install NGINX\n${NC}"
sudo apk add nginx
CLIENT=$(echo "$CLIENT" | tr '[:upper:]' '[:lower:]')
sudo touch /var/log/nginx/"$CLIENT"-access.log && sudo chown -R "$USER":"$USER" /var/log/nginx/"$CLIENT"-access.log
sudo touch /var/log/nginx/"$CLIENT"-error.log && sudo chown -R "$USER":"$USER" /var/log/nginx/"$CLIENT"-error.log
sudo touch /var/run/nginx.pid && sudo chown -R "$USER":"$USER" /var/run/nginx.pid
sudo touch /var/lib/nginx/logs/error.log  && sudo chown -R "$USER":"$USER" /var/lib/nginx/logs/error.log
sudo touch /var/log/nginx/access.log && sudo chown -R "$USER":"$USER" /var/lib/nginx/logs/access.log
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
    root /home/$USER/www;

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

if  ! grep -q mjpgstreamer1 /etc/nginx/nginx.conf;
then
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

chmod +x start.sh
sh start.sh
