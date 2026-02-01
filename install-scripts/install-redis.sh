#!/bin/bash
source /var/www/infra/install-scripts/common.sh

# ----------------------------
# Redis
# ----------------------------

if is_pkg_installed redis-server; then
  info "🔍 Redis est déjà installé…"
  exit 0
else

  REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
  REDIS_PORT="${REDIS_PORT:-6379}"
  REDIS_PASSWORD="${REDIS_PASSWORD:-}"

  info "📦 Installation de Redis..."
  sudo apt-get install -y --no-install-recommends redis-server &> /dev/null 2>&1
  sudo sed -ri 's/supervised no/supervised systemd/g' /etc/redis/redis.conf &> /dev/null 2>&1

  # Apply env-driven config
  sudo sed -ri "s/^bind .*/bind ${REDIS_HOST}/" /etc/redis/redis.conf &> /dev/null 2>&1 || true
  sudo sed -ri "s/^port .*/port ${REDIS_PORT}/" /etc/redis/redis.conf &> /dev/null 2>&1 || true

  if [ -n "$REDIS_PASSWORD" ]; then
    if grep -qE '^#?\s*requirepass ' /etc/redis/redis.conf; then
      sudo sed -ri "s/^#?\s*requirepass .*/requirepass ${REDIS_PASSWORD}/" /etc/redis/redis.conf &> /dev/null 2>&1
    else
      echo "requirepass ${REDIS_PASSWORD}" | sudo tee -a /etc/redis/redis.conf > /dev/null
    fi
  else
    sudo sed -ri "s/^#?\s*requirepass .*/# requirepass/" /etc/redis/redis.conf &> /dev/null 2>&1 || true
  fi

  sudo systemctl enable redis-server.service  &> /dev/null 2>&1
  sudo systemctl restart redis-server.service  &> /dev/null 2>&1
  ok "✅ Redis installé avec succès (host: ${REDIS_HOST}, port: ${REDIS_PORT}).\n"
fi

# --------------------------------------
# Install redis-commander (global)
# --------------------------------------
if command -v redis-commander >/dev/null 2>&1; then

  info "🔍 Redis Commander est déjà installé…"
  exit 0

else

  info "📦 Installation de Redis Commander"
  npm install -g redis-commander

  SERVICE_FILE="/etc/systemd/system/redis-commander.service"

  if [ ! -f "$SERVICE_FILE" ]; then
    info "Création du service systemd"

    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Redis Commander
After=network.target redis-server.service
Requires=redis-server.service

[Service]
ExecStart=/usr/bin/redis-commander \
  --redis-host ${REDIS_HOST} \
  --redis-port ${REDIS_PORT} ${REDIS_AUTH_FLAG} \
  --port 8081 \
  --no-open
Restart=always
User=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
  else
    info "Le service systemd existe déjà"
  fi

  systemctl daemon-reexec
  systemctl daemon-reload
  systemctl enable redis-commander
  systemctl restart redis-commander

  sudo tee /etc/apache2/sites-available/800-redis-commander.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName redis.${VM_DOMAIN}
    Redirect permanent / https://redis.${VM_DOMAIN}/
</VirtualHost>
EOF

  sudo tee /etc/apache2/sites-available/800-redis-commander-ssl.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName redis.${VM_DOMAIN}

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/wildcard.local.pem
    SSLCertificateKeyFile /etc/apache2/ssl/wildcard.local-key.pem

    ProxyPreserveHost On
    ProxyPass        / http://127.0.0.1:8081/
    ProxyPassReverse / http://127.0.0.1:8081/

    <Location />
        Require ip 127.0.0.1 192.168.56.0/24
    </Location>
</VirtualHost>
EOF

  sudo a2ensite 800-redis-commander
  sudo a2ensite 800-redis-commander-ssl
  sudo systemctl reload apache2
  ok "✅ Redis Commander installé avec succès.\n"
fi