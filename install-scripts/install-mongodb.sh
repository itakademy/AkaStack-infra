#!/bin/bash
source /var/www/infra/install-scripts/common.sh

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
sed -i 's/^  bindIp:.*$/  bindIp: 127.0.0.1/' /etc/mongod.conf &> /dev/null 2>&1
systemctl daemon-reexec &> /dev/null 2>&1
systemctl enable mongod &> /dev/null 2>&1
systemctl restart mongod &> /dev/null 2>&1
ok "✅ MongoDb installé avec succès.\n"

# ----------------------------
# Mongo Express
# ----------------------------
info "📦 Installation de Mongo Express..."
SERVICE_FILE="/etc/systemd/system/mongo-express.service"
APP_DIR="/opt/mongo-express"

sudo rm -rf "$APP_DIR"
sudo git clone https://github.com/mongo-express/mongo-express.git "$APP_DIR" &> /dev/null 2>&1
cd "$APP_DIR"
sudo npm install &> /dev/null 2>&1

sudo sed -i 's/8081/8082/g' /opt/mongo-express/config.default.js
sudo sed -i "/site:[[:space:]]*{/a\ \ \ \ sessionSecret: \"AkaStackSuperSecret\"," /opt/mongo-express/config.default.js

info "▶ Configuration de Mongo Express"

sudo tee /opt/mongo-express/config.cjs > /dev/null  <<EOF
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

sudo tee /opt/mongo-express/config.js > /dev/null <<EOF
import cfg from './config.cjs';
export default cfg;
EOF

info "▶ Création du service systemd "

sudo tee "$SERVICE_FILE" > /dev/null  <<EOF
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
    SSLCertificateFile /etc/apache2/ssl/wildcard.local.pem
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

ok "✔ Mongo Express est installé"
info "→  URL: https://mongo.${VM_DOMAIN}"
