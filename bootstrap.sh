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

source /var/www/infra/install-scripts/common.sh

ENV_FILE="/var/www/.env"
if [ -n "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
  ok "✅ Loaded environment variables from $ENV_FILE"
else
  err "⚠️ No env file found."
  exit 1
fi
