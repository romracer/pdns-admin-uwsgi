FROM alpine:3.7
MAINTAINER "Peter Schiffer" <pschiffe@redhat.com>

RUN apk add --no-cache \
     python2 \
     py2-pip \
     uwsgi-python \
     py-mysqldb \
     py2-pyldap \
     py2-cffi \
     py2-bcrypt \
     py2-openssl \
     py2-tz \
     libxml2 \
     xmlsec \
     mariadb-client \
     openssl \
     ca-certificates \
  && apk add --no-cache --virtual build-deps \
     gcc libc-dev python2-dev openssl-dev libxml2-dev xmlsec-dev curl \
  && mkdir -p /opt/powerdns-admin \
  && curl -sSL https://github.com/thomasDOTde/PowerDNS-Admin/archive/master.tar.gz \
     | tar -xzC /opt/powerdns-admin --strip 1 \
  && sed -i '/MySQL-python/d' /opt/powerdns-admin/requirements.txt \
  && sed -i '/python-ldap/d' /opt/powerdns-admin/requirements.txt \
  && sed -i '/bcrypt/d' /opt/powerdns-admin/requirements.txt \
  && sed -i '/pyOpenSSL/d' /opt/powerdns-admin/requirements.txt \
  && sed -i '/pytz/d' /opt/powerdns-admin/requirements.txt \
  && chown -R root: /opt/powerdns-admin \
  && chown -R uwsgi: /opt/powerdns-admin/upload

WORKDIR /opt/powerdns-admin

RUN pip install envtpl \
  && pip install -r requirements.txt \
  && apk del --purge build-deps \
  && rm -rf ~/.cache/*

ENV PDNS_ADMIN_LOGIN_TITLE="'PDNS'" \
  PDNS_ADMIN_TIMEOUT=10 \
  PDNS_ADMIN_LOG_LEVEL="'INFO'" \
  PDNS_ADMIN_BASIC_ENABLED=True \
  PDNS_ADMIN_SIGNUP_ENABLED=True \
  PDNS_ADMIN_RECORDS_ALLOW_EDIT="['SOA', 'A', 'AAAA', 'CAA', 'CNAME', 'MX', 'PTR', 'SPF', 'SRV', 'TXT', 'LOC', 'NS']" \
  PDNS_ADMIN_FORWARD_RECORDS_ALLOW_EDIT="['A', 'AAAA', 'CAA', 'CNAME', 'MX', 'PTR', 'SPF', 'SRV', 'TXT', 'LOC' 'NS']" \
  PDNS_ADMIN_REVERSE_RECORDS_ALLOW_EDIT="['TXT', 'LOC', 'NS', 'PTR']"

COPY pdns-admin.ini /etc/uwsgi/conf.d/
RUN chown uwsgi: /etc/uwsgi/conf.d/pdns-admin.ini \
  && ln -s /etc/uwsgi/uwsgi.ini /etc/uwsgi.ini

EXPOSE 9494

VOLUME [ "/opt/powerdns-admin/upload" ]

COPY config.py.tpl /
COPY docker-cmd.sh /

CMD [ "/docker-cmd.sh" ]
