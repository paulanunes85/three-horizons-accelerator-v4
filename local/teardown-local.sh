#!/bin/bash
# =============================================================================
# teardown-local.sh — Destroy local demo environment
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config/local.env"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ${BOLD}THREE HORIZONS — Local Demo Teardown${NC}${BLUE}                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo -e "${YELLOW}Cluster $CLUSTER_NAME does not exist — nothing to do${NC}"
  exit 0
fi

echo -e "${YELLOW}This will delete the kind cluster: ${BOLD}$CLUSTER_NAME${NC}"
echo -e "${YELLOW}All data in the cluster will be lost.${NC}"
echo ""
read -rp "Continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
  echo "Cancelled."
  exit 0
fi

echo ""
echo -e "Deleting cluster ${BOLD}$CLUSTER_NAME${NC}..."
kind delete cluster --name "$CLUSTER_NAME"

# Clean checkpoint file
rm -f "$SCRIPT_DIR/.deploy-checkpoint"
rm -f "$SCRIPT_DIR/.deploy-local.log"

echo ""
echo -e "${GREEN}✓ Cluster deleted successfully${NC}"
echo -e "  Run ${BOLD}make -C local up${NC} to recreate"
echo ""
