#!/bin/bash
# =============================================================================
# Automatic Installer for E-Ink Slideshow (old style + useful functions)
# =============================================================================

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)

set -e  # Exit on error

APP_DIR="/home/rma/InkyRic"
GITHUB_REPO="https://github.com/morelos-ricardo/InkyRic"
IMAGE_DIR="$APP_DIR/images"
SERVICE_FILE="$APP_DIR/eink-slideshow.service"
PYTHON_SCRIPT="$APP_DIR/slideshow.py"
REQUIREMENTS_FILE="$APP_DIR/requirements.txt"

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
  sudo sed -i 's/^#dtparam=i2c_arm=.*/dtparam=i2*_
