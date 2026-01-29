#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Starting reinstall + update sequence..."

bash "$SCRIPT_DIR/uninstall.sh"
echo "✔ Uninstall OK"

bash "$SCRIPT_DIR/update.sh"
echo "✔ Update OK"

bash "$SCRIPT_DIR/install.sh"
echo "✔ Install OK"

echo "🎉 Full reinstall/update completed successfully."
