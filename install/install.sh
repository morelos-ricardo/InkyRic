#!/bin/bash
# =============================================================================
# Automatic Installer for E-Ink Slideshow (old style + useful functions)
# =============================================================================

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)

SOURCE=${BASH_SOURCE[0]}
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
SCRIPT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

set -e  # Exit on error
GITHUB_REPO="https://github.com/morelos-ricardo/InkyRic"
SCRIPT_DIR=GITHUB_REPO
SRC_PATH="$SCRIPT_DIR/../src"

APPNAME="inkypi"
INSTALL_PATH="/usr/local/$APPNAME"

IMAGE_DIR="$INSTALL_PATH/images"
SERVICE_NAME="inkypi.service"
SERVICE_FILE="$INSTALL_PATH/$SERVICE_NAME"
PYTHON_SCRIPT="$INSTALL_PATH/slideshow.py"
REQUIREMENTS_FILE="$INSTALL_PATH/requirements.txt"
VENV_PATH="$INSTALL_PATH/venv_$APPNAME"
BINPATH="/usr/local/bin"

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

if [ -f "$REQUIREMENTS_FILE" ]; then
  echo "Creating Python virtual environment at $VENV_PATH ..."
  python3 -m venv "$VENV_PATH"
  $VENV_PATH/bin/python -m pip install --upgrade pip setuptools wheel > /dev/null
  show_loader "\tInstalling Python packages in virtual environment..."
  $VENV_PATH/bin/python -m pip install -r $REQUIREMENTS_FILE > /dev/null &
  show_loader "\tFinished installing python dependencies."
else
    echo_error "requirements.txt not found! Please check repository."
fi

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

uninstall_if_necessary() {

# Stop service if running
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "🔴 Starting uninstall process..."
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
if [ -d "$INSTALL_PATH" ]; then
    echo "Removing application directory..."
    sudo rm -rf "$INSTALL_PATH"
else
    echo "Application directory already removed."
fi

echo "🔍 Verifying uninstall..."

ERRORS=0

[ -d "$INSTALL_PATH" ] && echo "❌ $INSTALL_PATH still exists" && ERRORS=1
[ -f "$SERVICE_FILE" ] && echo "❌ Service file still exists" && ERRORS=1
systemctl list-unit-files | grep -q "$SERVICE_NAME" && echo "❌ Service still registered" && ERRORS=1

if [ "$ERRORS" -eq 0 ]; then
    echo "✅ Uninstall completed successfully."
    exit 0
else
    echo "❌ Uninstall incomplete."
    exit 1
fi
}


intstall_general_libraries(){
sudo apt-get update
sudo apt-get install tree



}

install_executable() {
  echo "Adding executable to ${BINPATH}/$APPNAME"
  cp "$SERVICE_FILE" $BINPATH/
  sudo chmod +x $BINPATH/$SERVICE_NAME
  
#sudo cp "$SERVICE_FILE" /etc/systemd/system/
#sudo systemctl daemon-reload
#sudo systemctl enable eink-slideshow
#sudo systemctl start eink-slideshow
  
}

# -------------------------------
# Main installation steps
# -------------------------------

echo_header "Removing any existing installation..."
uninstall_if_necessary

echo_header "Cloning repository from GitHub..."
sudo git clone "$GITHUB_REPO" "$INSTALL_PATH"

echo_header "Ensuring images folder exists..."
mkdir -p "$IMAGE_DIR"

intstall_general_libraries
enable_interfaces   # Enable SPI/I2C interfaces
echo_header "Installing Python dependencies globally..."
create_venv

echo_header "Making slideshow script executable..."
sudo chmod +x "$PYTHON_SCRIPT"

echo_header "Installing systemd service..."
install_executable


echo_success "Installation complete!"
echo "Put your images into $IMAGE_DIR if not already present."
echo "The slideshow will start automatically on boot."
echo "A reboot is recommended if SPI/I2C interfaces were updated."

ask_for_reboot
