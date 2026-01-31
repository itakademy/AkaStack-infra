#!/bin/bash
source /var/www/infra/install-scripts/common.sh

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
sudo tee /var/www/infra/extras/phpinfo.php > /dev/null <<'EOF'
<?php
phpinfo();
EOF
sudo chmod 644 /var/www/infra/extras/phpinfo.php
sudo tee /etc/apache2/conf-available/phpinfo.conf > /dev/null <<'EOF'
Alias /phpinfo /var/www/infra/extras/phpinfo.php

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
echo ""

# ----------------------------
# Composer + docs renderer
# ----------------------------
info "📦 Installation de Composer..."
export COMPOSER_ALLOW_SUPERUSER=1
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" &> /dev/null 2>&1
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer  &> /dev/null 2>&1
sudo php -r "unlink('composer-setup.php');" &> /dev/null 2>&1
ok "✅ Composer installé avec succès.\n"

sudo chmod a+w /var/www/infra/extras
cd /var/www/infra/extras
composer init \
    --name="project/docs" \
    --description="Project documentation renderer" \
    --type="project" \
    --no-interaction &> /dev/null 2>&1
sudo chmod a+w composer.json
composer require fastvolt/markdown --no-interaction &> /dev/null 2>&1
ok "Composer est installé.\n"

info "📦 Installation de Deployer..."
composer global require deployer/deployer &> /dev/null 2>&1
echo "export PATH=\"$HOME/.composer/vendor/bin:$PATH\"" >> ~/.bashrc
source /home/vagrant/.bashrc
ok "Deployer est installé.\n"