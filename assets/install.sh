#!/bin/bash

#judgement
if [[ -a /etc/supervisor/conf.d/supervisord.conf ]]; then
  exit 0
fi

#supervisor
cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[supervisord]
nodaemon=true

[program:postfix]
command=/opt/postfix.sh

[program:rsyslog]
command=/usr/sbin/rsyslogd -n

[program:saslauthd]
command=/usr/sbin/saslauthd -d -c -m /var/spool/postfix/var/run/saslauthd -r -a pam
EOF

############
#  postfix
############
cat >> /opt/postfix.sh <<EOF
#!/bin/bash
#service postfix start
#tail -f /var/log/mail.log
postfix start-fg
EOF
chmod +x /opt/postfix.sh

postconf -e myhostname=$HOSTNAME
#postconf -F '*/*/chroot = n'

postconf -e 'mydestination = localhost, proxy:mysql:/etc/postfix/mysql-mydestination.cf'
postconf -e 'virtual_alias_maps = proxy:mysql:/etc/postfix/mysql-virtual_forwardings.cf, mysql:/etc/postfix/mysql-virtual_email2email.cf'
postconf -e 'virtual_mailbox_domains = proxy:mysql:/etc/postfix/mysql-virtual_domains.cf'
postconf -e 'virtual_mailbox_maps = proxy:mysql:/etc/postfix/mysql-virtual_mailboxes.cf'
postconf -e 'virtual_mailbox_base = /home/vmail'
postconf -e 'virtual_uid_maps = static:5000'
postconf -e 'virtual_gid_maps = static:5000'
postconf -e 'smtpd_sasl_auth_enable = yes'
postconf -e 'smtpd_helo_required = yes'
postconf -e 'broken_sasl_auth_clients = yes'
postconf -e 'smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination'
postconf -e 'smtpd_use_tls = yes'
postconf -e 'smtpd_tls_cert_file = /etc/postfix/smtpd.crt'
postconf -e 'smtpd_tls_key_file = /etc/postfix/smtpd.key'
postconf -e 'smtpd_tls_security_level = encrypt'
postconf -e 'smtpd_tls_auth_only = yes'
postconf -e 'strict_rfc821_envelopes = yes'
postconf -e 'disable_vrfy_command = yes'
postconf -e 'transport_maps = proxy:mysql:/etc/postfix/mysql-virtual_transports.cf'
#postconf -e 'virtual_create_maildirsize = yes'
#postconf -e 'virtual_mailbox_extended = yes'
postconf -e 'virtual_mailbox_limit_maps = proxy:mysql:/etc/postfix/mysql-virtual_mailbox_limit_maps.cf'
#postconf -e 'virtual_mailbox_limit_override = yes'
#postconf -e 'virtual_maildir_limit_message = "Account is over quota"'
#postconf -e 'virtual_overquota_bounce = yes'
postconf -e 'proxy_read_maps = $local_recipient_maps $mydestination $virtual_alias_maps $virtual_alias_domains $virtual_mailbox_maps    $virtual_mailbox_domains $relay_recipient_maps $relay_domains $canonical_maps $sender_canonical_maps $recipient_canonical_maps $relocated_maps $transport_maps $mynetworks $virtual_mailbox_limit_maps'

CONFIG_FILES="/etc/postfix/*.cf"
CONFIG_FILES+=" /etc/pam.d/smtp"
CONFIG_FILES+=" /etc/postfix/sasl/smtpd.conf"

echo $CONFIG_FILES

for file in $CONFIG_FILES
do
  sed -i "s/{mysql_host}/$MYSQL_HOST/g" $file
  sed -i "s/{mysql_username}/$MYSQL_USERNAME/g" $file
  sed -i "s/{mysql_password}/$MYSQL_PASSWORD/g" $file
  sed -i "s/{mysql_database}/$MYSQL_DATABASE/g" $file
done

cp /etc/services /var/spool/postfix/etc
cp /etc/resolv.conf /var/spool/postfix/etc

chown -R postfix:postfix /etc/postfix
