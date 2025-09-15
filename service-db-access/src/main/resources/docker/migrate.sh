#!/usr/bin/env bash
set -e

perform_migration () {
    /opt/flyway/flyway migrate \
        -user="$DB_USERNAME" \
        -password="$DB_PASSWORD" \
        -url="$DB_URL" \
        -locations=filesystem:/opt/java-base/sql \
        -reportEnabled=false
}

if [[ -n "${BASELINE_VERSION}" ]]; then
    /opt/flyway/flyway baseline \
        -user="$DB_USERNAME" \
        -password="$DB_PASSWORD" \
        -url="$DB_URL" \
        -locations=filesystem:/opt/java-base/sql \
        -baselineVersion="$BASELINE_VERSION"\
        -reportEnabled=false
    perform_migration
else
    perform_migration
fi
