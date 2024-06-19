# Foundation Stage, PHP for Google Cloud Run Toolkit

This is the baseline Docker image for the [runphp](https://github.com/thinkfluent/runphp) Serverless PHP Toolkit for Google Cloud Run.

**All the documentation and guides [are here](https://github.com/thinkfluent/runphp)**

## Build
Local builds can be performed as follows

```bash
docker build \
  --build-arg TAG_NAME=dev \
  --build-arg BUILD_PHP_VER=8.3.7 \
  -t runphp-foundation:dev .
```

Or, for multi-arch builds
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg TAG_NAME=${RUNPHP_REV} \
  --build-arg BUILD_PHP_VER=${BUILD_PHP_VER} \
  -t runphp-foundation:dev .
```