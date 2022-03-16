ARG ALPINE_VERSION=3.15.0
FROM alpine:${ALPINE_VERSION}

ENV BACKUP_DATABASES= \
    DB_USER= \
    DB_PASS= \
    DB_HOST=localhost \
    DB_PORT=3306 \
    S3_PROTOCOL=https \
    S3_REGION= \
    S3_BUCKET= \
    S3_ENDPOINT= \
    S3_ACCESS_KEY= \
    S3_ACCESS_SECRET=

COPY backup.sh /etc/periodic/daily/backup

RUN apk update \
    && apk add --no-cache bash curl mysql-client openssl \
    && chmod +x /etc/periodic/daily/backup

CMD [ "crond", "-f" ]
