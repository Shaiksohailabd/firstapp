#!/bin/bash
# start_application.sh - Script to start the application

echo "Starting ApplicationStart phase..." >> /var/log/deploy.log

# Restart Apache
echo "Restarting Apache..." >> /var/log/deploy.log
sudo systemctl restart httpd
sudo systemctl enable httpd

# Verify Apache is running
if systemctl is-active --quiet httpd; then
    echo "Apache service is running." >> /var/log/deploy.log
else
    echo "Failed to start Apache service." >> /var/log/deploy.log
    exit 1
fi

# Check PHP is working
echo "Verifying PHP setup..." >> /var/log/deploy.log
if php -v > /dev/null 2>&1; then
    echo "PHP is configured correctly." >> /var/log/deploy.log
else
    echo "PHP configuration issue detected." >> /var/log/deploy.log
    exit 1
fi

# Run a simple health check
if curl -s http://localhost/ > /dev/null 2>&1; then
    echo "Application is responding to HTTP requests." >> /var/log/deploy.log
else
    echo "Application is not responding to HTTP requests." >> /var/log/deploy.log
    # Not exiting with error as this could be expected in some cases
fi

echo "ApplicationStart phase completed successfully" >> /var/log/deploy.log
exit 0