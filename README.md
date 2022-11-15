# Foundation Docker Image, PHP for Google Cloud Run Toolkit

This is the baseline Docker image for the [runphp](https://github.com/thinkfluent/runphp) Serverless PHP Toolkit for Google Cloud Run.

## Build
Local builds can be performed as follows

```bash
./build.sh -v 7.4.33 -t dev
./build.sh -v 8.0.25 -t dev
./build.sh -v 8.1.12 -t dev
./build.sh -v 8.2-rc -t dev
```