#!/bin/bash
# Installation script for PostgreSQL S3 Backup System
# Run this script on your production server

set -e

echo "==================================="
echo "PostgreSQL S3 Backup - Installation"
echo "==================================="
echo ""

# Get the directory where this script is located
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for required tools
echo "Checking dependencies..."

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "ERROR: $1 is not installed. Please install it first."
        exit 1
    fi
    echo "  ✓ $1 found"
}

check_command pg_dump
check_command aws
check_command curl
check_command gzip

echo ""
echo "All dependencies are installed."
echo ""

# Create logs directory
mkdir -p "${INSTALL_DIR}/logs"

# Make scripts executable
chmod +x "${INSTALL_DIR}/scripts/backup.sh"
chmod +x "${INSTALL_DIR}/scripts/setup-s3-versioning.sh"

# Check if .env exists
if [ ! -f "${INSTALL_DIR}/config/.env" ]; then
    echo "Creating config/.env from template..."
    cp "${INSTALL_DIR}/config/.env.example" "${INSTALL_DIR}/config/.env"
    echo ""
    echo "IMPORTANT: Please edit ${INSTALL_DIR}/config/.env with your credentials"
    echo ""
fi

# Set secure permissions on config
chmod 600 "${INSTALL_DIR}/config/.env" 2>/dev/null || true
chmod 600 "${INSTALL_DIR}/config/.env.example"

echo "==================================="
echo "Installation complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Edit your configuration:"
echo "   nano ${INSTALL_DIR}/config/.env"
echo ""
echo "2. Enable S3 versioning (run once):"
echo "   ${INSTALL_DIR}/scripts/setup-s3-versioning.sh"
echo ""
echo "3. Test the backup manually:"
echo "   ${INSTALL_DIR}/scripts/backup.sh"
echo ""
echo "4. Set up the cron job (every 2 hours):"
echo "   crontab -e"
echo "   Add: 0 */2 * * * ${INSTALL_DIR}/scripts/backup.sh >> ${INSTALL_DIR}/logs/cron.log 2>&1"
echo ""
