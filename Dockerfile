# Extensions we'd like to add by default
ARG PHP_EXT_ESSENTIAL="bcmath opcache mysqli pdo_mysql bz2 soap sockets zip"

# Where do all the PHP extensions go?
ARG BUILD_PHP_VER="7.4.33"
ARG PHP_EXT_FOLDER="/usr/local/lib/php/extensions/no-debug-non-zts-20190902/"

ARG TAG_NAME="dev-master"

################################################################################################################
FROM php:${BUILD_PHP_VER}-apache as baseline

# Let's get up to date
RUN apt-get update && apt-get -y upgrade

# TODO Review Libraries we're going to need at runtime vs compilation for smaller image size

# Libraries we're going to need for development/compilation
RUN apt-get install -y \
    libxml2-dev \
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
ARG PHP_EXT_FOLDER

# Extensions that need building for fast Google APIs. This takes a while.
# https://pecl.php.net/package/grpc
RUN pecl install grpc-1.50.0
# https://pecl.php.net/package/protobuf
RUN pecl install protobuf-3.21.9

# Memcached & Redis
RUN pecl install memcached redis

# Xdebug
RUN pecl install xdebug

# Install our desired extensions available from php base image
RUN docker-php-ext-install -j$(nproc) ${PHP_EXT_ESSENTIAL}

# We'd like GD with some extras...
RUN docker-php-source extract && \
    cd /usr/src/php/ext/gd && \
    phpize && \
    ./configure --with-jpeg --with-webp --with-freetype && \
    make && \
    make install && \
    make clean && \
    docker-php-source delete

# XHProf
RUN pecl install xhprof

# opencensus, for Google Cloud Trace
# https://pecl.php.net/package/opencensus
RUN pecl install opencensus-alpha

# Build any remaining extensions
RUN php /runphp-foundation/bin/install-all-missing-extensions.php

# Purge extension debug strings (100MB becomes 8MB)
# See https://github.com/docker-library/php/issues/297
RUN ls -1 ${PHP_EXT_FOLDER}*.so | xargs strip --strip-debug

################################################################################################################
FROM baseline as runtime
ARG PHP_EXT_ESSENTIAL
ARG PHP_EXT_FOLDER
ARG TAG_NAME

# Make the log directory writable
RUN chmod ugo+w /var/log

# So we can handle signals properly (Cloud Run will send a SIGTERM), we'll need dumb-init
RUN apt-get install dumb-init

# Pull in all the built extensions
COPY --from=builder ${PHP_EXT_FOLDER}*.so ${PHP_EXT_FOLDER}

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

