#!/bin/bash
source /var/www/infra/install-scripts/common.sh

# ----------------------------
# phpMyAdmin
# ----------------------------
if is_pkg_installed phpmyadmin; then
  info "🔍 phpMyAdmin est déjà installé…"
  exit 0
fi

sudo install -d -m 0755 /etc/dbconfig-common
sudo tee /etc/dbconfig-common/phpmyadmin.conf > /dev/null <<EOF
dbc_install='true'
dbc_upgrade='true'
dbc_remove=''
dbc_dbtype='mysql'
dbc_dbuser='phpmyadmin'
dbc_dbpass='${MYSQL_ROOT_PASSWORD}'
dbc_dbserver='localhost'
dbc_dbport=''
dbc_dbname='phpmyadmin'
dbc_admin='root'
dbc_basepath=''
dbc_ssl=''
dbc_authmethod_admin=''
dbc_authmethod_user=''
EOF

# Non-interactive install (avoids any debconf prompts)
info  "🧪 Installation de phpMyAdmin (non-interactive)…"
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install phpmyadmin >/dev/null 2>&1
sudo a2enconf phpmyadmin >/dev/null 2>&1 || true
sudo systemctl reload apache2 >/dev/null 2>&1 || true
ok "✅ phpMyAdmin installé avec succès.\n"