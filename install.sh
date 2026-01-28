#!/usr/bin/env bash
set -e

echo "=== InkyRic Installer ==="

# --------------------------
# Variables
# --------------------------
APP_DIR="/opt/eink"
IMAGE_DIR="$APP_DIR/images"
SERVICE_FILE="$APP_DIR/eink-slideshow.service"
PYTHON_SCRIPT="$APP_DIR/slideshow.py"
GITHUB_REPO="https://github.com/morelos-ricardo/InkyRic"

# --------------------------
# System update and dependencies
# --------------------------
echo "[1/7] Installing system packages..."
sudo apt update
sudo apt install -y \
    python3 \
    python3-full \
    python3-venv \
    python3-pip \
    git \
    libopenjp2-7 \
    libjpeg-dev \
    libfreetype6-dev \
    libatlas-base-dev

# --------------------------
# Create application directories
# --------------------------
echo "[2/7] Creating application directories..."
sudo mkdir -p "$APP_DIR"
sudo mkdir -p "$IMAGE_DIR"
sudo chown -R $USER:$USER "$APP_DIR"

# --------------------------
# Copy repository files
# --------------------------
echo "[3/7] Cloning repository files..."
git clone "$GITHUB_REPO" "$APP_DIR/temp_clone" || true
cp "$APP_DIR/temp_clone/slideshow.py" "$APP_DIR/"
rm -rf "$APP_DIR/temp_clone"

# --------------------------
# Create virtual environment
# --------------------------
echo "[4/7] Creating Python virtual environment..."
cd "$APP_DIR"
python3 -m venv venv
source venv/bin/activate

# --------------------------
# Install Python dependencies
# --------------------------
echo "[5/7] Installing Python dependencies..."
pip install --upgrade pip
pip install pillow inky[rpi]

# --------------------------
# Enable SPI interface
# --------------------------
echo "[6/7] Enabling SPI interface..."
sudo sed -i 's/^#*dtparam=spi=.*/dtparam=spi=on/' /boot/firmware/config.txt
sudo raspi-config nonint do_spi 0

# --------------------------
# Setup systemd service
# --------------------------
echo "[7/7] Installing systemd service..."
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=InkyRic Slideshow
After=network.target

[Service]
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python $PYTHON_SCRIPT
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo cp "$SERVICE_FILE" /etc/systemd/system/eink-slideshow.service
sudo systemctl daemon-reload
sudo systemctl enable eink-slideshow
sudo systemctl start eink-slideshow

echo "=== Installation complete! ==="
echo "Put your images into $IMAGE_DIR if not already present. They will display automatically on boot."
