#!/bin/bash
source /var/www/infra/install-scripts/common.sh


if [ "$EUID" -ne 0 ]; then
  err "Please run as root: sudo $0 ..."
  exit 1
fi

info "📦 Installing Python 3 and tooling..."
apt-get update -y -qq &>/dev/null 2>&1
apt-get install -y python3 python3-venv python3-pip &>/dev/null 2>&1

if command -v python3 >/dev/null 2>&1; then
  ok "✅ Python 3 installé: $(python3 --version 2>&1) \n"
else
  err "❌ Échec de l'installation de Python 3.\n"
  exit 1
fi
