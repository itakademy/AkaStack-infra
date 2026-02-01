#!/bin/bash
source /var/www/infra/install-scripts/common.sh

echo "======================================"
info " Provisionnement terminé !"
echo "======================================"

echo ""
info "Adresse IP publique : ${VM_IP}"
info "Web services"
info "• Project home:      https://${VM_DOMAIN}/"
info "• Front:             https://www.${VM_DOMAIN}/"
info "• Back office:       https://back.${VM_DOMAIN}/"
info "• API:               https://api.${VM_DOMAIN}/"
info "• Swagger:           https://swagger.${VM_DOMAIN}/"
info "• MailHog:           https://mail.${VM_DOMAIN}/"
info "• Mongo Express:     https://mongo.${VM_DOMAIN}/"
info "• Redis Commander:   https://redis.${VM_DOMAIN}/"
info "• phpMyAdmin:        https://${VM_DOMAIN}/phpmyadmin"
info "• phpinfo:           https://${VM_DOMAIN}/phpinfo"

echo ""
ok "✅ All services are ready. Happy coding! 🚀"
