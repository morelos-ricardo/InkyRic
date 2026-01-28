#!/bin/bash

# =============================================================================
# Minimal Installer for E-Ink Slideshow
# =============================================================================

set -e  # Exit on errors

# Paths
APP_DIR="/opt/eink"
IMAGE_DIR="$APP_DIR/images"
SERVICE_FILE="$APP_DIR/eink-slideshow.service"
PYTHON_SCRIPT="$APP_DIR/slideshow.py"

echo "Creating application directory..."
mkdir -p "$APP_DIR"
mkdir -p "$IMAGE_DIR"

# Update OS packages
echo "Updating system packages..."
apt-get update -y
apt-get install -y python3-pip python3-pil python3-pil.imagetk python3-pil.imagetk libjpeg-dev git

# Install Inky library (adjust if using Spectra 6)
echo "Installing Inky library..."
pip3 install --upgrade inky[rpi]

# Enable SPI interface
echo "Enabling SPI interface..."
sed -i 's/^#*dtparam=spi=.*/dtparam=spi=on/' /boot/firmware/config.txt
raspi-config nonint do_spi 0

# Copy Python script
echo "Copying slideshow.py..."
cp slideshow.py "$PYTHON_SCRIPT"
chmod +x "$PYTHON_SCRIPT"

# Copy systemd service file
echo "Installing systemd service..."
cp eink-slideshow.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable eink-slideshow
systemctl start eink-slideshow
echo "Service installed, enabled, and started."

echo "Installation complete!"
echo "Put your images into $IMAGE_DIR and they will display automatically."
