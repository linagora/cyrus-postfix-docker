ARG DEBIANVERSION=bookworm

FROM debian:${DEBIANVERSION}-slim AS debian-backports-updated

ENV DEBIAN_VERSION=bookworm

RUN echo "# Install packages from ${DEBIAN_VERSION}" && \
    apt-get -y update && \
    apt-get -y dist-upgrade && \
    echo "deb http://deb.debian.org/debian" ${DEBIAN_VERSION}"-backports main" > /etc/apt/sources.list.d/backports.list && \
    apt-get -y update

FROM debian-backports-updated

ARG S6_OVERLAY_VERSION=3.2.0.2

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/cyrus-imapd-postfix" \
      version="v1.0"

ENV DEBIAN_VERSION=bookworm \
    MAILNAME=example.com \
    OTHER_DESTINATIONS="example.com" \
    RELAY_HOST= \
    MYNETWORKS="127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" \
    ROOT_ADDRESS= \
    CYRUS_PWD= \
    SASL_PWCHECK_METHOD="saslauthd auxprop" \
    SASLDB=sasldb

RUN \
    echo cyrus-common cyrus-common/removespools boolean false | debconf-set-selections && \
    echo postfix postfix/main_mailer_type select "Internet Site" | debconf-set-selections && \
    echo postfix postfix/mailname string "$MAILNAME" | debconf-set-selections && \
    echo postfix postfix/destinations string "$OTHER_DESTINATIONS" | debconf-set-selections && \
    echo postfix postfix/relayhost string "" | debconf-set-selections && \
    echo postfix postfix/procmail boolean false | debconf-set-selections && \
    echo postfix postfix/protocols select all | debconf-set-selections && \
    echo postfix postfix/recipient_delim string "+" | debconf-set-selections && \
    echo postfix postfix/chattr boolean false | debconf-set-selections && \
    echo postfix postfix/mynetworks string "$MYNETWORKS" | debconf-set-selections && \
    echo postfix postfix/mailbox_limit string 0 | debconf-set-selections && \
    echo postfix postfix/root_address string "$ROOT_ADDRESS" | debconf-set-selections && \
    echo postfix postfix/newaliases boolean false | debconf-set-selections && \
    apt install -y xz-utils \
      cyrus-imapd/${DEBIAN_VERSION}-backports \
      cyrus-pop3d/${DEBIAN_VERSION}-backports \
      cyrus-nntpd/${DEBIAN_VERSION}-backports \
      cyrus-admin/${DEBIAN_VERSION}-backports \
      cyrus-caldav/${DEBIAN_VERSION}-backports \
      libcyrus-imap-perl/${DEBIAN_VERSION}-backports \
      net-tools \
      dnsutils \
      telnet \
      curl \
      vim \
      jq \
      postfix \
      sasl2-bin && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/postfix/master.cf.proto \
      /etc/postfix/sasl_passwd \
      /etc/postfix/canonical \
      /etc/postfix/dynamicmaps.cf \
      /etc/postfix/sasl_passwd.db \
      /etc/postfix/canonical \
      /etc/postfix/dynamicmaps.cf \
      /etc/postfix/sasl_passwd.db \
      /etc/postfix/main.cf \
      /etc/postfix/regexmap \
      /etc/postfix/canonical.db \
      /etc/postfix/master.cf \
      /etc/postfix/main.cf.proto

RUN perl -i -pe 's/httpmodules: .*$/httpmodules: carddav caldav jmap/' /etc/imapd.conf
RUN perl -i -pe 's/sasl_pwcheck_method: .*$/sasl_pwcheck_method: saslauthd auxprop/' /etc/imapd.conf
RUN echo 'conversations: 1' >> /etc/imapd.conf
RUN echo 'conversations_db: twoskip' >> /etc/imapd.conf
RUN echo 'admins: cyrus' >> /etc/imapd.conf
RUN echo 'jmap_vacation: 0' >> /etc/imapd.conf
RUN echo 'virtdomains: yes' >> /etc/imapd.conf
RUN echo 'defaultdomain: localhost.com' >> /etc/imapd.conf

RUN /usr/lib/cyrus/bin/ctl_conversationsdb -b -r

RUN usermod -aG mail postfix

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/syslogd-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && rm /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && rm /tmp/s6-overlay-x86_64.tar.xz && \
    tar -C / -Jxpf /tmp/syslogd-overlay-noarch.tar.xz && rm /tmp/syslogd-overlay-noarch.tar.xz


EXPOSE 25 465 587 110 143 993 995 2000 8008 8443

VOLUME [ "/etc", "/var/lib/cyrus", "/var/spool/cyrus", "/var/spool/mail", "/var/spool/sieve" ]

COPY install /

CMD ["/usr/sbin/cyrmaster", "-D", "-l", "32", "-C", "/etc/imapd.conf", "-M", "/etc/cyrus.conf"]

ENTRYPOINT ["/init"]
