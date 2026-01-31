#!/bin/bash
source /var/www/infra/install-scripts/common.sh

# --- Test de connexion GitHub ---
# On capture la sortie pour éviter que le message de GitHub ne pollue le terminal
info "🔗 Test de connexion à GitHub..."
ssh_output=$(ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1)

if echo "$ssh_output" | grep -q "successfully authenticated"; then
    ok "✅ Authentification GitHub réussie."
else
    err "❌ Échec de l'authentification GitHub."
    echo -e "${ORANGE}Détails du message :${NC}"
    echo "$ssh_output"
    exit 1
fi
echo ""