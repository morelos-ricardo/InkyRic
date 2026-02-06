#!/bin/bash
# =============================================================================
# Automatic Installer for E-Ink Slideshow (old style + useful functions)
# =============================================================================

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)

set -e  # Exit on error


APPNAME="InkyRic"
APP_DIR="/usr/local/$APPNAME"
GITHUB_REPO="https://github.com/morelos-ricardo/InkyRic"
IMAGE_DIR="$APP_DIR/images"
SERVICE_FILE="$APP_DIR/eink-slideshow.service"
PYTHON_SCRIPT="$APP_DIR/slideshow.py"
REQUIREMENTS_FILE="$APP_DIR/requirements.txt"
VENV_PATH="$APP_DIR/venv_inkypi"

# -------------------------------
# Utility functions
# -------------------------------

# Show a spinner/loader while a background process runs
show_loader() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\'
  printf "$1 [${spinstr:0:1}] "
  while ps a | awk '{print $1}' | grep -q "${pid}"; do
    local temp=${spinstr#?}
    printf "\r$1 [${temp:0:1}] "
    spinstr=${temp}${spinstr%"${temp}"}
    sleep ${delay}
  done
  if [[ $? -eq 0 ]]; then
    printf "\r$1 [\e[32m\xE2\x9C\x94\e[0m]\n"
  else
    printf "\r$1 [\e[31m\xE2\x9C\x98\e[0m]\n"
  fi
  
}

echo_success() { echo -e "$1 [\e[32m\xE2\x9C\x94\e[0m]"; }
echo_error() { echo -e "${red}$1${normal} [\e[31m\xE2\x9C\x98\e[0m]\n"; }
echo_header() { echo -e "${bold}$1${normal}"; }


# Enable SPI and I2C interfaces (needed for Inky displays)
enable_interfaces(){
  echo "Enabling interfaces required for E-Ink slideshow..."
  # Enable SPI
  sudo sed -i 's/^dtparam=spi=.*/dtparam=spi=on/' /boot/firmware/config.txt
  sudo sed -i 's/^#dtparam=spi=.*/dtparam=spi=on/' /boot/firmware/config.txt
  sudo raspi-config nonint do_spi 0
  echo_success "\tSPI Interface enabled"

  # Enable I2C
  sudo sed -i 's/^dtparam=i2c_arm=.*/dtparam=i2c_arm=on/' /boot/firmware/config.txt
  sudo sed -i 's/^#dtparam=i2c_arm=.*/dtparam=i2c_arm=on/' /boot/firmware/config.txt
  sudo raspi-config nonint do_i2c 0
  echo_success "\tI2C Interface enabled"
}



check_permissions() {
  # Ensure the script is run with sudo
  if [ "$EUID" -ne 0 ]; then
    echo_error "ERROR: Installation requires root privileges. Please run it with sudo."
    exit 1
  fi
}




# create Python virtual environment (not used in service yet)
create_venv(){
  echo "Creating Python virtual environment at $VENV_PATH ..."
  python3 -m venv "$VENV_PATH"
  $VENV_PATH/bin/python -m pip install --upgrade pip setuptools wheel > /dev/null
  show_loader "\tInstalling Python packages in virtual environment..."
  $VENV_PATH/bin/python -m pip install -r $REQUIREMENTS_FILE > /dev/null &
  show_loader "\tFinished installing python dependencies."
}



ask_for_reboot() {
  # Get hostname and IP address
  hostname=$(get_hostname)
  ip_address=$(get_ip_address)
  echo_header "$(echo_success "${APPNAME^^} Installation Complete!")"
  echo_header "[•] A reboot of your Raspberry Pi is required for the changes to take effect"
  echo_header "[•] After your Pi is rebooted, you can access the web UI by going to $(echo_blue "'$hostname.local'") or $(echo_blue "'$ip_address'") in your browser."
  echo_header "[•] If you encounter any issues or have suggestions, please submit them here: https://github.com/fatihak/InkyPi/issues"

  read -p "Would you like to restart your Raspberry Pi now? [Y/N] " userInput
  userInput="${userInput^^}"

  if [[ "${userInput,,}" == "y" ]]; then
    echo_success "You entered 'Y', rebooting now..."
    sleep 2
    sudo reboot now
  elif [[ "${userInput,,}" == "n" ]]; then
    echo "Please restart your Raspberry Pi later to apply changes by running 'sudo reboot now'."
    exit
  else
    echo "Unknown input, please restart your Raspberry Pi later to apply changes by running 'sudo reboot now'."
    sleep 1
  fi
}

# -------------------------------
# Main installation steps
# -------------------------------

echo_header "Removing any existing installation..."
sudo rm -rf "$APP_DIR"

echo_header "Cloning repository from GitHub..."
sudo git clone "$GITHUB_REPO" "$APP_DIR"

echo_header "Ensuring images folder exists..."
mkdir -p "$IMAGE_DIR"

echo_header "Updating system packages..."
sudo apt-get update -y
sudo apt-get install -y python3-pip python3-pil python3-pil.imagetk libjpeg-dev git

echo_header "Installing Python dependencies globally..."
if [ -f "$REQUIREMENTS_FILE" ]; then
    sudo pip3 install -r "$REQUIREMENTS_FILE"
else
    echo_error "requirements.txt not found! Please check repository."
fi

enable_interfaces   # Enable SPI/I2C interfaces

echo_header "Making slideshow script executable..."
sudo chmod +x "$PYTHON_SCRIPT"

echo_header "Installing systemd service..."
sudo cp "$SERVICE_FILE" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable eink-slideshow
sudo systemctl start eink-slideshow

echo_success "Installation complete!"
echo "Put your images into $IMAGE_DIR if not already present."
echo "The slideshow will start automatically on boot."
echo "A reboot is recommended if SPI/I2C interfaces were updated."

ask_for_reboot
