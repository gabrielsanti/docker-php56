# Base image
FROM php:5.6-apache

# Create web folder
RUN mkdir /var/www/html/website

# Copy config files into the container
COPY ./conf/website.conf /etc/apache2/sites-available/website.conf
COPY ./conf/php.ini /usr/local/etc/php/

# Setting ServerName to avoid "Could not reliably determine the server's fully qualified domain name, using 127.0.1.1 for ServerName" warning
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf
RUN a2enconf servername

# Configure Apache vhosts, enable mod rewrite
RUN chown -R www-data:www-data /var/www/html/website \
    && a2dissite 000-default.conf \
    && a2ensite website.conf \
    && a2enmod rewrite \
    && service apache2 restart

# Installing PHP, PHP extensions and necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends libpng-dev libjpeg-dev libjpeg62-turbo libmcrypt4 libmcrypt-dev libcurl3-dev libxml2-dev libxslt-dev libicu-dev  && rm -rf /var/lib/apt/lists/*

RUN apt-get update  \
    && apt-get install -y zlib1g-dev \
    && docker-php-ext-configure gd --with-jpeg-dir=/usr/lib \
    && docker-php-ext-install gd \
    && docker-php-ext-install zip \
    && docker-php-ext-install mysql \
    && docker-php-ext-install opcache \
    && docker-php-ext-install exif \
    && apt-get purge --auto-remove -y libjpeg-dev libmcrypt-dev libcurl3-dev libxml2-dev libicu-dev \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install pdo_mysql \
    && apt-get autoremove

RUN BEFORE_PWD=$(pwd) \
    && mkdir -p /opt/xdebug \
    && cd /opt/xdebug \
    && curl -k -L https://github.com/xdebug/xdebug/archive/XDEBUG_2_5_5.tar.gz | tar zx \
    && cd xdebug-XDEBUG_2_5_5 \
    && phpize \
    && ./configure --enable-xdebug \
    && make clean \
    && sed -i 's/-O2/-O0/g' Makefile \
    && make \
    # && make test \
    && make install \
    && cd "${BEFORE_PWD}" \
    && rm -r /opt/xdebug
RUN docker-php-ext-enable xdebug

# Exposing web ports
EXPOSE 80 443

CMD apachectl -D FOREGROUND