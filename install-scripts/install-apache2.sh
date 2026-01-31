#!/bin/bash
source /var/www/infra/install-scripts/common.sh

# ----------------------------
# Apache
# ----------------------------
info "📦 Installation du serveur web Apache2"
sudo apt-get install -y apache2 &> /dev/null 2>&1
ok "✅ Apache2 installé avec succès.\n"

info "🔧 Configuration d'Apache2"
# Enable required Apache modules
sudo a2enmod rewrite headers expires ssl proxy proxy_fcgi proxy_http &> /dev/null 2>&1
# Define global server name
echo "ServerName ${VM_DOMAIN}" > /etc/apache2/conf-available/servername.conf
sudo a2enconf servername &> /dev/null 2>&1
# Install certificates
sudo mkdir -p /etc/apache2/ssl
sudo cp /var/www/infra/certs/wildcard.local.pem /etc/apache2/ssl/wildcard.local.pem
sudo cp /var/www/infra/certs/wildcard.local-key.pem /etc/apache2/ssl/wildcard.local-key.pem
sudo chmod 600 /etc/apache2/ssl/wildcard.local-key.pem
sudo chmod 644 /etc/apache2/ssl/wildcard.local.pem
# Disable default 000 site and move it at 999
a2dissite 000-default &> /dev/null 2>&1
# Redirect IP-based access to FQDN-based SSL access
sudo tee /etc/apache2/sites-available/999-default.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName ${VM_DOMAIN}
    Redirect permanent / https://${VM_DOMAIN}/
</VirtualHost>
EOF
sudo tee /etc/apache2/sites-available/999-default-ssl.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName ${VM_DOMAIN}
    DocumentRoot /var/www/infra/extras

    <Directory //var/www/infra/extras>
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
    </FilesMatch>

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/wildcard.local.pem
    SSLCertificateKeyFile /etc/apache2/ssl/wildcard.local-key.pem

    ErrorLog /var/www/infra/logs/default_ssl_error.log
    CustomLog /var/www/infra/logs/default_ssl_access.log combined
</VirtualHost>
EOF
a2ensite 999-default &> /dev/null 2>&1
a2ensite 999-default-ssl &> /dev/null 2>&1
sudo rm -rf /etc/apache2/sites-available/000-default.conf
sudo rm -rf /etc/apache2/sites-available/default-ssl.conf
# Create logs dir
sudo mkdir -p /var/www/infra/logs &> /dev/null 2>&1
sudo rm -rf /var/www/html
# Activate required Apache modules and restart
info "🔁 Redémarage du service Apache2..."
sudo systemctl restart apache2 &> /dev/null 2>&1
ok "✅ Apache a redémarré.\n"

info "🔧 Configuration de l'environnement de développement (permissions, inotify, cron jobs)..."
sudo chgrp -R www-data /var/www&> /dev/null 2>&1
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf &> /dev/null 2>&1
sudo sysctl -p &> /dev/null 2>&1
ok "✅ Environnement de développement configuré.\n"