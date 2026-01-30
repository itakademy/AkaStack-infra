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
info "📦 Installion du serveur web Apache2"
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

    ErrorLog /var/www/stack/logs/default_ssl_error.log
    CustomLog /var/www/stack/logs/default_ssl_access.log combined
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
sudo a2enmod ssl proxy proxy_fcgi proxy_http
sudo systemctl restart apache2 &> /dev/null 2>&1
ok "✅ Apache a redémarré.\n"