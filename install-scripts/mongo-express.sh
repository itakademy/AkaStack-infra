#!/bin/bash
source /var/www/infra/install-scripts/common.sh
echo "======================================"
echo " Installing Mongo Express"
echo "======================================"

SERVICE_FILE="/etc/systemd/system/mongo-express.service"
APP_DIR="/opt/mongo-express"

# --------------------------------------
# Prerequisites
# --------------------------------------
if ! command -v node >/dev/null 2>&1; then
  echo "❌ Node.js is required"
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "❌ npm is required"
  exit 1
fi

if ! command -v mongod >/dev/null 2>&1; then
  echo "❌ MongoDB must be installed first"
  exit 1
fi

sudo rm -rf /opt/mongo-express
sudo git clone https://github.com/mongo-express/mongo-express.git /opt/mongo-express &> /dev/null 2>&1
cd /opt/mongo-express
sudo npm install &> /dev/null 2>&1

sudo sed -i 's/8081/8082/g' /opt/mongo-express/config.default.js
sudo sed -i "/site:[[:space:]]*{/a\ \ \ \ sessionSecret: \"AkaStackSuperSecret\"," /opt/mongo-express/config.default.js

# --------------------------------------
# Configuration
# --------------------------------------
echo "▶ Configuring Mongo Express"

sudo tee /opt/mongo-express/config.cjs &> /dev/null 2>&1  <<EOF
module.exports = {
  mongodb: {
    server: '127.0.0.1',
    port: 27017,
    enableAdmin: true
  },
  site: {
    baseUrl: '/',
    port: 8082,
    sessionSecret: "AkaStackSuperSecret"
  },
  useBasicAuth: false,
  options: {
    readOnly: false
  }
};
EOF

sudo tee /opt/mongo-express/config.js &> /dev/null 2>&1 <<EOF
import cfg from './config.cjs';
export default cfg;
EOF

# --------------------------------------
# systemd service
# --------------------------------------
echo "▶ Creating systemd service"

sudo tee $SERVICE_FILE  &> /dev/null 2>&1 <<EOF
[Unit]
Description=Mongo Express
After=network.target mongod.service

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node /opt/mongo-express/app.js
Restart=always
Environment=NODE_ENV=production
Environment=ME_CONFIG_MONGODB_URL=mongodb://127.0.0.1:27017
Environment=ME_CONFIG_CONFIGFILE=/opt/mongo-express/config.cjs
Environment=ME_CONFIG_SITE_PORT=8082

[Install]
WantedBy=multi-user.target
EOF

# --------------------------------------
# Enable & start
# --------------------------------------
sudo systemctl daemon-reload &> /dev/null 2>&1
sudo systemctl enable mongo-express &> /dev/null 2>&1
sudo systemctl restart mongo-express &> /dev/null 2>&1

sudo tee /etc/apache2/sites-available/600-mongo-express.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName mongo.${VM_DOMAIN}
    Redirect permanent / https://mongo.${VM_DOMAIN}/
</VirtualHost>
EOF

sudo tee /etc/apache2/sites-available/600-mongo-express-ssl.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName mongo.${VM_DOMAIN}

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/wilcard.local.pem
    SSLCertificateKeyFile /etc/apache2/ssl/wildcard.local-key.pem

    ProxyPreserveHost On
    ProxyPass        / http://127.0.0.1:8082/
    ProxyPassReverse / http://127.0.0.1:8082/

    <Location />
        Require ip 127.0.0.1 192.168.56.0/24
    </Location>
</VirtualHost>
EOF

sudo a2ensite 600-mongo-express &> /dev/null 2>&1
sudo a2ensite 600-mongo-express-ssl &> /dev/null 2>&1
sudo systemctl reload apache2 &> /dev/null 2>&1

ok "✔ Mongo Express installed and running"
info "→ Internal URL: https://mongo.${VM_DOMAIN}"
