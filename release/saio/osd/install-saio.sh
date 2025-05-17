#!/bin/bash
# ============================================================
# Super-AIO Installation Script for RetroPie
# ============================================================
#
# This script automates the installation and setup of the
# Super-AIO project on a Raspberry Pi running RetroPie.
#
# Goal:
# - Installs dependencies and configures necessary files.
# - Sets up Super-AIO with correct permissions.
# - Configures a systemd service to ensure `saio-osd.py` runs
#   automatically at boot with a proper CPU priority.
#
# How It Works:
# - Updates the system and installs required dependencies.
# - Clones the Super-AIO repository and sets executable permissions.
# - Copies configuration files to the correct locations.
# - Creates a systemd service for automatic startup.
# - Reboots the system to apply changes.
#
# Prerequisites:
# - A Raspberry Pi running **Debian-based RetroPie (tested on Buster)**.
# - Internet connection for downloading updates and dependencies.
# - Basic Linux permissions (should be run as `pi`).
# - Ensure RetroPie is installed and running correctly before execution.
#
# Usage:
# - Save this script as `setup.sh`.
# - Run it using: `bash setup.sh`
# - After running, the system will reboot, and Super-AIO should start
#   automatically with optimized CPU priority settings.
#
# ============================================================

echo "Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

echo "Installing dependencies..."
sudo apt-get install libpng12-0 -y

echo "Cloning Super-AIO repository..."
git clone https://github.com/geebles/Super-AIO/
cd /home/pi/Super-AIO/release/saio

echo "Installing Python serial package..."
sudo dpkg -i python-serial_2.6-1.1_all.deb

echo "Setting executable permissions..."
sudo chmod +x ../tester/pngview
sudo chmod +x osd/saio-osd
sudo chmod +x rfkill/rfkill
sudo chmod +x flash/flash.sh

echo "Copying configuration files..."
sudo cp asound.conf /etc/
sudo cp config.txt /boot/config.txt
sudo cp config-saio.txt /boot/config-saio.txt

echo "Updating autostart script..."
sudo mv /opt/retropie/configs/all/autostart.sh /opt/retropie/configs/all/autostart_OLD.sh
sudo cp autostart.sh /opt/retropie/configs/all/autostart.sh

echo "Setting up sound configuration..."
echo -e "pcm.!default {\n\ttype hw\n\tcard 1\n}\n\nctl.!default {\n\ttype hw\n\tcard 1\n}" | sudo tee /home/pi/.asoundrc

echo "Creating systemd service for Super-AIO..."
sudo tee /etc/systemd/system/saio.service > /dev/null <<EOF
[Unit]
Description=Super-AIO Service
After=network.target

[Service]
ExecStart=/usr/bin/nice -n 19 /usr/bin/python3 /home/pi/Super-AIO/release/saio/saio-osd.py
Restart=always
User=pi
WorkingDirectory=/home/pi/Super-AIO/release/saio/
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=saio-service
Nice=19

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd and enabling the service..."
sudo systemctl daemon-reload
sudo systemctl enable saio.service
sudo systemctl start saio.service

echo "Checking service status..."
sudo systemctl status saio.service

echo "Rebooting system..."
sudo reboot
