#!/bin/bash
# =============================================================================
# Script Name: install.sh
# Description: Installer for InkyRic E-Ink Slideshow
#              - Clones GitHub repo
#              - Installs dependencies
#              - Enables SPI
#              - Sets up systemd service to run slideshow on boot
# =============================================================================

set -e  # Exit immediately on error

# -----------------------------
# Configuration
# -----------------------------
APP_NAME="eink-slideshow"
INSTALL_DIR="/opt/eink"
VENV_DIR="$INSTALL_DIR/venv"
SERVICE_FILE="$APP_NAME.service"
SERVICE_TARGET="/etc/systemd/system/$SERVICE_FILE"
GITHUB_REPO="https://github.com/morelos-ricardo/InkyRic"
PYTHON_SCRIPT="$INSTALL_DIR/slideshow.py"

# -----------------------------
# Helper functions
# -----------------------------

# Ensure script is run as root
check_permissions() {
  if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this installer with sudo."
    exit 1
  fi
}

# Enable SPI interface (required for Inky)
enable_spi() {
  echo "Enabling SPI interface..."
  sed -i 's/^#*dtparam=spi=.*/dtparam=spi=on/' /boot/firmware/config.txt
  raspi-config nonint do_spi 0
}

# Install OS-level dependencies
install_apt_dependencies() {
  echo "Installing system dependencies..."
  apt-get update -y
  apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    libjpeg-dev \
    zlib1g-dev
}

# Clone or refresh repository
install_source() {
  echo "Installing application from GitHub..."
  rm -rf "$INSTALL_DIR"
  git clone "$GITHUB_REPO" "$INSTALL_DIR"
}

# Create Python virtual environment and install dependencies
create_venv() {
  echo "Creating virtual environment..."
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel
  "$VENV_DIR/bin/pip" install -r "$INSTALL_DIR/requirements.txt"
}

# Install systemd service
install_service() {
  echo "Installing systemd service..."

  cat <<EOF > "$SERVICE_TARGET"
[Unit]
Description=E-Ink Slideshow Service
After=network.target

[Service]
ExecStart=$VENV_DIR/bin/python $PYTHON_SCRIPT
WorkingDirectory=$INSTALL_DIR
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reexec
  systemctl daemon-reload
  systemctl enable "$APP_NAME"
}

# Ask user for reboot
ask_for_reboot() {
  echo ""
  read -p "Installation complete. Reboot now? (y/n): " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    reboot
  else
    echo "Reboot skipped. Please reboot manually later."
  fi
}

# -----------------------------
# Main installation flow
# -----------------------------
check_permissions
install_apt_dependencies
enable_spi
install_source
create_venv
install_service

echo "Installation finished successfully."
ask_for_reboot
