#!/bin/bash
# =============================================================================
# FULL RESET SCRIPT
# Stops service, removes installation, deletes repo, reclones fresh copy
# =============================================================================

# -------------------------------
# CONFIGURATION
# -------------------------------
REPO_URL="https://github.com/morelos-ricardo/InkyRic.git"
CLONE_DIR="/home/rma/InkyRic"
INSTALL_DIR="/usr/local/inkypi"
EXECUTABLE_PATH="/usr/local/bin/inkypi"
SERVICE_NAME="inkypi.service"

# -------------------------------
# REQUIRE ROOT
# -------------------------------
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo."
    exit 1
fi

echo "Starting FULL uninstall / delete / reclone process..."

# -------------------------------
# STOP AND DISABLE SERVICE
# -------------------------------
if systemctl list-unit-files | grep -q "$SERVICE_NAME"; then
    echo "Stopping $SERVICE_NAME..."
    systemctl stop "$SERVICE_NAME" 2>/dev/null
    systemctl disable "$SERVICE_NAME" 2>/dev/null
fi

# -------------------------------
# REMOVE SYSTEMD SERVICE FILE
# -------------------------------
if [ -f "/etc/systemd/system/$SERVICE_NAME" ]; then
    echo "Removing systemd service file..."
    rm -f "/etc/systemd/system/$SERVICE_NAME"
    systemctl daemon-reload
fi

# -------------------------------
# REMOVE INSTALL DIRECTORY
# -------------------------------
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing install directory: $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
fi

# -------------------------------
# REMOVE EXECUTABLE
# -------------------------------
if [ -f "$EXECUTABLE_PATH" ]; then
    echo "Removing executable: $EXECUTABLE_PATH"
    rm -f "$EXECUTABLE_PATH"
fi

# -------------------------------
# DELETE ENTIRE REPO DIRECTORY
# -------------------------------
if [ -d "$CLONE_DIR" ]; then
    echo "Removing old repository directory: $CLONE_DIR"
    rm -rf "$CLONE_DIR"
fi

# -------------------------------
# CLONE FRESH COPY
# -------------------------------
echo "Cloning fresh repository..."
git clone "$REPO_URL" "$CLONE_DIR"

if [ $? -ne 0 ]; then
    echo "Git clone failed. Check network connection."
    exit 1
fi

echo "Repository successfully recloned."
echo "Reset process complete."
echo "You can now run:"
echo "cd $CLONE_DIR/install && sudo bash install.sh"
