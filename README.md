# Foundation Stage, PHP for Google Cloud Run Toolkit

This is the baseline Docker image for the [runphp](https://github.com/thinkfluent/runphp) Serverless PHP Toolkit for Google Cloud Run.

**All the documentation and guides [are here](https://github.com/thinkfluent/runphp)**

## Build
Local builds can be performed as follows

```bash
docker build \
  --platform linux/amd64 \
  --build-arg TAG_NAME=dev \
  --build-arg BUILD_PHP_VER=8.4.6 \
  -t runphp-foundation:dev .
```
