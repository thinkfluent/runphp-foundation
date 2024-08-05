# Extensions we'd like to add by default
ARG PHP_EXT_ESSENTIAL="bcmath opcache mysqli pdo_mysql bz2 soap sockets zip"

# Default PHP version
ARG BUILD_PHP_VER="8.3.8"
ARG TAG_NAME="dev-master"

################################################################################################################
FROM php:${BUILD_PHP_VER}-apache-bullseye as baseline

# Let's get up to date
RUN apt-get update && apt-get -y upgrade

# Set up a PHP extension symlink to the current folder (varies with PHP versions)
RUN ln -s /usr/local/lib/php/extensions/$(ls -1 /usr/local/lib/php/extensions) /usr/local/lib/php/extensions/current

# TODO Review Libraries we're going to need at runtime vs compilation for smaller image size

# Libraries we're going to need for development/compilation
RUN apt-get install -y \
    libxml2-dev \
    libyaml-dev \
    zlib1g-dev \
    libmemcached-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libxslt-dev \
    libzip-dev \
    libffi-dev \
    libpq-dev

# Manifest contents needed for build & runtime
COPY ./manifest /

# TODO Consdier cleanup to reduce image size, apt-get clean etc.

################################################################################################################
FROM baseline as builder
ARG PHP_EXT_ESSENTIAL

# yaml is everywhere these days
# https://pecl.php.net/package/yaml
# https://github.com/php/pecl-file_formats-yaml/tags
RUN export MAKEFLAGS="-j $(nproc)" && pecl install yaml-2.2.3

# APCu
# https://pecl.php.net/package/apcu
# https://github.com/krakjoe/apcu/tags
RUN export MAKEFLAGS="-j $(nproc)" && pecl install apcu-5.1.23

# Extensions that need building for fast Google APIs. This takes a while.
# https://pecl.php.net/package/grpc
RUN export MAKEFLAGS="-j $(nproc)" && pecl install grpc-1.65.2

# https://pecl.php.net/package/protobuf
# PHP 7.4 is limited to 3.24.x
# PHP 8.1 is limited to 3.25.x
RUN export MAKEFLAGS="-j $(nproc)" && pecl install protobuf-`php -r "echo PHP_MAJOR_VERSION < 8 ? '3.24.4' : (PHP_MINOR_VERSION < 1 ? '3.25.4' : '4.27.3');"`

# Memcached & Redis
RUN export MAKEFLAGS="-j $(nproc)" && pecl install memcached redis

# Xdebug. Pinned version for PHP 7.x builds.
# https://xdebug.org/announcements
# https://github.com/xdebug/xdebug/tags
RUN export MAKEFLAGS="-j $(nproc)" && pecl install xdebug`php -r "echo PHP_MAJOR_VERSION < 8 ? '-3.1.6' : (PHP_MINOR_VERSION > 2 ? '-3.3.2' : '');"`

# Install our desired extensions available from php base image
RUN docker-php-ext-install -j$(nproc) ${PHP_EXT_ESSENTIAL}

# We'd like GD with some extras...
RUN docker-php-source extract && \
    cd /usr/src/php/ext/gd && \
    phpize && \
    ./configure --with-jpeg --with-webp --with-freetype && \
    export MAKEFLAGS="-j $(nproc)" && \
    make -j $(nproc) && \
    make install && \
    make clean && \
    docker-php-source delete

# XHProf
RUN export MAKEFLAGS="-j $(nproc)" && pecl install xhprof

# opencensus, for Google Cloud Trace
# https://pecl.php.net/package/opencensus
RUN export MAKEFLAGS="-j $(nproc)" && pecl install opencensus-alpha

# Build any remaining extensions
RUN php /runphp-foundation/bin/install-all-missing-extensions.php

# Purge extension debug strings (100MB becomes 8MB)
# See https://github.com/docker-library/php/issues/297
RUN ls -1 /usr/local/lib/php/extensions/current/*.so | xargs strip --strip-all

################################################################################################################
FROM baseline as runtime
ARG PHP_EXT_ESSENTIAL
ARG TAG_NAME

# Make the log directory writable
RUN chmod ugo+w /var/log

# So we can handle signals properly (Cloud Run will send a SIGTERM), we'll need dumb-init
RUN apt-get install dumb-init

# Pull in all the built extensions
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Enable our base set of extensions (but not all)
RUN docker-php-ext-enable \
    grpc \
    protobuf \
    memcached \
    redis \
    gd \
    xhprof \
    ${PHP_EXT_ESSENTIAL}

# Ensure we listen on the runtime $PORT value
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Adjust apache modules & etc, enable our foundation "hello" page
RUN a2enmod rewrite headers remoteip expires include brotli && \
    a2dismod -f autoindex && \
    a2dissite 000-default && \
    a2ensite 000-runphp-core 001-runphp-foundation && \
    a2enconf 000-logging

ENV RUNPHP_FOUNDATION_VERSION=${TAG_NAME}

