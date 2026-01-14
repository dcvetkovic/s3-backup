#!/usr/bin/env bash
set -e

# Ensure we're running in bash
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires bash. Run with: bash $0"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables
ENV_FILE="${PROJECT_DIR}/config/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file not found at $ENV_FILE"
    exit 1
fi
. "$ENV_FILE"

# Configuration
BACKUP_DIR="/tmp/pg_backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql.gz"
S3_DEST="${S3_PATH}/backup_${TIMESTAMP}.sql.gz"
LOG_FILE="${PROJECT_DIR}/logs/backup.log"

# Create directories if they don't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Telegram notification function
send_telegram_notification() {
    local message="$1"
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="$message" \
            -d parse_mode="HTML" > /dev/null 2>&1
    fi
}

# Cleanup function
cleanup() {
    rm -f "$BACKUP_FILE"
    log "Cleaned up temporary backup file"
}

# Error handler
error_handler() {
    local exit_code=$?
    local line_number=$1
    log "ERROR: Backup failed at line $line_number with exit code $exit_code"

    # Send Telegram notification
    local hostname=$(hostname)
    local last_logs=$(tail -5 "$LOG_FILE" 2>/dev/null | head -4 || echo "No logs available")
    local error_message="🚨🚨🚨 <b>DATABASE BACKUP FAILED</b> 🚨🚨🚨

⚠️ <b>IMMEDIATE ATTENTION REQUIRED</b> ⚠️

<b>Server:</b> ${hostname}
<b>Database:</b> ${PGDATABASE}
<b>Host:</b> ${PGHOST}:${PGPORT}
<b>S3 Target:</b> s3://${S3_BUCKET}/${S3_DEST}
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S')
<b>Exit Code:</b> ${exit_code}
<b>Failed At:</b> Line ${line_number}

<b>Recent Logs:</b>
<pre>${last_logs}</pre>"

    send_telegram_notification "$error_message"
    cleanup
    exit $exit_code
}

# Set up error trap
trap 'error_handler $LINENO' ERR

# Main backup process
main() {
    log "Starting PostgreSQL backup for database: $PGDATABASE"

    # Export PostgreSQL password for pg_dump
    export PGPASSWORD="$PGPASSWORD"

    # Create backup using pg_dump with compression
    log "Creating database dump..."
    pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$PGDATABASE" | gzip > "$BACKUP_FILE"

    # Verify backup file exists and has content
    if [ ! -s "$BACKUP_FILE" ]; then
        log "ERROR: Backup file is empty or doesn't exist"
        exit 1
    fi

    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "Backup created successfully. Size: $BACKUP_SIZE"

    # Upload to S3
    log "Uploading backup to S3: s3://${S3_BUCKET}/${S3_DEST}"

    # Configure AWS CLI with credentials
    export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
    export AWS_DEFAULT_REGION="$AWS_REGION"

    # Upload to S3
    aws s3 cp "$BACKUP_FILE" "s3://${S3_BUCKET}/${S3_DEST}" \
        --storage-class STANDARD_IA

    log "Backup uploaded successfully to S3"

    # Cleanup
    cleanup

    # Send success notification
    local hostname=$(hostname)
    local success_message="✅ <b>Database Backup Successful</b>

<b>Server:</b> ${hostname}
<b>Database:</b> ${PGDATABASE}
<b>Size:</b> ${BACKUP_SIZE}
<b>Time:</b> $(date '+%Y-%m-%d %H:%M:%S')
<b>Location:</b> s3://${S3_BUCKET}/${S3_DEST}"

    send_telegram_notification "$success_message"

    log "Backup completed successfully"
}

# Run main function
main
