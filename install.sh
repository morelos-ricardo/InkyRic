#!/bin/bash

# =============================================================================
# Automatic Installer for E-Ink Slideshow from GitHub
# =============================================================================

set -e  # Exit on errors

# GitHub repository
GITHUB_REPO="https://github.com/morelos-ricardo/InkyRic"
APP_DIR="/opt/eink"
IMAGE_DIR="$APP_DIR/images"
SERVICE_FILE="$APP_DIR/eink-slideshow.service"
PYTHON_SCRIPT="$APP_DIR/slideshow.py"

echo "Removing any existing installation..."
sudo rm -rf "$APP_DIR"

echo "Cloning repository from GitHub..."
sudo git clone "$GITHUB_REPO" "$APP_DIR"

# Ensure images folder exists
mkdir -p "$IMAGE_DIR"

# Update OS packages
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get install -y python3-pip python3-pil python3-pil.imagetk python3-pil.imagetk libjpeg-dev git

# Install Inky library (adjust if using Spectra 6)
echo "Installing Inky library..."
sudo pip3 install inky==2.2.1 pillow==12.0.0

# Enable SPI interface
echo "Enabling SPI interface..."
sudo sed -i 's/^#*dtparam=spi=.*/dtparam=spi=on/' /boot/firmware/config.txt
sudo raspi-config nonint do_spi 0

# Make sure Python script is executable
sudo chmod +x "$PYTHON_SCRIPT"

# Install systemd service
echo "Installing systemd service..."
sudo cp "$SERVICE_FILE" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable eink-slideshow
sudo systemctl start eink-slideshow
echo "Service installed, enabled, and started."

echo "Installation complete!"
echo "Put your images into $IMAGE_DIR if not already present. They will display automatically on boot."
