#!/bin/bash
set -e

# PostgreSQL Database Migration Script
# AWS → Huawei Cloud
# Author: George Ajay

# ====== CONFIGURATION ======
SRC_HOST="your-aws-endpoint.amazonaws.com"
SRC_PORT=5432
SRC_USER="postgres"
SRC_DB="georgedb"

DST_HOST="your-huawei-db-host"
DST_PORT=5432
DST_USER="postgres"
DST_DB="georgedb"

BACKUP_FILE="georgedb_backup_$(date +%F_%H%M%S).dump"
LOCAL_BACKUP_DIR="/tmp"

# ====== STEP 0: Prompt for Passwords ======
echo "🔐 Enter AWS PostgreSQL password:"
read -s SRC_PASSWORD
echo "🔐 Enter Huawei PostgreSQL password:"
read -s DST_PASSWORD
echo

# ====== STEP 1: Perform pg_dump from AWS RDS ======
echo "📦 Starting PostgreSQL backup from AWS (within VPC, no SSL needed)..."
PGPASSWORD="$SRC_PASSWORD" pg_dump \
  -h "$SRC_HOST" \
  -p "$SRC_PORT" \
  -U "$SRC_USER" \
  -d "$SRC_DB" \
  --format=custom \
  --blobs \
  --verbose \
  -f "$LOCAL_BACKUP_DIR/$BACKUP_FILE"

echo "✅ Backup completed: $LOCAL_BACKUP_DIR/$BACKUP_FILE"

# ====== STEP 2: Create destination database (if not exists) ======
echo "🛠️  Creating destination database (if not exists, using SSL)..."
PGPASSWORD="$DST_PASSWORD" createdb \
  -h "$DST_HOST" \
  -p "$DST_PORT" \
  -U "$DST_USER" \
  --sslmode=require \
  "$DST_DB" 2>/dev/null || echo "Database already exists."

# ====== STEP 3: Restore dump into Huawei Cloud DB ======
echo "🔄 Restoring backup into Huawei Cloud PostgreSQL (encrypted in transit)..."
PGPASSWORD="$DST_PASSWORD" pg_restore \
  -h "$DST_HOST" \
  -p "$DST_PORT" \
  -U "$DST_USER" \
  -d "$DST_DB" \
  --sslmode=require \
  --jobs=4 \
  --verbose \
  "$LOCAL_BACKUP_DIR/$BACKUP_FILE"

echo "🎉 Migration completed successfully over SSL/TLS!"
