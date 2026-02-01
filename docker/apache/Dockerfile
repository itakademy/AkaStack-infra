FROM httpd:2.4

RUN sed -i \
  -e 's/^#LoadModule proxy_module/LoadModule proxy_module/' \
  -e 's/^#LoadModule proxy_fcgi_module/LoadModule proxy_fcgi_module/' \
  -e 's/^#LoadModule proxy_http_module/LoadModule proxy_http_module/' \
  -e 's/^#LoadModule ssl_module/LoadModule ssl_module/' \
  -e 's/^#LoadModule rewrite_module/LoadModule rewrite_module/' \
  -e 's/^#LoadModule headers_module/LoadModule headers_module/' \
  -e 's/^#LoadModule alias_module/LoadModule alias_module/' \
  /usr/local/apache2/conf/httpd.conf \
  && echo "Include conf/extra/vhosts.conf" >> /usr/local/apache2/conf/httpd.conf

RUN mkdir -p /usr/local/apache2/conf/certs /var/www /usr/local/apache2/conf/extra

COPY conf/vhosts.conf.template /usr/local/apache2/conf/extra/vhosts.conf.template
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
