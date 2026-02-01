#!/bin/bash
source /var/www/infra/install-scripts/common.sh

API_DIR="/var/www/api"
README_PATH="API_DIR/README.md"
OUTPUT_HTML="API_DIR/index.html"

mkdir -p $API_DIR

info "🧾 Writing API index.html"
cat <<'EOF_HTML' > "$OUTPUT_HTML"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>API README</title>
    <style>
        html, body {
            margin: 0;
            font-family: system-ui;
        }
        .content {
            max-width: 900px;
            margin: 0 auto;
            padding: 0 20px calc(var(--footer-height) + 20px);
        }
    </style>
</head>
<body>

<div class="page">
    <main class="content">
        <div class="content-inner">
        <h1>Frontend</h1>
        <p>You may create a new API from scratch, use one of our templates or attach an existing git repository. For more informations, see <a href="https://github.com/itakademy/AkaStack/wiki/2.-Installation#choosing-how-to-attach-your-backend-and-frontend" target="_blank">project Wiki</a>.</p>
        </div>
    </main>
</div>

</body>
</html>
EOF_HTML

# Apache vhost
info "🔧 Configuring Apache vhost for API"
sudo tee /etc/apache2/sites-available/200-api.conf > /dev/null <<EOF_APACHE
<VirtualHost *:80>
    ServerName api.${VM_DOMAIN}
    Redirect permanent / https://api.${VM_DOMAIN}/
</VirtualHost>
EOF_APACHE

sudo tee /etc/apache2/sites-available/200-api-ssl.conf > /dev/null <<EOF_APACHE
<VirtualHost *:443>
    ServerName api.${VM_DOMAIN}
    DocumentRoot ${API_DIR}

    <Directory ${API_DIR}>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/wildcard.local.pem
    SSLCertificateKeyFile /etc/apache2/ssl/wildcard.local-key.pem
</VirtualHost>
EOF_APACHE

sudo a2ensite 200-api >/dev/null 2>&1
sudo a2ensite 200-api-ssl >/dev/null 2>&1
sudo systemctl reload apache2 >/dev/null 2>&1

ok "✅ API vhost installé. URL: https://api.${VM_DOMAIN}"
