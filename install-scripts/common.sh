#!/bin/bash

ENV_FILE="/var/www/.env"

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a


info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[ OK ]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERR ]\033[0m $*" >&2; }

is_pkg_installed() {
  # returns 0 if installed, non-zero otherwise
  dpkg-query -Wf'${db:Status-abbrev}' "$1" 2>/dev/null | grep -q '^i'
}
