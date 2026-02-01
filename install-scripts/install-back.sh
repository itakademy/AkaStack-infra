#!/bin/bash
source /var/www/infra/install-scripts/common.sh

BACK_DIR="/var/www/back"
README_PATH="BACK_DIR/README.md"
OUTPUT_HTML="BACK_DIR/index.html"

mkdir -p $BACK_DIR

info "🧾 Writing back index.html"
cat <<'EOF_HTML' > "$OUTPUT_HTML"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Back README</title>
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
        <p>You may create a new back from scratch, use one of our templates or attach an existing git repository. For more informations, see <a href="https://github.com/itakademy/AkaStack/wiki/2.-Installation#choosing-how-to-attach-your-backend-and-frontend" target="_blank">project Wiki</a>.</p>
        </div>
    </main>
</div>

</body>
</html>
EOF_HTML

# Apache vhost
info "🔧 Configuring Apache vhost for front"
sudo tee /etc/apache2/sites-available/300-back.conf > /dev/null <<EOF_APACHE
<VirtualHost *:80>
    ServerName back.${VM_DOMAIN}
    Redirect permanent / https://back.${VM_DOMAIN}/
</VirtualHost>
EOF_APACHE

sudo tee /etc/apache2/sites-available/300-back-ssl.conf > /dev/null <<EOF_APACHE
<VirtualHost *:443>
    ServerName back.${VM_DOMAIN}
    DocumentRoot ${BACK_DIR}

    <Directory ${BACK_DIR}>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/wildcard.local.pem
    SSLCertificateKeyFile /etc/apache2/ssl/wildcard.local-key.pem
</VirtualHost>
EOF_APACHE

sudo a2ensite 300-back >/dev/null 2>&1
sudo a2ensite 300-back-ssl >/dev/null 2>&1
sudo systemctl reload apache2 >/dev/null 2>&1

ok "✅ Back vhost installé. URL: https://back.${VM_DOMAIN}"
