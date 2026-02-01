#!/bin/bash
# validate-kubernetes.sh - Kubernetes cluster validation script
# Part of Three Horizons Accelerator validation scripts
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

log_info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_ok()    { echo -e "${GREEN}✅ $1${NC}"; }
log_warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; ((WARNINGS++)); }
log_error() { echo -e "${RED}❌ $1${NC}"; ((ERRORS++)); }

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Validate Kubernetes cluster for Three Horizons Accelerator.

OPTIONS:
  -n, --namespace NAME    Namespace to validate (default: all)
  -a, --all               Run all validation checks
  --health                Check cluster health only
  --workloads             Check workloads only
  --rbac                  Check RBAC only
  -h, --help              Show this help

EXAMPLES:
  $(basename "$0") --all
  $(basename "$0") -n argocd --workloads
  $(basename "$0") --health

EOF
}

validate_cluster_health() {
  log_info "Validating cluster health..."
  
  # Check API server
  if ! kubectl cluster-info &>/dev/null; then
    log_error "Cannot connect to Kubernetes API server"
    return 1
  fi
  log_ok "API server is reachable"
  
  # Check nodes
  local not_ready
  not_ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -cv "Ready" || echo "0")
  if [[ "$not_ready" -gt 0 ]]; then
    log_error "$not_ready nodes are not ready"
    kubectl get nodes -o wide
    return 1
  fi
  
  local node_count
  node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  log_ok "All $node_count nodes are ready"
  
  # Check system pods
  local failed_pods
  failed_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -cvE "Running|Completed" || echo "0")
  if [[ "$failed_pods" -gt 0 ]]; then
    log_warn "$failed_pods system pods are not running"
    kubectl get pods -n kube-system | grep -vE "Running|Completed"
  else
    log_ok "All system pods are running"
  fi
  
  # Check cluster version
  local version
  version=$(kubectl version --short 2>/dev/null | grep Server || kubectl version 2>/dev/null | grep "Server Version" | head -1)
  log_info "Cluster version: $version"
}

validate_workloads() {
  local namespace=${1:-}
  
  if [[ -n "$namespace" ]]; then
    log_info "Validating workloads in namespace: $namespace"
    _validate_namespace_workloads "$namespace"
  else
    log_info "Validating workloads in all namespaces"
    
    # Get all non-system namespaces
    local namespaces
    namespaces=$(kubectl get ns --no-headers -o custom-columns=':metadata.name' 2>/dev/null | grep -vE '^kube-')
    
    for ns in $namespaces; do
      _validate_namespace_workloads "$ns"
    done
  fi
}

_validate_namespace_workloads() {
  local ns=$1
  
  # Check deployments
  local total_deps
  total_deps=$(kubectl get deployments -n "$ns" --no-headers 2>/dev/null | wc -l)
  
  if [[ "$total_deps" -gt 0 ]]; then
    local failed_deps
    failed_deps=$(kubectl get deployments -n "$ns" --no-headers 2>/dev/null | awk '$2 != $4' | wc -l)
    if [[ "$failed_deps" -gt 0 ]]; then
      log_warn "[$ns] $failed_deps/$total_deps deployments not fully available"
    else
      log_ok "[$ns] All $total_deps deployments are available"
    fi
  fi
  
  # Check pods
  local total_pods
  total_pods=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l)
  
  if [[ "$total_pods" -gt 0 ]]; then
    local failed_pods
    failed_pods=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | grep -cvE "Running|Completed|Succeeded" || echo "0")
    if [[ "$failed_pods" -gt 0 ]]; then
      log_warn "[$ns] $failed_pods/$total_pods pods are not running"
      kubectl get pods -n "$ns" | grep -vE "Running|Completed|Succeeded" | head -10
    else
      log_ok "[$ns] All $total_pods pods are running/completed"
    fi
    
    # Check for restart loops
    local restarts
    restarts=$(kubectl get pods -n "$ns" -o jsonpath='{range .items[*]}{.metadata.name}{" "}{range .status.containerStatuses[*]}{.restartCount}{" "}{end}{"\n"}{end}' 2>/dev/null | awk '{sum=0; for(i=2;i<=NF;i++) sum+=$i; if(sum>5) print $1": "sum" restarts"}')
    if [[ -n "$restarts" ]]; then
      log_warn "[$ns] Pods with high restart counts:"
      echo "$restarts" | head -5
    fi
  fi
}

