#!/bin/bash
set -e

APP_DIR="/opt/eink"
SERVICE_NAME="eink-slideshow.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

echo "🔴 Starting uninstall process..."

# Stop service if running
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "Stopping service..."
    sudo systemctl stop $SERVICE_NAME
else
    echo "Service not running."
fi

# Disable service
if systemctl is-enabled --quiet $SERVICE_NAME; then
    echo "Disabling service..."
    sudo systemctl disable $SERVICE_NAME
else
    echo "Service already disabled."
fi

# Remove service file
if [ -f "$SERVICE_FILE" ]; then
    echo "Removing systemd service file..."
    sudo rm -f "$SERVICE_FILE"
else
    echo "Service file already removed."
fi

sudo systemctl daemon-reload

# Remove application directory
if [ -d "$APP_DIR" ]; then
    echo "Removing application directory..."
    sudo rm -rf "$APP_DIR"
else
    echo "Application directory already removed."
fi

echo "🔍 Verifying uninstall..."

ERRORS=0

[ -d "$APP_DIR" ] && echo "❌ $APP_DIR still exists" && ERRORS=1
[ -f "$SERVICE_FILE" ] && echo "❌ Service file still exists" && ERRORS=1
systemctl list-unit-files | grep -q "$SERVICE_NAME" && echo "❌ Service still registered" && ERRORS=1

if [ "$ERRORS" -eq 0 ]; then
    echo "✅ Uninstall completed successfully."
    exit 0
else
    echo "❌ Uninstall incomplete."
    exit 1
fi
