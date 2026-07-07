#!/usr/bin/env bash
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-devops_assessment_postgres}"
DB_USER="${DB_USER:-insurance_user}"
RESTORE_DB="${RESTORE_DB:-insurance_db_restored}"
BACKUP_DIR="${BACKUP_DIR:-backups}"

backup_file="${1:-}"

if [[ -z "${backup_file}" ]]; then
  backup_file="$(ls -1t "${BACKUP_DIR}"/*.dump 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "${backup_file}" || ! -f "${backup_file}" ]]; then
  echo "No backup file found. Run ./scripts/backup.sh first or pass a dump path." >&2
  exit 1
fi

docker exec "${DB_CONTAINER}" psql -U "${DB_USER}" -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS ${RESTORE_DB};"
docker exec "${DB_CONTAINER}" psql -U "${DB_USER}" -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE ${RESTORE_DB};"

docker exec -i "${DB_CONTAINER}" pg_restore -U "${DB_USER}" -d "${RESTORE_DB}" --clean --if-exists < "${backup_file}"

echo "Restored ${backup_file} into database ${RESTORE_DB}"