validate_network_policies() {
  local namespace=${1:-}
  log_info "Validating network policies..."
  
  local namespaces
  if [[ -n "$namespace" ]]; then
    namespaces="$namespace"
  else
    namespaces=$(kubectl get ns --no-headers -o custom-columns=':metadata.name' 2>/dev/null | grep -vE '^kube-')
  fi
  
  for ns in $namespaces; do
    local np_count
    np_count=$(kubectl get networkpolicies -n "$ns" --no-headers 2>/dev/null | wc -l)
    if [[ "$np_count" -eq 0 ]]; then
      log_warn "[$ns] No network policies defined"
    else
      log_ok "[$ns] $np_count network policies defined"
    fi
  done
}

validate_rbac() {
  log_info "Validating RBAC configuration..."
  
  # Check for cluster-admin bindings
  local cluster_admins
  cluster_admins=$(kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '.items[] | select(.roleRef.name == "cluster-admin") | .metadata.name')
  
  log_info "Cluster-admin bindings:"
  echo "$cluster_admins" | while read -r binding; do
    if [[ -n "$binding" ]]; then
      echo "   - $binding"
    fi
  done
  
  # Check service accounts with cluster-admin
  local sa_admins
  sa_admins=$(kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '.items[] | select(.roleRef.name == "cluster-admin") | .subjects[]? | select(.kind == "ServiceAccount") | "\(.namespace)/\(.name)"')
  
  if [[ -n "$sa_admins" ]]; then
    log_warn "Service accounts with cluster-admin:"
    echo "$sa_admins" | while read -r sa; do
      echo "   - $sa"
    done
  fi
}

validate_resource_quotas() {
  local namespace=${1:-}
  log_info "Validating resource quotas..."
  
  local namespaces
  if [[ -n "$namespace" ]]; then
    namespaces="$namespace"
  else
    namespaces=$(kubectl get ns --no-headers -o custom-columns=':metadata.name' 2>/dev/null | grep -vE '^kube-')
  fi
  
  for ns in $namespaces; do
    local quotas
    quotas=$(kubectl get resourcequotas -n "$ns" --no-headers 2>/dev/null | wc -l)
    local limits
    limits=$(kubectl get limitranges -n "$ns" --no-headers 2>/dev/null | wc -l)
    
    if [[ "$quotas" -eq 0 && "$limits" -eq 0 ]]; then
      log_warn "[$ns] No resource quotas or limit ranges"
    else
      log_ok "[$ns] $quotas quotas, $limits limit ranges"
    fi
  done
}

validate_pvc() {
  log_info "Validating Persistent Volume Claims..."
  
  local pending_pvcs
  pending_pvcs=$(kubectl get pvc -A --no-headers 2>/dev/null | grep -c "Pending" || echo "0")
  
  if [[ "$pending_pvcs" -gt 0 ]]; then
    log_warn "$pending_pvcs PVCs are pending"
    kubectl get pvc -A | grep Pending
  else
    local total_pvcs
    total_pvcs=$(kubectl get pvc -A --no-headers 2>/dev/null | wc -l)
    log_ok "All $total_pvcs PVCs are bound"
  fi
}

# Main
main() {
  local namespace=""
  local check_health=false
  local check_workloads=false
  local check_rbac=false
  local check_all=false
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      -n|--namespace) namespace="$2"; shift 2 ;;
      -a|--all) check_all=true; shift ;;
      --health) check_health=true; shift ;;
      --workloads) check_workloads=true; shift ;;
      --rbac) check_rbac=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
  done
  
  # Default to all if nothing specified
  if ! $check_health && ! $check_workloads && ! $check_rbac; then
    check_all=true
  fi
  
  echo "═══════════════════════════════════════════════════════════"
  echo "       Kubernetes Cluster Validation                       "
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  
  if $check_all || $check_health; then
    validate_cluster_health
    echo ""
  fi
  
  if $check_all || $check_workloads; then
    validate_workloads "$namespace"
    echo ""
  fi
  
  if $check_all; then
    validate_network_policies "$namespace"
    echo ""
    validate_resource_quotas "$namespace"
    echo ""
    validate_pvc
    echo ""
  fi
  
  if $check_all || $check_rbac; then
    validate_rbac
    echo ""
  fi
  
  echo "═══════════════════════════════════════════════════════════"
  echo "Summary: $ERRORS errors, $WARNINGS warnings"
  echo "═══════════════════════════════════════════════════════════"
  
  exit $ERRORS
}

main "$@"
