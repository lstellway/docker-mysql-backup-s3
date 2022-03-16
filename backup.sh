#!/bin/bash

# Create temporary directory
DIR=$(mktemp -d)
DATE_VALUE=$(date '-R')
DATE_DAY=$(date '+%F')
DATE_TIME=$(date '+%FT%T')
S3_ENDPOINT="${S3_ENDPOINT}"

# Helper to fail with message
_fatal() {
  printf "Fatal: %s\n" "$@" >&2
  exit 1
}

# Cleanup
# Arguments
#   1) Directory to save files to
_cleanup() {
    [ -d "${DIR}" ] && rm -rf "${DIR}"
}

# Bootstrap using a configuration file
_bootstrap() {
    # Get secret values from files
    [ -r "${DB_PASS_FILE}" ] && DB_PASS=$(cat "${DB_PASS_FILE}")
    [ -r "${S3_ACCESS_KEY_FILE}" ] && S3_ACCESS_KEY=$(cat "${S3_ACCESS_KEY_FILE}")
    [ -r "${S3_ACCESS_SECRET_FILE}" ] && S3_ACCESS_SECRET=$(cat "${S3_ACCESS_SECRET_FILE}")

    # Set the default region
    if [ -z "${S3_ENDPOINT}" ]; then
        S3_ENDPOINT="${S3_BUCKET}.s3-website.${S3_REGION:-us-east-1}.amazonaws.com"
    fi

    # Ensure variables are set
    [ -z "${BACKUP_DATABASES}" ] && _fatal "'BACKUP_DATABASES' not set"
    [ -z "${DB_USER}" ] && _fatal "'DB_USER' not set"
    [ -z "${DB_PASS}" ] && _fatal "'DB_PASS' not set"
    [ -z "${S3_BUCKET}" ] && _fatal "'S3_BUCKET' not set"
    [ -z "${S3_ACCESS_KEY}" ] && _fatal "'S3_ACCESS_KEY' not set"
    [ -z "${S3_ACCESS_SECRET}" ] && _fatal "'S3_ACCESS_SECRET' not set"
}

# Export database data
# Arguments
#   1) Directory to save files to
_export_db() {
    local WORKDIR="${1}"
    [ -n "${WORKDIR}" ] || _fatal "No directory specified for exports."

    local -a DATABASES
    IFS=',' read -ra DATABASES <<< "${BACKUP_DATABASES}"

    for DB in "${DATABASES[@]}"; do
        mysqldump \
            --user="${DB_USER}" \
            --password="${DB_PASS}" \
            --host="${DB_HOST:-localhost}" \
            --port="${DB_PORT:-3306}" \
            "${DB}" > "${WORKDIR}/${DB}.sql" || _fatal "Could not backup database '${DB}'"
    done
}

# Run the backup job
# Arguments
#   1) Directory to read files from
function _backup() {
    local WORKDIR="${1}"
    [ -n "${WORKDIR}" ] || _fatal "No directory specified for uploads."

    local -a FILES
    FILES=$(ls ${WORKDIR}/*.sql)

    # Only continue if files have been written
    if [ "${#FILES[@]}" -gt 0 ]; then
        # Compress backup
        FILE_NAME="db-backups_${DATE_TIME}.tar.gz"
        FILE="/tmp/${FILE_NAME}"
        tar -zcf "${FILE}" -C "${WORKDIR}" . || _fatal "An error occurred while compressing the backup files."
        mv "${FILE}" "${WORKDIR}/${FILE_NAME}"
        FILE="${WORKDIR}/${FILE_NAME}"

        # Build signature
        CONTENT_TYPE="application/x-compressed-tar"
        RESOURCE="/${S3_BUCKET}/${DATE_DAY}/${FILE_NAME}"
        SIGNATURE=$(printf "PUT\n\n%s\n%s\n%s" "${CONTENT_TYPE}" "${DATE_VALUE}" "${RESOURCE}" | openssl sha1 -hmac "${S3_ACCESS_SECRET}" -binary | base64)

        # Upload file
        printf "Uploading '%s'\n" "${RESOURCE}"
        curl -X PUT -T "${FILE}" \
            -H "Host: ${S3_ENDPOINT}" \
            -H "Date: ${DATE_VALUE}" \
            -H "Content-Type: ${CONTENT_TYPE}" \
            -H "Authorization: AWS ${S3_ACCESS_KEY}:${SIGNATURE}" \
            "${S3_PROTOCOL:-https}://${S3_ENDPOINT}${RESOURCE}" || _fatal "An error occurred while uploading the file."
        printf "Successfully uploaded '%s'\n" "${RESOURCE}"
    fi
}

trap _cleanup EXIT
_bootstrap
_export_db "${DIR}"
_backup "${DIR}"
_cleanup
