FROM php:8.0-fpm
LABEL maintainer="Dzango Technologies Limited <info@dzango.com>"

ARG memory_limit=-1
ARG node_version='18'
ARG timezone='Asia/Hong_Kong'
ARG uid=1000
ARG upload_max_filesize='10M'

RUN ulimit -n 4096 \
    && apt-get update \
    && apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages --fix-missing \
    && apt install -y \
        apt-utils \
        build-essential \
        cron \
        git \
        gnupg \
        libcap2-bin \
        libcurl4-gnutls-dev \
        libfreetype6-dev \
        libgeoip-dev \
        libgmp-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libmagickwand-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libxslt1.1 libxslt1-dev \
        libzip-dev \
        locales \
        netcat \
        nginx \
        openssh-client \
        supervisor \
        unzip \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install \
        calendar \
        curl \
        exif \
        gd \
        gmp \
        gettext \
        intl \
        mysqli \
        opcache \
        pcntl \
        pdo_mysql \
        shmop \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        xsl \
        zip \
    && echo "date.timezone="$timezone > /usr/local/etc/php/conf.d/date_timezone.ini \
    && echo "display_errors=0" > /usr/local/etc/php/conf.d/display_errors.ini \
    && echo "log_errors=1" > /usr/local/etc/php/conf.d/log_errors.ini \
    && echo "memory_limit="$memory_limit > /usr/local/etc/php/conf.d/memory_limit.ini \
    && echo "opcache.enable=0" > /usr/local/etc/php/conf.d/opcache.ini \
    && echo "upload_max_filesize="$upload_max_filesize > /usr/local/etc/php/conf.d/upload_max_filesize.ini \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && /usr/sbin/nginx -v \
    && setcap cap_net_bind_service=+ep /usr/sbin/nginx \
    && curl -sL https://deb.nodesource.com/setup_$node_version.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf

COPY ./etc/php/conf.d/ /usr/local/etc/php/conf.d/

COPY ./etc/nginx/conf.d/nginx.conf /etc/nginx/sites-available/default

RUN touch /var/run/nginx.pid

COPY www/index.html /var/www/html/web/index.html

COPY www/index.php /var/www/html/web/index.php

COPY ./bin/docker-php-nginx-entrypoint /usr/local/bin/

RUN usermod -u $uid www-data && groupmod -g $uid www-data \
    && chown -R www-data:www-data /var/run/nginx.pid /var/lib/nginx /var/log /var/www \
    && chmod -R 777 /var/lib/nginx

WORKDIR /var/www/html

USER www-data

RUN touch /var/log/cron.log

EXPOSE 80 443

ENTRYPOINT ["/bin/sh"]

CMD ["/usr/local/bin/docker-php-nginx-entrypoint"]
