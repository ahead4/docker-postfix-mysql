From ubuntu:eoan

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get -y install supervisor postfix postfix-mysql libsasl2-modules-sql sasl2-bin libsasl2-2 libpam-mysql opendkim opendkim-tools rsyslog nano

ADD assets/install.sh /opt/install.sh

ADD assets/postfix/ /etc/postfix
ADD assets/pam.d /etc/pam.d

RUN chmod 640 /etc/postfix/mysql-*.cf \
 && chgrp postfix /etc/postfix/mysql-*.cf

RUN groupadd -g 5000 vmail \
 && useradd -g vmail -u 5000 vmail -d /home/vmail -m

#RUN openssl req -new -outform PEM -out /etc/postfix/smtpd.cert -newkey rsa:2048 -nodes -keyout /etc/postfix/smtpd.key -keyform PEM -days 3650 -x509 \
# && chmod 640 /etc/postfix/smtpd.key

RUN adduser postfix sasl \
 && mkdir -p /var/spool/postfix/var/run/saslauthd

CMD /opt/install.sh; /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
