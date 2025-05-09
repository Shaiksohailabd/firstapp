#!/bin/bash
# before_install.sh - Script to run before files are installed

echo "Starting BeforeInstall phase..." >> /var/log/deploy.log

# Stop Apache if it's running
if systemctl is-active --quiet httpd; then
    echo "Stopping Apache..." >> /var/log/deploy.log
    sudo systemctl stop httpd
fi

# Ensure Apache is installed
echo "Installing Apache..." >> /var/log/deploy.log
sudo dnf install -y httpd php php-cli php-common php-curl php-mbstring php-xml php-zip php-pdo php-mysqlnd php-gd

# Create deployment directory if it doesn't exist
echo "Setting up deployment directory..." >> /var/log/deploy.log
sudo mkdir -p /var/www/html/php-app

# Clear existing files if directory exists
echo "Cleaning deployment directory..." >> /var/log/deploy.log
sudo rm -rf /var/www/html/php-app/*

echo "BeforeInstall phase completed" >> /var/log/deploy.log
exit 0