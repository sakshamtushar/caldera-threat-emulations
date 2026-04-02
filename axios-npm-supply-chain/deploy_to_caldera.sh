#!/usr/bin/env bash
# =============================================================================
# deploy_to_caldera.sh — Axios npm Supply Chain Compromise Emulation Plan
# Deploys abilities and adversary profile to MITRE Caldera.
# Supports both direct filesystem deployment and Docker mode.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABILITIES_DIR_NAME="${ABILITIES_DIR_NAME:-axios-npm-supply-chain}"
ENV_FILE="$SCRIPT_DIR/.env"

# Load .env if it exists
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

# Defaults
CALDERA_HOME="${CALDERA_HOME:-}"
DOCKER_MODE="${DOCKER_MODE:-false}"
DOCKER_CONTAINER="${DOCKER_CONTAINER:-caldera-caldera-1}"
DOCKER_CALDERA_WORKDIR="${DOCKER_CALDERA_WORKDIR:-/usr/src/app}"
CALDERA_ABILITIES_PATH="${CALDERA_ABILITIES_PATH:-data/abilities}"
CALDERA_ADVERSARIES_PATH="${CALDERA_ADVERSARIES_PATH:-data/adversaries}"

# ─── Validation ───────────────────────────────────────────────────────────────
validate() {
  if [[ "$DOCKER_MODE" != "true" && -z "$CALDERA_HOME" ]]; then
    echo "[ERROR] CALDERA_HOME is not set. Set it in .env or as an environment variable."
    echo "        Or set DOCKER_MODE=true to use Docker mode."
    exit 1
  fi
  if [[ ! -d "$SCRIPT_DIR/abilities" ]]; then
    echo "[ERROR] abilities/ directory not found in $SCRIPT_DIR"
    exit 1
  fi
  if [[ ! -d "$SCRIPT_DIR/adversaries" ]]; then
    echo "[ERROR] adversaries/ directory not found in $SCRIPT_DIR"
    exit 1
  fi
}

# ─── Filesystem deployment ────────────────────────────────────────────────────
deploy_filesystem() {
  echo "[*] Deploying to Caldera at: $CALDERA_HOME"

  local abilities_dest="$CALDERA_HOME/$CALDERA_ABILITIES_PATH/$ABILITIES_DIR_NAME"
  local adversaries_dest="$CALDERA_HOME/$CALDERA_ADVERSARIES_PATH"

  echo "[*] Creating abilities directory: $abilities_dest"
  mkdir -p "$abilities_dest"

  echo "[*] Copying ability files..."
  cp "$SCRIPT_DIR/abilities"/*.yml "$abilities_dest/"

  echo "[*] Copying adversary profile..."
  cp "$SCRIPT_DIR/adversaries"/*.yml "$adversaries_dest/"

  echo "[+] Deployed successfully to $CALDERA_HOME"
  echo "[!] IMPORTANT: Restart the Caldera server to load new abilities."
  echo "    For systemd: sudo systemctl restart caldera"
  echo "    For manual:  cd $CALDERA_HOME && python3 caldera.py &"
}

# ─── Docker deployment ────────────────────────────────────────────────────────
deploy_docker() {
  echo "[*] Deploying to Docker container: $DOCKER_CONTAINER"
  echo "[*] Remote workdir: $DOCKER_CALDERA_WORKDIR"

  local remote_abilities="$DOCKER_CALDERA_WORKDIR/$CALDERA_ABILITIES_PATH/$ABILITIES_DIR_NAME"
  local remote_adversaries="$DOCKER_CALDERA_WORKDIR/$CALDERA_ADVERSARIES_PATH"

  echo "[*] Creating remote abilities directory..."
  docker exec "$DOCKER_CONTAINER" mkdir -p "$remote_abilities"

  echo "[*] Copying ability files..."
  docker cp "$SCRIPT_DIR/abilities/." "$DOCKER_CONTAINER:$remote_abilities/"

  echo "[*] Copying adversary profile..."
  docker cp "$SCRIPT_DIR/adversaries/." "$DOCKER_CONTAINER:$remote_adversaries/"

  echo "[+] Copied all files to container $DOCKER_CONTAINER"
  echo "[!] IMPORTANT: Restart the container to load new abilities."
  echo "    docker restart $DOCKER_CONTAINER"
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
  echo "========================================"
  echo " Axios npm Supply Chain — Caldera Deploy"
  echo "========================================"
  echo ""

  validate

  if [[ "$DOCKER_MODE" == "true" ]]; then
    deploy_docker
  else
    deploy_filesystem
  fi

  echo ""
  echo "[*] Next steps:"
  echo "    1. Restart Caldera (see above)"
  echo "    2. Open Caldera web UI"
  echo "    3. Go to Agents → deploy a Sandcat agent on a Windows target"
  echo "    4. Go to Operations → Create operation → select 'Axios npm Supply Chain Compromise'"
  echo "    5. Click Start"
  echo ""
}

main
