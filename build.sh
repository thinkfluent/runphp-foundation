#!/usr/bin/env bash

# Args
while getopts ":v:t:" opt; do
  case $opt in
    v) BUILD_PHP_VER="$OPTARG"
    ;;
    t) BUILD_TAG="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# And some defaults
: ${BUILD_PHP_VER:=7.4.33}
: ${BUILD_TAG:=dev}

# PHP ext folder
PHP_EXT_FOLDER=/usr/local/lib/php/extensions
case ${BUILD_PHP_VER:0:3} in
  7.4) PHP_EXT_FOLDER="${PHP_EXT_FOLDER}/no-debug-non-zts-20190902/"
  ;;
  8.0) PHP_EXT_FOLDER="${PHP_EXT_FOLDER}/no-debug-non-zts-20200930/"
  ;;
  8.1) PHP_EXT_FOLDER="${PHP_EXT_FOLDER}/no-debug-non-zts-20210902/"
  ;;
  8.2) PHP_EXT_FOLDER="${PHP_EXT_FOLDER}/no-debug-non-zts-20220829/"
  ;;
  *) echo "Unsupported PHP version" >&2
  exit 1
  ;;
esac


# Fully qualified tag
RUNPHP_REV="${BUILD_PHP_VER}-${BUILD_TAG}"
export RUNPHP_REV

# Use the current folder context for the build
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Building ${RUNPHP_REV}..."
docker build \
  --build-arg TAG_NAME=${RUNPHP_REV} \
  --build-arg BUILD_PHP_VER=${BUILD_PHP_VER} \
  --build-arg PHP_EXT_FOLDER=${PHP_EXT_FOLDER} \
  -t runphp-foundation:${RUNPHP_REV} ${SCRIPT_DIR}
