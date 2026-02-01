#!/bin/bash
source /var/www/infra/install-scripts/common.sh

# ----------------------------
# MariaDB
# ----------------------------
info "📦 Installation de MariaDB..."
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get install -y mariadb-server &> /dev/null 2>&1
ok "✅ MariaDB installé avec succès.\n"
sudo mysql <<EOF
ALTER USER 'root'@'localhost'
IDENTIFIED VIA mysql_native_password
USING PASSWORD('${MYSQL_ROOT_PASSWORD}');
FLUSH PRIVILEGES;
EOF
info "🔑 Le mot de passe root de MariaDb est : ${MYSQL_ROOT_PASSWORD}"
echo ""
