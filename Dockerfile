# Extensions we'd like to add by default
## IMPORTANT - We are pinning to 1.66.0, as there seems to be asegfault bug in versions over this at the moment
## https://github.com/grpc/grpc/issues/38184

ARG PHP_EXT_ESSENTIAL="bcmath opcache mysqli pdo_mysql bz2 soap sockets zip gd intl yaml apcu protobuf memcached redis xhprof"

# Default PHP version
ARG BUILD_FRANKENPHP_VER="1.4.2"
ARG BUILD_PHP_VER="8.4.3"
ARG TAG_NAME="dev-master"

# Build
FROM dunglas/frankenphp:${BUILD_FRANKENPHP_VER}-php${BUILD_PHP_VER}
ARG PHP_EXT_ESSENTIAL
ARG TAG_NAME

# Workaround for noisy pecl E_STRICT
RUN sed -i '1 s/^.*$/<?php error_reporting(E_ALL ^ (E_DEPRECATED));/' /usr/local/lib/php/pearcmd.php

# Additional extensions here:
# frankenphp provides
# https://github.com/mlocati/docker-php-extension-installer
# Which ensures extensions are stripped of strings (small) and should not carry any extra 'dev' package weight
ENV IPE_DONT_ENABLE=1
RUN install-php-extensions ${PHP_EXT_ESSENTIAL} grpc-1.66.0 xdebug
RUN docker-php-ext-enable ${PHP_EXT_ESSENTIAL} grpc

# TODO - GD with jpeg, webp, freetype

ENV RUNPHP_FOUNDATION_VERSION=${TAG_NAME}