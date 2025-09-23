#!/bin/bash
# Simple setup script for demo
sudo apt-get update -y
sudo apt-get install -y apache2
echo "<h1>Apache installed via File Provisioner</h1>" | sudo tee /var/www/html/index.html
sudo systemctl enable apache2
sudo systemctl restart apache2