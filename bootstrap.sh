#!/bin/bash
# Provisioning script – Ubuntu 24.04 LTS

VM_VERSION=$(cat /var/www/VERSION)

export DEBIAN_FRONTEND=noninteractive
echo ""
echo ""
echo "   ___   "
echo "  (o,o)  "
echo " <  .  >  It-Akademy "
echo "  -----  "
echo ""
echo -e "https://www.it-akademy.fr"
echo ""
echo -e "VM $VM_NAME v.$VM_VERSION "
echo ""
echo "+-------------------------------+"
echo "PROVISIONING"
echo ""

info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[ OK ]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERR ]\033[0m $*" >&2; }

is_pkg_installed() {
  # returns 0 if installed, non-zero otherwise
  dpkg-query -Wf'${db:Status-abbrev}' "$1" 2>/dev/null | grep -q '^i'
}

# ----------------------------
# OpenSSH post-install workaround
# ----------------------------
info "🔧 Handling openssh-server post-install script issues..."
if grep -q "half-configured" /var/lib/dpkg/status || ps aux | grep -q "[o]penssh-server.*postinst"; then
  sudo mv /var/lib/dpkg/info/openssh-server.postinst /tmp/openssh-server.postinst.bak &> /dev/null 2>&1 || true
  sudo dpkg --configure -a &> /dev/null 2>&1 || true
fi
sudo apt-get purge -qq -y openssh-server openssh-client &> /dev/null 2>&1 || true
sudo apt-get update -qq &> /dev/null 2>&1
sudo apt-get install -qq -y openssh-server openssh-client &> /dev/null 2>&1 || true

info "✅ Workaround to prevent post-install problems with openssh-server applied."
if sudo systemctl is-active ssh &> /dev/null 2>&1; then
  ok "✅ Openssh-server has been installed and started successfully.\n"
else
  warn "⚠️ SSH service appears inactive, trying to restart...\n"
  sudo systemctl restart ssh /dev/null 2>&1 || true
fi

# --- Test de connexion GitHub ---
# On capture la sortie pour éviter que le message de GitHub ne pollue le terminal
info "🔗 Test de connexion à GitHub..."
ssh_output=$(ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1)

if echo "$ssh_output" | grep -q "successfully authenticated"; then
    ok "✅ Authentification GitHub réussie."
else
    err "❌ Échec de l'authentification GitHub."
    echo -e "${ORANGE}Détails du message :${NC}"
    echo "$ssh_output"
    exit 1
fi

# ----------------------------
# System update
# ----------------------------
info "📦 Mise à jour du système.."
sudo apt-get upgrade -y -qq &> /dev/null 2>&1
ok "✅ Système mis à jour avec succès.\n"

# ----------------------------
# System utilities
# ----------------------------
info "📦 Installation des utilitaires système..."
sudo apt-get install -y --no-install-recommends build-essential libssl-dev git curl wget zip unzip git-core ca-certificates apt-transport-https locate software-properties-common dirmngr &> /dev/null 2>&1
ok -e "✅ Utilitaires système installés avec succès.\n"

# ----------------------------
# Apache
# ----------------------------
info "📦 Installation du serveur web Apache2"
sudo apt-get install -y apache2 &> /dev/null 2>&1
ok "✅ Apache2 installé avec succès.\n"
info "🔧 Configuration d'Apache2"
# Enable required Apache modules
sudo a2enmod rewrite headers expires &> /dev/null 2>&1
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
    DocumentRoot /var/www/html

    <Directory /var/www/html>
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
# Map extras content to /var/www/html
sudo rm -rf /var/www/html
sudo ln -s /var/www/infra/extras /var/www/html
# Activate required Apache modules and restart
info "🔁 Redémarage du service Apache2..."
sudo a2enmod ssl proxy proxy_fcgi proxy_http &> /dev/null 2>&1
sudo systemctl restart apache2 &> /dev/null 2>&1
ok "✅ Apache a redémarré.\n"

# ----------------------------
# MariaDB
# ----------------------------
info "📦 Installation de MariaDB..."
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get install -y mariadb-server &> /dev/null 2>&1
ok "✅ MariaDB installé avec succès.\n"
sudo mysql <<EOF
ALTER USER 'root'@'localhost'
IDENTIFIED VIA mysql_native_password
USING PASSWORD('$MYSQL_ROOT_PASSWORD');
FLUSH PRIVILEGES;
EOF
info "🔑 Le mot de passe root de MariaDb est : $MYSQL_ROOT_PASSWORD\n"

# ----------------------------
# Redis
# ----------------------------
info "📦 Installation de Redis..."
sudo apt-get install -y --no-install-recommends redis-server &> /dev/null 2>&1
sudo sed -ri 's/supervised no/supervised systemd/g' /etc/redis/redis.conf &> /dev/null 2>&1
sudo systemctl enable redis-server.service  &> /dev/null 2>&1
ok "✅ Redis installé avec succès.\n"

# ----------------------------
# PHP 8.4 (FPM)
# ----------------------------
info "📦 Installation de PHP 8.4 (FPM)..."
sudo add-apt-repository ppa:ondrej/php -y &> /dev/null 2>&1
sudo apt-get update -qq &> /dev/null 2>&1
sudo apt-get upgrade -y -qq &> /dev/null 2>&1
sudo apt-get install -y --no-install-recommends \
  php8.4-fpm \
  php8.4-cli \
  php8.4-dev \
  php8.4-common \
  php8.4-mysql \
  php8.4-sqlite3 \
  php8.4-mbstring \
  php8.4-intl \
  php8.4-gd \
  php8.4-dom \
  php8.4-opcache \
  php8.4-ssh2 \
  php8.4-rrd \
  php8.4-yaml \
  php8.4-apcu \
  php8.4-memcached \
  php8.4-curl \
  php8.4-zip \
  php8.4-xml \
  php8.4-phpdbg \
  php-redis \
  &> /dev/null 2>&1
sudo a2dismod php8.4 &> /dev/null || true
sudo a2dismod php8.3 &> /dev/null || true
sudo a2enconf php8.4-fpm &> /dev/null
sudo update-alternatives --set php /usr/bin/php8.4 &> /dev/null 2>&1
sudo update-alternatives --set phar /usr/bin/phar8.4 &> /dev/null 2>&1
sudo update-alternatives --set phar.phar /usr/bin/phar.phar8.4 &> /dev/null 2>&1
sudo systemctl restart php8.4-fpm &> /dev/null 2>&1
sudo systemctl restart apache2 &> /dev/null 2>&1
sudo tee /var/www/html/phpinfo.php > /dev/null <<'EOF'
<?php
phpinfo();
EOF
sudo chmod 644 /var/www/html/phpinfo.php
sudo tee /etc/apache2/conf-available/phpinfo.conf > /dev/null <<'EOF'
Alias /phpinfo /var/www/html/phpinfo.php

<Directory /var/www>
    Require all granted
</Directory>

<FilesMatch phpinfo\.php$>
    SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
</FilesMatch>
EOF
sudo a2enconf phpinfo &> /dev/null 2>&1
sudo systemctl restart apache2 &> /dev/null 2>&1
ok "✅ PHP 8.4 FPM installé avec succès.\n"

# ----------------------------
# MongoDB
# ----------------------------
info "📦 Installation de MongoDb..."
curl -fsSL https://pgp.mongodb.com/server-${MONGODB_VERSION}.asc \
  | gpg --dearmor -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg &> /dev/null 2>&1
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/${MONGODB_VERSION} multiverse" \
| tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list &> /dev/null 2>&1
apt-get update -y &> /dev/null 2>&1
apt-get install -y mongodb-org &> /dev/null 2>&1
sed -i 's/^  bindIp:.*$/  bindIp: 127.0.0.1/' /etc/mongod.conf
systemctl daemon-reexec &> /dev/null 2>&1
systemctl enable mongod &> /dev/null 2>&1
systemctl restart mongod &> /dev/null 2>&1
ok "✅ MongoDb installé avec succès.\n"

# ----------------------------
# Node.js
# ----------------------------
info "📦 Installation de Node.js..."
curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash - &> /dev/null 2>&1
sudo apt-get install -y --no-install-recommends nodejs &> /dev/null 2>&1
sudo npm install --global npm@latest  &> /dev/null 2>&1
sudo npm install --global yarn  &> /dev/null 2>&1
sudo npm install --global gulp-cli  &> /dev/null 2>&1
sudo npm install --global bower &> /dev/null 2>&1
ok "✅ Node.js, npm, yarn, gulp-cli, et bower ont été installés avec succès.\n"

# ----------------------------
# Composer + docs renderer
# ----------------------------
info "📦 Installation de Composer..."
export COMPOSER_ALLOW_SUPERUSER=1
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" &> /dev/null 2>&1
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer  &> /dev/null 2>&1
sudo php -r "unlink('composer-setup.php');" &> /dev/null 2>&1
ok "✅ Composer installé avec succès.\n"
sudo chmod a+w /var/www/html
cd /var/www/html
composer init \
    --name="project/docs" \
    --description="Project documentation renderer" \
    --type="project" \
    --no-interaction &> /dev/null 2>&1
sudo chmod a+w composer.json
composer require fastvolt/markdown --no-interaction &> /dev/null 2>&1


# ----------------------------
# Development environment
# ----------------------------
info "🔧 Configuration de l'environnement de développement (permissions, inotify, cron jobs)..."
sudo chgrp -R www-data /var/www&> /dev/null 2>&1
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf &> /dev/null 2>&1
sudo sysctl -p &> /dev/null 2>&1
composer global require deployer/deployer &> /dev/null 2>&1
echo "export PATH=\"$HOME/.composer/vendor/bin:$PATH\"" >> ~/.bashrc
source /home/vagrant/.bashrc
ok "✅ Environnement de développement configuré.\n"

info "📦 Installation de GitHub CLI (gh)"

if ! command -v gh >/dev/null 2>&1; then
  sudo apt install -y curl ca-certificates gnupg &> /dev/null 2>&1

  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg &> /dev/null 2>&1

  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &> /dev/null 2>&1

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list &> /dev/null 2>&1

  sudo apt install -y gh &> /dev/null 2>&1

  ok "✔ GitHub CLI installé"
else
  warn "✔ GitHub CLI déjà installé"
fi



# ----------------------------
# Done
# ----------------------------
ok "✅ Provisionnement terminé"
info "✅  Nous sommes prêts ! Rendez-vous dans le navigateur web sur :\n   http://$VM_IP"
info "\n\n🚀 Happy coding!\n\n"
echo "+--------------------------------------------"
