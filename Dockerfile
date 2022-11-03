FROM php:7.4-fpm

MAINTAINER Olivier Pichon <op@dzango.com>

ARG build='build'

ARG memory_limit=-1

ARG timezone='Asia/Hong_Kong'

ARG upload_max_filesize='10M'

ARG version='version'

ARG NODE_VERSION='18'

RUN ulimit -n 4096 \
    && apt-get update \
    && apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages --fix-missing \
    && apt install -y apt-utils \
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
    && echo "memory_limit="$memory_limit > /usr/local/etc/php/conf.d/memory_limit.ini \
    && echo "upload_max_filesize="$upload_max_filesize > /usr/local/etc/php/conf.d/upload_max_filesize.ini \
    && echo "display_errors=0" > /usr/local/etc/php/conf.d/display_errors.ini \
    && echo "log_errors=1" > /usr/local/etc/php/conf.d/log_errors.ini \
    && usermod -u 1001 www-data \
    && chown -R www-data:www-data /var/www \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && pecl install geoip-1.1.1  && echo "extension=geoip.so" >> /usr/local/etc/php/conf.d/geoip.ini \
    && /usr/sbin/nginx -v \
    && setcap cap_net_bind_service=+ep /usr/sbin/nginx \
    && curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PATH "/var/www/.composer/vendor/bin:$PATH"

COPY ./etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf

COPY ./etc/php/conf.d/ /usr/local/etc/php/conf.d/

COPY ./etc/nginx/conf.d/nginx.conf /etc/nginx/sites-available/default

RUN touch /var/run/nginx.pid

RUN  chown -R www-data:www-data /var/run/nginx.pid /var/lib/nginx /var/log

COPY www/index.html /var/www/html/web/index.html

COPY www/index.php /var/www/html/web/index.php

COPY ./bin/docker-php-nginx-entrypoint /usr/local/bin/

RUN chown -R www-data:www-data /var/lib/nginx /var/www \
   && chmod -R 777 /var/lib/nginx

WORKDIR /var/www/html

RUN touch /var/log/cron.log

EXPOSE 80 443

ENTRYPOINT ["/bin/sh"]

CMD ["/usr/local/bin/docker-php-nginx-entrypoint"]
