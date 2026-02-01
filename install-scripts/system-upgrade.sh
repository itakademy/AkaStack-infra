#!/bin/bash
source /var/www/infra/install-scripts/common.sh

# ----------------------------
# System update
# ----------------------------
info "📦 Mise à jour du système.."
sudo apt-get upgrade -y -qq &> /dev/null 2>&1
ok "✅ Système mis à jour avec succès.\n"

# ----------------------------
# System utilities
# ----------------------------
info "📦 Installation des utilitaires système..."
sudo apt-get install -y --no-install-recommends build-essential libssl-dev git curl wget zip unzip git-core ca-certificates apt-transport-https locate software-properties-common dirmngr &> /dev/null 2>&1
ok "✅ Utilitaires système installés avec succès.\n"