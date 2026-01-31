#!/bin/bash
source /var/www/infra/scripts/common.sh
# ----------------------------
# Mailhog
# ----------------------------
info "📦 Installation de MailHog (Go official build)"

MAILHOG_BIN="/usr/local/bin/mailhog"
SERVICE_FILE="/etc/systemd/system/mailhog.service"
GO_VERSION="1.24.0"
ARCH="$(uname -m)"
GO_TARBALL=""

case "$ARCH" in
  x86_64)   GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz" ;;
  aarch64|arm64) GO_TARBALL="go${GO_VERSION}.linux-arm64.tar.gz" ;;
  *) echo "Unsupported arch $ARCH"; exit 1 ;;
esac

info "📦 Installation de Go $GO_VERSION"
cd /tmp
curl -fsSL "https://go.dev/dl/${GO_TARBALL}" -o /tmp/go.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz

export PATH="/usr/local/go/bin:$PATH"
export GOPATH="/opt/go"

mkdir -p "$GOPATH/bin"

echo "Go version:"
/usr/local/go/bin/go version

echo "Build de MailHog"
/usr/local/go/bin/go install github.com/mailhog/MailHog@latest

sudo cp "$GOPATH/bin/MailHog" "$MAILHOG_BIN"
sudo chmod +x "$MAILHOG_BIN"

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=MailHog
After=network.target

[Service]
ExecStart=/usr/local/bin/mailhog -ui-bind-addr=0.0.0.0:8025 -smtp-bind-addr=127.0.0.1:1025
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mailhog
sudo systemctl restart mailhog

sleep 2

ss -lntp | grep -q ":8025" || {
  systemctl status mailhog --no-pager
  exit 1
}

sudo tee /etc/apache2/sites-available/500-mailhog.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName mail.${VM_DOMAIN}
    Redirect permanent / https://mail.${VM_DOMAIN}/
</VirtualHost>
EOF

sudo tee /etc/apache2/sites-available/500-mailhog-ssl.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName mail.${VM_DOMAIN}

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/wildcard.local.pem
    SSLCertificateKeyFile /etc/apache2/ssl/wildcard.local-key.pem

    ProxyPreserveHost On
    ProxyPass        / http://127.0.0.1:8025/
    ProxyPassReverse / http://127.0.0.1:8025/

    <Location />
        Require ip 127.0.0.1 192.168.56.0/24
    </Location>
</VirtualHost>
EOF

sudo a2enmod proxy proxy_http ssl headers rewrite
sudo a2ensite 500-mailhog
sudo a2ensite 500-mailhog-ssl
sudo systemctl reload apache2

echo "======================================"
info " MailHog is running"
info " Web UI : https://mail.${VM_DOMAIN}"
info " SMTP   : 127.0.0.1:1025"
echo "======================================"