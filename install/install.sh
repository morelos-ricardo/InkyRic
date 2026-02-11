#!/bin/bash
# =============================================================================
# Automatic Installer for E-Ink Slideshow (old style + useful functions)
# =============================================================================

#Installer. Installs assuming repo is cloned.

# Formatting stuff
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


APPNAME="inkypi"
INSTALL_PATH="/usr/local/$APPNAME"
SRC_PATH="$SCRIPT_DIR/../src"
BINPATH="/usr/local/bin"
VENV_PATH="$INSTALL_PATH/venv_$APPNAME"

SERVICE_FILE="$APPNAME.service"
SERVICE_FILE_SOURCE="$SCRIPT_DIR/$SERVICE_FILE"
SERVICE_FILE_TARGET="/etc/systemd/system/$SERVICE_FILE"

PIP_REQUIREMENTS_FILE="$INSTALL_PATH/requirements.txt"
APT_REQUIREMENTS_FILE="$SCRIPT_DIR/debian-requirements.txt"



# -------------------------------
# Utility functions
# -------------------------------


check_permissions() {
  # Ensure the script is run with sudo
  if [ "$EUID" -ne 0 ]; then
    echo_error "ERROR: Installation requires root privileges. Please run it with sudo."
    exit 1
  fi
}

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

echo_success() {
  echo -e "$1 [\e[32m\xE2\x9C\x94\e[0m]"
}

echo_override() {
  echo -e "\r$1"
}

echo_header() {
  echo -e "${bold}$1${normal}"
}

echo_error() {
  echo -e "${red}$1${normal} [\e[31m\xE2\x9C\x98\e[0m]\n"
}

echo_blue() {
  echo -e "\e[38;2;65;105;225m$1\e[0m"
}

install_debian_dependencies() {
  if [ -f "$APT_REQUIREMENTS_FILE" ]; then
    sudo apt-get update > /dev/null &
    show_loader "Fetch available system dependencies updates. " 

    xargs -a "$APT_REQUIREMENTS_FILE" sudo apt-get install -y > /dev/null &
    show_loader "Installing system dependencies. "
  else
    echo "ERROR: System dependencies file $APT_REQUIREMENTS_FILE not found!"
    exit 1
  fi
}


# create Python virtual environment (not used in service yet)
create_venv(){

if [ -f "$PIP_REQUIREMENTS_FILE" ]; then
  echo "Creating Python virtual environment at $VENV_PATH ..."
  python3 -m venv "$VENV_PATH" #runs python 3 to run the venv module, which is Python’s standard tool to create virtual environments, in given path. created structure:
#$VENV_PATH/
#├── bin/
#│   ├── activate        ← FILE (shell script)
#│   ├── activate.csh
#│   ├── activate.fish
#│   ├── python
#│   ├── pip
#│   └── ...
#├── include/
#├── lib/
#└── pyvenv.cfg
  $VENV_PATH/bin/python -m pip install --upgrade pip setuptools wheel > /dev/null #Calls the Python inside the virtual environment,Runs the pip module (Python’s package installer), Upgrades the  three core Python tools
  #> /dev/null → Redirects all normal output to “nowhere” → so the terminal doesn’t show the normal installation messages.
  show_loader "\tInstalling Python packages in virtual environment..."
  $VENV_PATH/bin/python -m pip install -r $PIP_REQUIREMENTS_FILE > /dev/null &
  show_loader "\tFinished installing python dependencies."
else
    echo_error "requirements.txt not found! Please check repository."
fi
}

install_app_service() {
  echo "Installing $APPNAME systemd service."
  if [ -f "$SERVICE_FILE_SOURCE" ]; then
    cp "$SERVICE_FILE_SOURCE" "$SERVICE_FILE_TARGET"
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_FILE
  else
    echo_error "ERROR: Service file $SERVICE_FILE_SOURCE not found!"
    exit 1
  fi
}

install_executable() {
  echo "Adding executable to ${BINPATH}/$APPNAME"
  cp $SCRIPT_DIR/inkypi $BINPATH/
  sudo chmod +x $BINPATH/$APPNAME
}

stop_service() {
    echo "Checking if $SERVICE_FILE is running"
    if /usr/bin/systemctl is-active --quiet $SERVICE_FILE
    then
      /usr/bin/systemctl stop $SERVICE_FILE > /dev/null &
      show_loader "Stopping $APPNAME service"
    else  
      echo_success "\t$SERVICE_FILE not running"
    fi
}

start_service() {
  echo "Starting $APPNAME service."
  sudo systemctl start $SERVICE_FILE
  }


ask_for_reboot() {
  # Get hostname and IP address

  echo_header "$(echo_success "${APPNAME^^} Installation Complete!")"
  echo_header "[•] A reboot of your Raspberry Pi is required for the changes to take effect"

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



intstall_general_libraries(){
sudo apt-get update
sudo apt-get install tree
}


# -------------------------------
# Main installation steps
# -------------------------------

check_permissions
stop_service

intstall_general_libraries

enable_interfaces   # Enable SPI/I2C interfaces
install_debian_dependencies
echo_header "Installing Python dependencies globally..."

create_venv
install_executable
#install_config ??needed?
install_app_service


echo_success "Installation complete!"
echo "Put your images into $IMAGE_DIR if not already present."
echo "The slideshow will start automatically on boot."

ask_for_reboot
