#!/bin/bash
# =============================================================================
# Uninstall, Delete old clone, and Re-clone the InkyRic repository
# =============================================================================

# -------------------------------
# CONFIGURATION
# -------------------------------
# Repository URL
REPO_URL="https://github.com/morelos-ricardo/InkyRic.git"

# Target clone directory (old repo location)
CLONE_DIR="/home/rma/InkyRic"

# Keep this script safe
SCRIPT_NAME="Uninstall_Delete_Reclone.sh"
SCRIPT_PATH="$(realpath "$0")"

# -------------------------------
# Utility functions
# -------------------------------
echo_header() {
    bold=$(tput bold)
    normal=$(tput sgr0)
    echo -e "${bold}$1${normal}"
}

echo_success() {
    echo -e "[\e[32m✔\e[0m] $1"
}

echo_error() {
    echo -e "[\e[31m✖\e[0m] $1"
}

check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        echo_error "This script must be run with sudo/root privileges."
        exit 1
    fi
}

# -------------------------------
# MAIN SCRIPT
# -------------------------------
check_permissions

echo_header "Starting Uninstall / Delete / Re-clone process..."

# Stop any running service first (if it exists)
if systemctl list-units --full -all | grep -q "inkypi.service"; then
    echo "Stopping inkypi service..."
    systemctl stop inkypi.service
    systemctl disable inkypi.service
fi

# Remove old systemd service file if exists
if [ -f "/etc/systemd/system/inkypi.service" ]; then
    echo "Removing old systemd service..."
    rm -f /etc/systemd/system/inkypi.service
    systemctl daemon-reload
fi

# Remove old virtual environment
if [ -d "$CLONE_DIR/venv_inkypi" ]; then
    echo "Removing old Python virtual environment..."
    rm -rf "$CLONE_DIR/venv_inkypi"
fi

# Delete everything in the clone directory except this script
if [ -d "$CLONE_DIR" ]; then
    echo "Cleaning old clone directory: $CLONE_DIR"
    find "$CLONE_DIR" -mindepth 1 ! -name "$SCRIPT_NAME" -exec rm -rf {} +
fi

# Clone fresh repository
echo "Cloning fresh repository into $CLONE_DIR..."
git clone "$REPO_URL" "$CLONE_DIR" || {
    echo_error "Failed to clone repository. Check network/URL."
    exit 1
}

echo_success "Repository successfully cloned."

echo_header "Uninstall/Delete/Re-clone process completed."
echo "You can now run the install.sh script in the cloned repository to set up the environment."
