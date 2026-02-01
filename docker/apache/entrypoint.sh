#!/bin/sh
set -e

if [ -z "$VM_DOMAIN" ]; then
  echo "VM_DOMAIN is required" >&2
  exit 1
fi

sed "s/__VM_DOMAIN__/${VM_DOMAIN}/g" /usr/local/apache2/conf/extra/vhosts.conf.template > /usr/local/apache2/conf/extra/vhosts.conf

exec httpd-foreground
