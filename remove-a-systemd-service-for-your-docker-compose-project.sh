#!/bin/bash
SERVICENAME=$(basename $(pwd))

echo "Stopping & Disabling $SERVICENAME"
# Stop systemd service
sudo systemctl stop $SERVICENAME.service
# Disable  systemd service now
sudo systemctl disable $SERVICENAME-reload.timer
sudo systemctl disable $SERVICENAME-reload.service
sudo systemctl disable $SERVICENAME.service


echo "Remove systemd services for $SERVICENAME"
rm /etc/systemd/system/$SERVICENAME.service
rm /etc/systemd/system/$SERVICENAME-reload.service
rm /etc/systemd/system/$SERVICENAME-reload.timer

sudo systemctl daemon-reload
