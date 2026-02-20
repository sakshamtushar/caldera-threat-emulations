#!/bin/bash
# Raccoon Stealer Caldera Deployment Script
# Deploys the emulation plan to a Caldera instance

set -e

echo "============================================"
echo "  Raccoon Stealer Emulation Deployment"
echo "============================================"

# Check for CALDERA_HOME environment variable
if [ -z "$CALDERA_HOME" ]; then
    echo "[!] CALDERA_HOME not set. Please set it to your Caldera installation directory."
    echo "    Example: export CALDERA_HOME=/opt/caldera"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABILITIES_SRC="$SCRIPT_DIR/abilities"
ADVERSARIES_SRC="$SCRIPT_DIR/adversaries"

ABILITIES_DST="$CALDERA_HOME/data/abilities/raccoon-stealer"
ADVERSARIES_DST="$CALDERA_HOME/data/adversaries"

echo "[*] Source directory: $SCRIPT_DIR"
echo "[*] Caldera home: $CALDERA_HOME"

# Create abilities directory for Raccoon Stealer
echo "[*] Creating abilities directory..."
mkdir -p "$ABILITIES_DST"

# Copy ability files
echo "[*] Copying ability files..."
for file in "$ABILITIES_SRC"/*.yml; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        cp "$file" "$ABILITIES_DST/$filename"
        echo "    [+] Copied: $filename"
    fi
done

# Copy adversary profile
echo "[*] Copying adversary profile..."
cp "$ADVERSARIES_SRC/raccoon_stealer.yml" "$ADVERSARIES_DST/"
echo "    [+] Copied: raccoon_stealer.yml"

echo ""
echo "[+] Deployment complete!"
echo ""
echo "Next steps:"
echo "  1. Restart the Caldera server"
echo "  2. Deploy a Sandcat agent to your Windows target VM"
echo "  3. Navigate to Operations in Caldera"
echo "  4. Create a new operation with 'Raccoon Stealer v2' adversary"
echo "  5. Run the operation"
echo ""
echo "============================================"
