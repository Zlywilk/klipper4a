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
: "${IP=$(ip route get 8.8.8.8 | sed -n 's|^.*src \(.*\)$|\1|gp' |awk '{print $1}')}"

################################################################################
# PRE
################################################################################
printf "${COL}Installing dependencies...\n${NC}"
sudo apk add git unzip  libffi-dev make gcc g++ \
ncurses-dev avrdude gcc-avr binutils-avr \
python3 py3-virtualenv \
python3-dev freetype-dev fribidi-dev harfbuzz-dev jpeg-dev lcms2-dev openjpeg-dev tcl-dev tiff-dev tk-dev zlib-dev \
jq udev curl-dev libressl-dev curl libsodium iproute2 patch


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
read -p "Would you like use virtual card?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
      cat >> "$CONFIG_PATH"/printer.cfg <<EOL
[virtual_sdcard]
path: $GCODE_PATH
EOL
fi
read -p "Would you like use Display status in GUI?[y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
      cat >> "$CONFIG_PATH"/printer.cfg <<EOL
[display_status]
EOL
fi
read -p "Would you like use pause and resume?[y/n]" -n 1 -r
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
read -p "Would you like use add cancel macro?[y/n]" -n 1 -r
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
    curl -sL https://api.github.com/repos/cadriel/fluidd/releases | jq -r ".[0].assets[0].browser_download_url"
    ;;
  2 | mainsail)
  CLIENT="mainsail"
    curl -sL https://api.github.com/repos/meteyou/mainsail/releases | jq -r ".[0].assets[0].browser_download_url"
    ;;
  *)
    echo "Unknown client $CLIENT (choose fluidd or mainsail)"
    exit 2
    ;;
esac

read -p 'set trust ip [192.168.0.0/24 ip2 ]: ' -r TRUSTIP
if  [[ "$TRUSTIP" == *" "* ]]
then
TRUSTIP=$(echo "$TRUSTIP"|tr ' ' '\n')
fi
cat > "$HOME"/moonraker.conf <<EOF
[server]
host: 0.0.0.0
config_path: $CONFIG_PATH
[authorization]
trusted_clients:
  $TRUSTIP
[octoprint_compat]
[update_manager]
enable_system_updates: False
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
read -p "Would you like use add domains?[y/n]" -n 1 -r
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
sudo touch /var/log/nginx/error.log  && sudo chown -R "$USER":"$USER" /var/log/nginx/error.log
sudo tee /etc/nginx/http.d/default.conf <<EOF
server {
    listen 8080;

    access_log /var/log/nginx/"$CLIENT"-access.log;
    error_log /var/log/nginx/"$CLIENT"-error.log;

    # disable this section on smaller hardware like a pi zero
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_proxied expired no-cache no-store private auth;
    gzip_comp_level 4;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/x-javascript application/json application/xml;

    # web_path from <<UI>> static files
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
EOF
sudo iptables -t nat -A OUTPUT -o lo -p tcp --dport 80 -j REDIRECT --to-port 8080

sudo sed -i '/^http.*/a \
map \$http_upgrade \$connection_upgrade { \
    default upgrade; \
    ''      close; \
    } \
upstream apiserver {\
    ip_hash;\
    server $IP:7125;\
}\
\
upstream mjpgstreamer1 {\
    ip_hash;\
    server $IP:8080;\
}\
\
upstream mjpgstreamer2 {\
    ip_hash;\
    server $IP:8081;\
}\
\
upstream mjpgstreamer3 {\
    ip_hash;\
    server $IP:8082;\
}\
\
upstream mjpgstreamer4 {\
    ip_hash;\
    server $IP:8083;\
}' /etc/nginx/nginx.conf
echo "pid        /var/run/nginx.pid;" | sudo tee -a /etc/nginx/nginx.conf

cat > "$HOME"/start.sh <<EOF
#!/bin/sh
OLDIP=\$(cat /etc/nginx/nginx.conf |grep "server " |cut -d ':' -f1 |tail -n1 |awk '{print $2}')
IP=\$(ip route get 8.8.8.8 | sed -n 's|^.*src \(.*\)$|\1|gp' ||awk '{print $1}')
if [\$IP != \$OLDIP] then
sudo sed -i 's/\$OLDIP/\$IP/g' /etc/nginx/nginx.conf
fi
$MOONRAKER_VENV_PATH/bin/python $MOONRAKER_PATH/moonraker/moonraker.py&
$KLIPPY_VENV_PATH/bin/python  $KLIPPER_PATH/klippy/klippy.py $CONFIG_PATH/printer.cfg -l /tmp/klippy.log -a /tmp/klippy_uds&
nginx&
EOF