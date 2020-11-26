# Foundation Docker Image, PHP for Google Cloud Run Toolkit

This is the baseline Docker image for the [runphp](https://github.com/thinkfluent/runphp) Serverless PHP Toolkit for Google Cloud Run.

## Local Build

```bash
docker build -t runphp-foundation .
```
```bash
docker run --rm -p8080:80 -ePORT=80 runphp-foundation:latest
```

```bash
export RUNPHP_REV=v0.4.11 && \
docker tag runphp-foundation:latest eu.gcr.io/thinkfluent/runphp-foundation:${RUNPHP_REV} && \
docker push eu.gcr.io/thinkfluent/runphp-foundation:${RUNPHP_REV} && \
gcloud run deploy runphp-foundation \
    --image=eu.gcr.io/thinkfluent/runphp-foundation:${RUNPHP_REV} \
    --revision-suffix=${RUNPHP_REV//\./-} \
    --platform managed \
    --allow-unauthenticated \
    --region europe-west1 \
    --project thinkfluent
```