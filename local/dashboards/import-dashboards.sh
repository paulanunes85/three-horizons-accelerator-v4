#!/bin/bash
# =============================================================================
# import-dashboards.sh — Import Grafana dashboards as ConfigMaps
# =============================================================================
# Imports dashboards from grafana/dashboards/ into Kubernetes as ConfigMaps
# with the grafana_dashboard label for sidecar auto-discovery.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DASHBOARD_DIR="$PROJECT_DIR/grafana/dashboards"
NAMESPACE="observability"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

if [[ ! -d "$DASHBOARD_DIR" ]]; then
  echo -e "${YELLOW}No dashboards directory found at $DASHBOARD_DIR — skipping${NC}"
  exit 0
fi

echo "Importing Grafana dashboards from $DASHBOARD_DIR..."

for dashboard_file in "$DASHBOARD_DIR"/*.json; do
  [[ -f "$dashboard_file" ]] || continue

  filename=$(basename "$dashboard_file")
  cm_name="grafana-dashboard-$(echo "${filename%.json}" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')"

  # Truncate name to max 63 chars for K8s
  cm_name="${cm_name:0:63}"

  kubectl create configmap "$cm_name" \
    --from-file="$filename=$dashboard_file" \
    --namespace "$NAMESPACE" \
    --dry-run=client -o yaml | \
    kubectl label --local -f - grafana_dashboard="1" -o yaml --dry-run=client | \
    kubectl apply -f -

  echo -e "  ${GREEN}✓${NC} $filename → $cm_name"
done

echo -e "${GREEN}Dashboard import complete${NC}"
