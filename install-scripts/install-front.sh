#!/bin/bash
source /var/www/infra/install-scripts/common.sh

FRONT_DIR="/var/www/front"
OUTPUT_HTML="$FRONT_DIR/index.html"

mkdir -p $FRONT_DIR

info "🧾 Writing front index.html"
cat <<'EOF_HTML' > "$OUTPUT_HTML"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Front README</title>
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
        <p>You may create a new front from scratch, use one of our templates or attach an existing git repository. For more informations, see <a href="https://github.com/itakademy/AkaStack/wiki/2.-Installation#choosing-how-to-attach-your-backend-and-frontend" target="_blank">project Wiki</a>.</p>
        </div>
    </main>
</div>

</body>
</html>
EOF_HTML

# Apache vhost
info "🔧 Configuring Apache vhost for front"
sudo tee /etc/apache2/sites-available/400-front.conf > /dev/null <<EOF_APACHE
<VirtualHost *:80>
    ServerName www.${VM_DOMAIN}
    Redirect permanent / https://www.${VM_DOMAIN}/
</VirtualHost>
EOF_APACHE

sudo tee /etc/apache2/sites-available/400-front-ssl.conf > /dev/null <<EOF_APACHE
<VirtualHost *:443>
    ServerName www.${VM_DOMAIN}
    DocumentRoot ${FRONT_DIR}

    <Directory ${FRONT_DIR}>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/wildcard.local.pem
    SSLCertificateKeyFile /etc/apache2/ssl/wildcard.local-key.pem
</VirtualHost>
EOF_APACHE

sudo a2ensite 400-front >/dev/null 2>&1
sudo a2ensite 400-front-ssl >/dev/null 2>&1
sudo systemctl reload apache2 >/dev/null 2>&1

ok "✅ Front vhost installé. URL: https://www.${VM_DOMAIN}"
