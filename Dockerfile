FROM registry.access.redhat.com/ubi7/ubi

LABEL \
  name="app" \
  version="latest"

EXPOSE 8080 8443

ENV \
    container=oci \
    TZ='America/Sao_Paulo' \
    HTTPD_PATH=/opt/rh/httpd24/root/etc/httpd \
    PHP_PATH=/etc/opt/rh/rh-php72 \
    APP_ROOT=/opt/app-root \
    PHP_VERSION=7.2 \
    PHP_VER_SHORT=72

ENV \
    APP_DATA=${APP_ROOT}/src \
    APP_PUBLIC=${APP_ROOT}/src/public \
    APP_BIN=${APP_ROOT}/bin \
    HOME=${APP_ROOT} \    
    PATH=${APP_ROOT}/bin:${APP_ROOT}/src:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/rh/rh-php72/root/usr/bin:/opt/rh/httpd24/root/usr/sbin:$PATH

RUN \
  yum-config-manager --disableplugin=subscription-manager --enable rhel-7-server-rpms rhel-7-server-optional-rpms rhel-server-rhscl-7-rpms && \
  INSTALL_PKGS="\
  rh-php72 \
  rh-php72-php \
  rh-php72-php-opcache \
  httpd24-mod_ssl" && \
  yum install -y --setopt=tsflags=nodocs --disableplugin=subscription-manager $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  yum -y clean all --disableplugin=subscription-manager --enablerepo='*'

RUN \
  # CONFIGURAÇÕES DO HTTPD
  sed -i -e 's%^Listen 443%Listen 0.0.0.0:8443%' ${HTTPD_PATH}/conf.d/ssl.conf && \
  sed -i -e 's%VirtualHost _default_:443%VirtualHost _default_:8443%' ${HTTPD_PATH}/conf.d/ssl.conf && \
  sed -i -e 's%#ServerName www.example.com:443%ServerName localhost:8443%' ${HTTPD_PATH}/conf.d/ssl.conf && \
  sed -i -e '75s%SSLProtocol all -SSLv2%SSLProtocol ALL -SSLv2 -SSLv3%' ${HTTPD_PATH}/conf.d/ssl.conf && \
  sed -i -e '92s%#SSLCipherSuite.*%SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA%' ${HTTPD_PATH}/conf.d/ssl.conf && \
  sed -i -e '93s%#SSLHonorCipherOrder%SSLHonorCipherOrder%' ${HTTPD_PATH}/conf.d/ssl.conf && \
  sed -i -e 's%^Listen 80%Listen 0.0.0.0:8080%' ${HTTPD_PATH}/conf/httpd.conf && \
  sed -i -e 's%#ServerName www.example.com:80%ServerName localhost%' ${HTTPD_PATH}/conf/httpd.conf && \
  sed -i -e 's%^User apache%User default%' ${HTTPD_PATH}/conf/httpd.conf && \
  sed -i -e 's%^Group apache%Group root%' ${HTTPD_PATH}/conf/httpd.conf && \
  sed -i -e 's%^DocumentRoot "/opt/rh/httpd24/root/var/www/html"%DocumentRoot "'"$APP_PUBLIC"'"%' ${HTTPD_PATH}/conf/httpd.conf && \
  sed -i -e 's%^<Directory "/opt/rh/httpd24/root/var/www/html"%<Directory "'"$APP_PUBLIC"'"%' ${HTTPD_PATH}/conf/httpd.conf && \
  sed -i -e 's%^<Directory "/opt/rh/httpd24/root/var/www"%<Directory "'"$APP_PUBLIC"'"%' ${HTTPD_PATH}/conf/httpd.conf && \
  sed -i -e '125s%AllowOverride None%AllowOverride All%' ${HTTPD_PATH}/conf/httpd.conf && \
  sed -i -e '151s%AllowOverride None%AllowOverride All%' ${HTTPD_PATH}/conf/httpd.conf && \
  sed -i -e '40s%LoadModule http2_module%# LoadModule httpd2_module%' ${HTTPD_PATH}/conf.modules.d/00-base.conf && \
  ln -sf /proc/self/fd/1 ${HTTPD_PATH}/logs/access_log && \
  ln -sf /proc/self/fd/1 ${HTTPD_PATH}/logs/error_log && \
  ln -sf /proc/self/fd/1 ${HTTPD_PATH}/logs/ssl_access_log && \
  ln -sf /proc/self/fd/1 ${HTTPD_PATH}/logs/ssl_error_log && \
  ln -sf /proc/self/fd/1 ${HTTPD_PATH}/logs/ssl_request_log && \    
  # CONFIGURAÇÕES DO PHP
  sed -i -e 's%^serialize_precision = -1%serialize_precision = 17%' ${PHP_PATH}/php.ini && \
  sed -i -e 's%^disable_functions =%disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,%' ${PHP_PATH}/php.ini && \
  sed -i -e 's%^expose_php = On%expose_php = Off%' ${PHP_PATH}/php.ini && \
  sed -i -e 's%^;track_errors%track_errors%' ${PHP_PATH}/php.ini && \
  sed -i -e 's%^post_max_size = 8M%post_max_size = 100M%' ${PHP_PATH}/php.ini && \
  sed -i -e 's%^upload_max_filesize = 2M%upload_max_filesize = 100M%' ${PHP_PATH}/php.ini && \
  sed -i -e 's%^pcre.jit%;pcre.jit%' ${PHP_PATH}/php.ini && \
  sed -i -e 's%^sendmail_path%;sendmail_path%' ${PHP_PATH}/php.ini

# COPIA A APLICAÇÃO
COPY ./index.php ${APP_PUBLIC}/index.php

RUN \
  # PERMISSÕES
  useradd -u 1001 -r -g 0 -d ${HOME} -s /sbin/nologin \
      -c "Default Application User" default && \
  chown -R 1001:0 ${HOME} && \
  chmod -R 770 ${HOME} && \
  chgrp -R 0 /var/log/httpd24 /opt/rh/httpd24/root/var/run/httpd && \
  chmod -R g=u /var/log/httpd24 /opt/rh/httpd24/root/var/run/httpd && \
  chmod -R a+r /etc/pki/tls/certs/localhost.crt && \
  chmod -R a+r /etc/pki/tls/private/localhost.key

WORKDIR ${HOME}

USER 1001

CMD scl enable httpd24 rh-php72 -- httpd -DFOREGROUND
