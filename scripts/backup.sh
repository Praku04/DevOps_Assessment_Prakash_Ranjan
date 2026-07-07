#!/usr/bin/env bash
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-devops_assessment_postgres}"
DB_NAME="${DB_NAME:-insurance_db}"
DB_USER="${DB_USER:-insurance_user}"
BACKUP_DIR="${BACKUP_DIR:-backups}"

mkdir -p "${BACKUP_DIR}"

timestamp="$(date +%Y%m%d_%H%M%S)"
backup_file="${BACKUP_DIR}/${DB_NAME}_${timestamp}.dump"

docker exec "${DB_CONTAINER}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" -Fc > "${backup_file}"

echo "Created backup: ${backup_file}"
