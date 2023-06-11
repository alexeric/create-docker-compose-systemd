#!/bin/bash
SERVICENAME=$(basename $(pwd))

EXECUTIONTIME="05:00:00"

while getopts 't:h' opt; do
  case "$opt" in
    t)
      arg="$OPTARG"
      echo "Processing option 't' with '${OPTARG}' argument"
      EXECUTIONTIME=${OPTARG}
      ;;

    ?|h)
      echo "Usage: $(basename $0) [-t hh:mm:ss]"
      exit 1
      ;;
    *)
      echo "No parameter given using EXECUTIONTIME='${EXECUTIONTIME}'"
      ;;
  esac
done
shift "$(($OPTIND -1))"

echo "Creating systemd service... /etc/systemd/system/${SERVICENAME}.service"
# Create systemd service file
sudo cat >/etc/systemd/system/$SERVICENAME.service <<EOF
[Unit]
Description=$SERVICENAME
Requires=docker.service
After=docker.service

[Service]
Restart=always
User=root
Group=docker
TimeoutSec=300
WorkingDirectory=$(pwd)
# Shutdown container (if running) when unit is started
ExecStartPre=$(which docker-compose) down

# Start container when unit is started
ExecStart=$(which docker-compose) up

# Stop container when unit is stopped
ExecStop=$(which docker-compose) down --remove-orphans

ExecReload=$(which docker-compose) pull --quiet \
           $(which docker-compose) up -d --remove-orphans

[Install]
TimeoutSec=360
WantedBy=multi-user.target
EOF

echo "Creating systemd reload service... /etc/systemd/system/${SERVICENAME}-reload.service"
# Create systemd service file
sudo cat >/etc/systemd/system/$SERVICENAME-reload.service <<EOF

[Unit]
Description=Refresh images and update containers

[Service]
Type=oneshot

ExecStart=/bin/systemctl reload-or-restart $SERVICENAME.service

[Install]
WantedBy=multi-user.target
EOF

echo "Creating systemd service... /etc/systemd/system/${SERVICENAME}-reload.timer"
# Create systemd service file
sudo cat >/etc/systemd/system/$SERVICENAME-reload.timer <<EOF
[Unit]
Description=Refresh images and update containers
Requires=$SERVICENAME.service
After=$SERVICENAME.service

[Timer]
OnCalendar=*-*-* $EXECUTIONTIME

[Install]
WantedBy=timers.target
EOF


echo "Enabling & starting $SERVICENAME"
# Autostart systemd service
sudo systemctl enable $SERVICENAME.service
# Start systemd service now
sudo systemctl start $SERVICENAME.service
sudo systemctl enable $SERVICENAME-reload.service
sudo systemctl enable $SERVICENAME-reload.timer
sudo systemctl daemon-reload
sudo systemctl restart $SERVICENAME-reload.timer

