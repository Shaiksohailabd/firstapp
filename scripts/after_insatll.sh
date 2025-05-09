#!/bin/bash
# after_install.sh - Script to run after files are installed

echo "Starting AfterInstall phase..." >> /var/log/deploy.log

# Set ownership for Apache
echo "Setting file ownership..." >> /var/log/deploy.log
sudo chown -R apache:apache /var/www/html/php-app

# Make storage directories writable
echo "Setting storage permissions..." >> /var/log/deploy.log
if [ -d "/var/www/html/php-app/storage" ]; then
    sudo chmod -R 775 /var/www/html/php-app/storage
    echo "Storage permissions set" >> /var/log/deploy.log
else
    echo "Storage directory not found, skipping" >> /var/log/deploy.log
fi

# Install Composer if not already installed
if ! command -v composer &> /dev/null; then
    echo "Installing Composer..." >> /var/log/deploy.log
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

# Install PHP dependencies using Composer
cd /var/www/html/php-app
if [ -f "composer.json" ]; then
    echo "Installing Composer dependencies..." >> /var/log/deploy.log
    sudo composer install --no-interaction --no-dev --optimize-autoloader
    echo "Composer dependencies installed" >> /var/log/deploy.log
else
    echo "No composer.json found, skipping dependency installation" >> /var/log/deploy.log
fi

# Set up environment file if needed
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo "Creating .env file from example..." >> /var/log/deploy.log
    sudo cp .env.example .env
    sudo chown apache:apache .env
    echo ".env file created" >> /var/log/deploy.log
fi

# Run Laravel commands if this is a Laravel app
if [ -f "artisan" ]; then
    echo "Laravel application detected" >> /var/log/deploy.log
    
    # Generate application key if not set
    if grep -q "APP_KEY=SomeRandomString" .env || grep -q "APP_KEY=" .env; then
        echo "Generating application key..." >> /var/log/deploy.log
        sudo -u apache php artisan key:generate
    fi
    
    # Cache configurations
    echo "Caching Laravel configurations..." >> /var/log/deploy.log
    sudo -u apache php artisan config:cache
    sudo -u apache php artisan route:cache
    sudo -u apache php artisan view:cache
    
    # Run migrations if database is configured
    if grep -q "DB_HOST=" .env && ! grep -q "DB_HOST=" .env; then
        echo "Running database migrations..." >> /var/log/deploy.log
        sudo -u apache php artisan migrate --force
    else
        echo "Database not configured, skipping migrations" >> /var/log/deploy.log
    fi
    
    echo "Laravel setup completed" >> /var/log/deploy.log
fi

# Configure Apache virtual host
echo "Configuring Apache virtual host..." >> /var/log/deploy.log
cat > /etc/httpd/conf.d/php-app.conf << 'EOL'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/php-app/public
    
    <Directory /var/www/html/php-app/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog /var/log/httpd/php-app-error.log
    CustomLog /var/log/httpd/php-app-access.log combined
</VirtualHost>
EOL

echo "AfterInstall phase completed" >> /var/log/deploy.log
exit 0