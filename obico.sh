#!/bin/bash                                                         detective.sh
: "${CONFIG_PATH:="$HOME/config"}"
: "${MOONRAKER_VENV_PATH:="$HOME/venv/moonraker"}"
: "${IP:=$(ip route get 8.8.8.8 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | tail -1)}"
: "${OBICO_CFG_FILE:="${CONFIG_PATH}/moonraker-obico.cfg"}"

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
		read -p "Enter your 6 digt code: " CODE
		AUTH_TOKEN=$(curl --location --request POST "${CURRENT_URL}"/api/v1/octo/verify/?code="$CODE" | jq -r .printer.auth_token)
		sed -i "s|# auth_token: <let the link command set this, see more in readme>|auth_token: $AUTH_TOKEN|g" "$OBICO_CFG_FILE"
		sed -i "s|127.0.0.1|$IP|g" "$OBICO_CFG_FILE"
		sed -i "s|pi|$USER|g" "$OBICO_CFG_FILE"
		if wget --spider "$IP":8080/video 2>/dev/null; then
			sed -i "s|# snapshot_url.*|snapshot_url = http://$IP:8080/webcam/shot.jpg|g" "$OBICO_CFG_FILE"
			sed -i "s|# stream_url.*|stream_url = http://$IP:8080/webcam/video|g" "$OBICO_CFG_FILE"
		else
			sed -i "s|# snapshot_url.*|snapshot_url = http://$IP:8080/webcam/jpeg|g" "$OBICO_CFG_FILE"
			sed -i "s|# stream_url.*|stream_url = http://$IP:8080/webcam/video/mjpeg|g" "$OBICO_CFG_FILE"
		fi
		if ! grep -q moonraker-obico "$OBICO_CFG_FILE"; then
			echo "screen -d -m -S moonraker-obico /home/$USER/venv/moonraker/bin/python -m moonraker_obico.app -c ${OBICO_CFG_FILE}" >>~/start.sh
		fi
	fi
fi
