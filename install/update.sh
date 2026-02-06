#!/bin/bash
# ^ Tells the system to run this script using the Bash shell

# ------------------------------------------------------------
# E-Ink Frame Updater Script
# ------------------------------------------------------------
# This script ensures that the local E-Ink application directory
# (/opt/eink) exactly matches the latest version on GitHub.
#
# What it does:
# - If no repository exists, it clones the project into /opt/eink
# - If the repository already exists, it force-updates it to
#   match origin/main (discarding all local changes)
# - Verifies that the local repo is clean and fully synced
# - Exits with an error if the repo differs from GitHub
#
# ⚠️ WARNING:
# This script uses `git reset --hard`, which permanently deletes
# any local changes to tracked files.
#
# How to run:
# 1. Make the script executable:
#    chmod +x update.sh
#
# 2. Run it from the terminal:
#    ./update.sh
#
# 3. If permission is denied (due to /opt):
#    sudo ./update.sh
# ------------------------------------------------------------


set -e
# ^ Exit the script immediately if ANY command returns a non-zero (error) status
#   This prevents partial updates or inconsistent states

APP_DIR="/opt/eink"
# ^ Absolute path where the application/repository should live on the system

REPO_URL="https://github.com/morelos-ricardo/InkyRic.git"
# ^ URL of the GitHub repository to clone or update from

echo "🔄 Starting update process..."
# ^ Print a user-friendly message to indicate the script has started


# Check if the directory /opt/eink/.git does NOT exist
# This tells us whether a git repository is already present
if [ ! -d "$APP_DIR/.git" ]; then

    echo "No git repo found. Cloning fresh copy..."
    # ^ Inform the user that this is a first-time setup

    sudo git clone "$REPO_URL" "$APP_DIR"
    # ^ Clone the repository from GitHub into /opt/eink
    # ^ sudo is required because /opt typically needs elevated permissions

    sudo chown -R $USER:$USER "$APP_DIR"
    # ^ Change ownership of all files in /opt/eink to the current user
    # ^ This allows running git commands later without sudo

else
    # ^ This block runs if a git repository already exists

    cd "$APP_DIR"
    # ^ Change directory to the application directory

    echo "Fetching latest changes..."
    # ^ Inform the user that an update is happening

    git fetch origin
    # ^ Download the latest commits and references from the remote "origin"
    # ^ Does NOT modify any local files yet

    git reset --hard origin/main
    # ^ Force the local repository to exactly match origin/main
    # ^ Discards ALL local changes (tracked files only)
    # ^ Ensures a clean, deterministic deployment state
fi


echo "🔍 Verifying repo integrity..."
# ^ Let the user know we are about to check repo consistency


cd "$APP_DIR"
# ^ Ensure we are inside the repository directory (safety)


# git status --porcelain:
#   - Outputs a machine-readable summary of file changes
# grep .:
#   - Matches any output (i.e., any modified, added, or deleted file)
if git status --porcelain | grep .; then

    echo "❌ Local repo differs from GitHub!"
    # ^ Warn that the repository is not clean

    git status
    # ^ Show a human-readable status so the user can see what’s different

    exit 1
    # ^ Exit with an error code to signal failure to any calling process

else
    echo "✅ Repo matches GitHub exactly."
    # ^ Confirm that the working tree is clean and fully synced
fi
