#!/bin/bash
set -e

APP_DIR="/opt/eink"
REPO_URL="https://github.com/morelos-ricardo/InkyRic.git"

echo "🔄 Starting update process..."

if [ ! -d "$APP_DIR/.git" ]; then
    echo "No git repo found. Cloning fresh copy..."
    sudo git clone "$REPO_URL" "$APP_DIR"
    sudo chown -R $USER:$USER "$APP_DIR"
else
    cd "$APP_DIR"
    echo "Fetching latest changes..."
    git fetch origin
    git reset --hard origin/main
fi

echo "🔍 Verifying repo integrity..."

cd "$APP_DIR"
if git status --porcelain | grep .; then
    echo "❌ Local repo differs from GitHub!"
    git status
    exit 1
else
    echo "✅ Repo matches GitHub exactly."
fi
