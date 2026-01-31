#!/bin/bash
source /var/www/infra/install-scripts/common.sh

# ----------------------------
# Node.js
# ----------------------------
info "📦 Installation de Node.js..."
curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash - &> /dev/null 2>&1
sudo apt-get install -y --no-install-recommends nodejs &> /dev/null 2>&1
sudo npm install --global npm@latest  &> /dev/null 2>&1
sudo npm install --global yarn  &> /dev/null 2>&1
sudo npm install --global gulp-cli  &> /dev/null 2>&1
sudo npm install --global bower &> /dev/null 2>&1
ok "✅ Node.js, npm, yarn, gulp-cli, et bower ont été installés avec succès.\n"
