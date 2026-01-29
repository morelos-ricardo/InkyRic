#!/usr/bin/env bash
set -e

echo "=== InkyRic Installer ==="

APP_DIR="/opt/eink"
IMAGE_DIR="$APP_DIR/images"
SERVICE_NAME="eink-slideshow"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
PYTHON_SCRIPT="$APP_DIR/slideshow.py"

RUN_USER="$(logname)"

# --------------------------
# System dependencies
# --------------------------
echo "[1/7] Installing system packages..."
sudo apt update
sudo apt install -y \
    python3-full \
    python3-venv \
    python3-pip \
    git \
    libopenjp2-7 \
    libjpeg-dev \
    libfreetype6-dev \
    libatlas-base-dev

# --------------------------
# Directory structure
# --------------------------
echo "[2/7] Preparing directories..."
sudo mkdir -p "$APP_DIR" "$IMAGE_DIR"
sudo chown -R "$RUN_USER:$RUN_USER" "$APP_DIR"

# --------------------------
# Virtual environment
# --------------------------
echo "[3/7] Creating Python virtual environment..."
cd "$APP_DIR"

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install pillow inky[rpi]

# --------------------------
# SPI enable
# --------------------------
echo "[4/7] Enabling SPI..."
sudo sed -i 's/^#*dtparam=spi=.*/dtparam=spi=on/' /boot/firmware/config.txt
sudo raspi-config nonint do_spi 0

# --------------------------
# systemd service
# --------------------------
echo "[5/7] Installing systemd service..."

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=InkyRic E-Ink Slideshow
After=network.target

[Service]
User=$RUN_USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python $PYTHON_SCRIPT
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

# --------------------------
# Verification
# --------------------------
echo "[6/7] Verifying installation..."

[ -d "$APP_DIR/venv" ] || { echo "❌ venv missing"; exit 1; }
systemctl is-active --quiet $SERVICE_NAME || { echo "❌ service not running"; exit 1; }

echo "[7/7] Done."

echo "✅ Installation complete."
echo "📂 Put images in: $IMAGE_DIR"
echo "🔁 Reboot recommended for SPI changes."
