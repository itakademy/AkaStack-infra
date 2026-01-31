#!/bin/bash
source /var/www/infra/install-scripts/common.sh

info "📦 Installation de GitHub CLI (gh)"

if ! command -v gh >/dev/null 2>&1; then
  sudo apt install -y curl ca-certificates gnupg &> /dev/null 2>&1

  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg &> /dev/null 2>&1

  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &> /dev/null 2>&1

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list &> /dev/null 2>&1

  sudo apt install -y gh &> /dev/null 2>&1

  ok "✔ GitHub CLI installé\n"
else
  warn "✔ GitHub CLI déjà installé\n"
fi
