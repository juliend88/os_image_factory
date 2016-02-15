#!/usr/bin/env bash
service apache2 stop
letsencrypt-auto certonly --standalone -d $(cat /etc/ansible/mail-vars.yml | grep mail_domain |cut -d"'" -f2) --standalone-supported-challenges tls-sni-01 --renew-by-default
service apache2 start