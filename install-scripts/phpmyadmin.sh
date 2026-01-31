#!/bin/bash
source /var/www/infra/install-scripts/common.sh

# -------- Config / Inputs --------
PROJECT_SRC_DIR="/var/www/infra"

# -------- Load .env --------
ENV_FILE=""
for candidate in /var/www/.env /var/www/project/project.env /var/www/infra/.env; do
  if [ -f "$candidate" ]; then
    ENV_FILE="$candidate"
    break
  fi
done

if [ -n "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
  ok "✅ Loaded environment variables from $ENV_FILE"
else
  warn "⚠️ No env file found; falling back to provided environment variables."
fi

# Basic sanity checks for expected vars (adapt if your names differ)
: "${MYSQL_ROOT_PASSWORD:?Missing MYSQL_ROOT_PASSWORD (env or .env)}"
PROJECT_DOMAIN="${PROJECT_DOMAIN:-${VM_DOMAIN:-}}"
: "${PROJECT_DOMAIN:?Missing PROJECT_DOMAIN or VM_DOMAIN}"

# -------- Remove phpMyAdmin if present (clean) --------
if is_pkg_installed phpmyadmin; then
  echo "🔍 phpMyAdmin detected — purging…"
  sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y phpmyadmin >/dev/null
  sudo apt-get -y autoremove >/dev/null
  echo "✅ phpMyAdmin removed."
else
  echo "✅ phpMyAdmin not installed — nothing to remove."
fi

# -------- Install phpMyAdmin (non-interactive, robust) --------
sudo apt-get update -y -qq

# Prefer dbconfig-common config file over debconf-set-selections (more reliable)
# It lets package scripts configure DB user/db silently.
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
echo "🧪 Installing phpMyAdmin (non-interactive)…"
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install phpmyadmin >/dev/null 2>&1
sudo a2enconf phpmyadmin >/dev/null 2>&1 || true
sudo systemctl reload apache2 >/dev/null 2>&1 || true
# Mark phpMyAdmin as installed
touch "${PROJECT_SRC_DIR}/.phpmyadmin.installed"

# -------- Final output --------
cat <<MSG

✅ PhpMyAdmin installation complete.

Access:
  • URL:  https://${PROJECT_DOMAIN}/phpmyadmin
  • Login:
        Username: root
        Password: ${MYSQL_ROOT_PASSWORD}

Happy building! 🚀
MSG
