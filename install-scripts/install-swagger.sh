#!/bin/bash
source /var/www/infra/install-scripts/common.sh

SWAGGER_DIR="/var/www/swagger"
APACHE_CONF="/etc/apache2/conf-available/swagger.conf"

mkdir -p "$SWAGGER_DIR"
cd "$SWAGGER_DIR"

if [ ! -f "$SWAGGER_DIR/index.html" ]; then
  info "▶ Installation de Swagger UI"
  curl -sL https://github.com/swagger-api/swagger-ui/archive/refs/heads/master.tar.gz \
    | tar xz --strip-components=2 swagger-ui-master/dist
else
  ok "✔ Swagger UI déjà installé"
fi

info "▶ Configuration de Swagger UI"

cat <<EOF > "$SWAGGER_DIR/swagger-config.js"
window.onload = function () {
  window.ui = SwaggerUIBundle({
    url: "/api/docs.json",
    dom_id: "#swagger-ui",
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    layout: "StandaloneLayout"
  });
};
EOF

# Patch index.html to load custom config
sed -i 's|SwaggerUIBundle({|SwaggerUIBundle({|g' index.html
sed -i 's|url:.*|url: "/api/docs.json",|g' index.html

# --------------------------------------
# Apache configuration
# --------------------------------------
info "▶ Configuration d'Apache"

sudo tee /etc/apache2/sites-available/700-swagger.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName swagger.${VM_DOMAIN}
    Redirect permanent / https://swagger.${VM_DOMAIN}/
</VirtualHost>
EOF

sudo tee /etc/apache2/sites-available/700-swagger-ssl.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName swagger.${VM_DOMAIN}
    DocumentRoot $SWAGGER_DIR
    <Directory $SWAGGER_DIR>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/wildcard.local.pem
    SSLCertificateKeyFile /etc/apache2/ssl/wildcard.local-key.pem

    <Location />
        Require ip 127.0.0.1 192.168.56.0/24
    </Location>
</VirtualHost>
EOF

sudo a2ensite 700-swagger
sudo a2ensite 700-swagger-ssl
sudo systemctl reload apache2

info "✔ Swagger UI installed"
info "→ URL: https://swagger.${VM_DOMAIN}"
echo ""
