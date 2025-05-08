#!/bin/bash
# Script to set up PHP environment for AWS CodeBuild

echo "→ Starting environment setup script"

# Check current system
echo "→ System information:"
cat /etc/os-release
uname -a

# Update system
echo "→ Updating system packages"
yum update -y

# Install basic tools
echo "→ Installing basic tools"
yum install -y wget curl git zip unzip

# Set up PHP repository and install PHP
echo "→ Setting up PHP"
amazon-linux-extras enable php8.0
yum clean metadata
yum install -y php php-common php-pear php-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip}

# Verify PHP installation
echo "→ PHP version:"
php -v

# Install Composer
echo "→ Installing Composer"
EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    echo "ERROR: Invalid Composer installer checksum"
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"
composer --version

# Set up Node.js
echo "→ Setting up Node.js"
if ! command -v node &> /dev/null; then
    curl -sL https://rpm.nodesource.com/setup_16.x | bash -
    yum install -y nodejs
fi

# Verify Node.js installation
echo "→ Node.js version:"
node -v
npm -v

echo "→ Environment setup complete"