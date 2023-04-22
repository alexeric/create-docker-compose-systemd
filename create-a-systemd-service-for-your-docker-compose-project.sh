#!/bin/bash
SERVICENAME=$(basename $(pwd))

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
ExecStop=$(which docker-compose) down

ExecReload=$(which docker-compose) pull --quiet
ExecReload=$(which docker-compose) up -d

[Install]
WantedBy=multi-user.target
EOF

echo "Creating systemd reload eervice... /etc/systemd/system/${SERVICENAME}-reload.service"
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
OnCalendar=*-*-* 5:00:00

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

