#!/bin/bash
source /var/www/infra/install-scripts/common.sh

# ----------------------------
# OpenSSH post-install workaround
# ----------------------------
info "🔧 Handling openssh-server post-install script issues..."
if grep -q "half-configured" /var/lib/dpkg/status || ps aux | grep -q "[o]penssh-server.*postinst"; then
  sudo mv /var/lib/dpkg/info/openssh-server.postinst /tmp/openssh-server.postinst.bak &> /dev/null 2>&1 || true
  sudo dpkg --configure -a &> /dev/null 2>&1 || true
fi
sudo apt-get purge -qq -y openssh-server openssh-client &> /dev/null 2>&1 || true
sudo apt-get update -qq &> /dev/null 2>&1
sudo apt-get install -qq -y openssh-server openssh-client &> /dev/null 2>&1 || true

info "✅ Workaround to prevent post-install problems with openssh-server applied."
if sudo systemctl is-active ssh &> /dev/null 2>&1; then
  ok "✅ Openssh-server has been installed and started successfully.\n"
else
  warn "⚠️ SSH service appears inactive, trying to restart...\n"
  sudo systemctl restart ssh /dev/null 2>&1 || true
fi