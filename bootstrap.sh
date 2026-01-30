#!/bin/bash
# Provisioning script – Ubuntu 24.04 LTS

VM_VERSION=$(cat /var/www/VERSION)

export DEBIAN_FRONTEND=noninteractive
echo ""
echo ""
echo "   ___   "
echo "  (o,o)  "
echo " <  .  >  It-Akademy "
echo "  -----  "
echo ""
echo -e "https://www.it-akademy.fr"
echo ""
echo -e "VM $VM_NAME v.$VM_VERSION "
echo ""
echo "+-------------------------------+"
echo "PROVISIONING"
echo ""

info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[ OK ]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERR ]\033[0m $*" >&2; }

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

# 1. Vérification SSH
ssh -T git@github.com -o StrictHostKeyChecking=no || { err "❌ SSH Agent non détecté"; exit 1; }