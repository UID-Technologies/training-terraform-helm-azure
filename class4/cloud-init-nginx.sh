#!/bin/bash
# Update system
apt-get update -y

# Install nginx
apt-get install -y nginx

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Replace default index.html with hostname
HOSTNAME=$(hostname)
echo "<h1>Hello from $HOSTNAME</h1>" > /var/www/html/index.html
