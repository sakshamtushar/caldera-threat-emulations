#!/bin/bash
# =============================================================
# Anomaly Baseline v1 — Caldera Deployment Script
# =============================================================
# Supports both standard (filesystem) and Docker deployments.
#
# Usage:
#   1. cp .env.example .env
#   2. Edit .env with your values
#   3. chmod +x deploy_to_caldera.sh
#   4. ./deploy_to_caldera.sh
#
# Alternatively, export variables manually before running:
#   export CALDERA_HOME=/opt/caldera
#   ./deploy_to_caldera.sh
#
# NOTE: for one-off additions during active development, the REST API flow
# documented in the repo's CLAUDE.md is faster and doesn't require a server
# restart. This filesystem script exists so the plan stays importable the
# same way every other plan in this repo is.
# =============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------------------------------------------------------------
# Load .env if it exists (variables already exported take precedence)
# -------------------------------------------------------------
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    echo "[*] Loading configuration from .env"
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        varname="${line%%=*}"
        if [ -z "${!varname+x}" ]; then
            export "$line"
        fi
    done < "$ENV_FILE"
else
    echo "[!] No .env file found — using environment variables only"
    echo "    Tip: cp .env.example .env and fill in your values"
    echo ""
fi

# -------------------------------------------------------------
# Apply defaults for optional variables
# -------------------------------------------------------------
DOCKER_MODE="${DOCKER_MODE:-false}"
DOCKER_CONTAINER="${DOCKER_CONTAINER:-caldera-caldera-1}"
DOCKER_CALDERA_WORKDIR="${DOCKER_CALDERA_WORKDIR:-/usr/src/app}"
ABILITIES_DIR_NAME="${ABILITIES_DIR_NAME:-anomaly-baseline-v1}"
CALDERA_ABILITIES_PATH="${CALDERA_ABILITIES_PATH:-data/abilities}"
CALDERA_ADVERSARIES_PATH="${CALDERA_ADVERSARIES_PATH:-data/adversaries}"

ABILITIES_SRC="$SCRIPT_DIR/abilities"
ADVERSARIES_SRC="$SCRIPT_DIR/adversaries"

echo "============================================"
echo "  Anomaly Baseline v1 — Caldera Deployment"
echo "============================================"
echo ""
echo "[*] Configuration:"
echo "    DOCKER_MODE          = $DOCKER_MODE"
if [ "$DOCKER_MODE" = "true" ]; then
    echo "    DOCKER_CONTAINER     = $DOCKER_CONTAINER"
    echo "    DOCKER_CALDERA_WORKDIR = $DOCKER_CALDERA_WORKDIR"
else
    echo "    CALDERA_HOME         = ${CALDERA_HOME:-<not set>}"
fi
echo "    ABILITIES_DIR_NAME   = $ABILITIES_DIR_NAME"
echo "    CALDERA_ABILITIES_PATH  = $CALDERA_ABILITIES_PATH"
echo "    CALDERA_ADVERSARIES_PATH = $CALDERA_ADVERSARIES_PATH"
echo ""

if [ "$DOCKER_MODE" = "true" ]; then

    if [ -z "$DOCKER_CONTAINER" ]; then
        echo "[!] DOCKER_CONTAINER is not set."
        echo "    Set it in .env or export it: export DOCKER_CONTAINER=caldera-caldera-1"
        exit 1
    fi

    if ! docker ps --format '{{.Names}}' | grep -q "^${DOCKER_CONTAINER}$"; then
        echo "[!] Container '$DOCKER_CONTAINER' is not running."
        echo "    Running containers:"
        docker ps --format '    - {{.Names}}'
        exit 1
    fi

    ABILITIES_DST="$DOCKER_CALDERA_WORKDIR/$CALDERA_ABILITIES_PATH/$ABILITIES_DIR_NAME"
    ADVERSARIES_DST="$DOCKER_CALDERA_WORKDIR/$CALDERA_ADVERSARIES_PATH"

    echo "[*] Deploying to Docker container: $DOCKER_CONTAINER"

    echo "[*] Creating abilities directory inside container..."
    docker exec "$DOCKER_CONTAINER" mkdir -p "$ABILITIES_DST"

    echo "[*] Copying ability files..."
    for file in "$ABILITIES_SRC"/*.yml; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        docker cp "$file" "$DOCKER_CONTAINER:$ABILITIES_DST/$filename"
        echo "    [+] Copied: $filename"
    done

    echo "[*] Copying adversary profile..."
    docker cp "$ADVERSARIES_SRC/anomaly_baseline.yml" "$DOCKER_CONTAINER:$ADVERSARIES_DST/"
    echo "    [+] Copied: anomaly_baseline.yml"

    echo "[*] Restarting container to load new content..."
    docker restart "$DOCKER_CONTAINER"
    echo "[+] Container restarted."

else

    if [ -z "$CALDERA_HOME" ]; then
        echo "[!] CALDERA_HOME is not set."
        echo "    Set it in .env:  CALDERA_HOME=/opt/caldera"
        echo "    Or export it:    export CALDERA_HOME=/opt/caldera"
        exit 1
    fi

    if [ ! -d "$CALDERA_HOME" ]; then
        echo "[!] CALDERA_HOME directory does not exist: $CALDERA_HOME"
        echo "    Check the path and try again."
        exit 1
    fi

    ABILITIES_DST="$CALDERA_HOME/$CALDERA_ABILITIES_PATH/$ABILITIES_DIR_NAME"
    ADVERSARIES_DST="$CALDERA_HOME/$CALDERA_ADVERSARIES_PATH"

    echo "[*] Deploying to: $CALDERA_HOME"

    echo "[*] Creating abilities directory..."
    mkdir -p "$ABILITIES_DST"

    echo "[*] Copying ability files..."
    for file in "$ABILITIES_SRC"/*.yml; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        cp "$file" "$ABILITIES_DST/$filename"
        echo "    [+] Copied: $filename"
    done

    echo "[*] Copying adversary profile..."
    cp "$ADVERSARIES_SRC/anomaly_baseline.yml" "$ADVERSARIES_DST/"
    echo "    [+] Copied: anomaly_baseline.yml"

    echo ""
    echo "[!] Remember to restart Caldera to load the new content:"
    echo "    cd $CALDERA_HOME && python3 server.py --insecure"

fi

echo ""
echo "[+] Deployment complete!"
echo ""
echo "Next steps:"
echo "  1. Open Caldera web UI"
echo "  2. Go to Agents → confirm the Windows 11 endpoint's Sandcat agent is checked in"
echo "  3. Go to Operations → Create new operation"
echo "  4. Select adversary: 'Anomaly Baseline v1'"
echo "  5. Click Start"
echo ""
echo "============================================"
