#!/bin/bash
# validate-azure.sh - Azure infrastructure validation script
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

Validate Azure infrastructure for Three Horizons Accelerator.

OPTIONS:
  -g, --resource-group NAME    Resource group name (required)
  -c, --cluster NAME           AKS cluster name
  -r, --registry NAME          ACR name
  -k, --keyvault NAME          Key Vault name
  -v, --vnet NAME              VNet name
  -h, --help                   Show this help

EXAMPLES:
  $(basename "$0") -g rg-myproject-prod
  $(basename "$0") -g rg-myproject-prod -c aks-myproject-prod -r crmyprojectprod

EOF
}

validate_resource_group() {
  local rg_name=$1
  log_info "Validating resource group: $rg_name"
  
  if ! az group show --name "$rg_name" --output none 2>/dev/null; then
    log_error "Resource group '$rg_name' does not exist"
    return 1
  fi
  
  local state
  state=$(az group show --name "$rg_name" --query "properties.provisioningState" -o tsv)
  if [[ "$state" != "Succeeded" ]]; then
    log_error "Resource group provisioning state: $state"
    return 1
  fi
  
  local tags
  tags=$(az group show --name "$rg_name" --query "tags" -o json)
  if [[ "$tags" == "null" || "$tags" == "{}" ]]; then
    log_warn "Resource group has no tags"
  fi
  
  log_ok "Resource group '$rg_name' is valid"
}

validate_aks_cluster() {
  local rg_name=$1
  local cluster_name=$2
  log_info "Validating AKS cluster: $cluster_name"
  
  if ! az aks show --resource-group "$rg_name" --name "$cluster_name" --output none 2>/dev/null; then
    log_error "AKS cluster '$cluster_name' does not exist"
    return 1
  fi
  
  local cluster_info
  cluster_info=$(az aks show --resource-group "$rg_name" --name "$cluster_name" -o json)
  
  # Check provisioning state
  local state
  state=$(echo "$cluster_info" | jq -r '.provisioningState')
  if [[ "$state" != "Succeeded" ]]; then
    log_error "Cluster provisioning state: $state"
    return 1
  fi
  
  # Check power state
  local power_state
  power_state=$(echo "$cluster_info" | jq -r '.powerState.code')
  if [[ "$power_state" != "Running" ]]; then
    log_error "Cluster power state: $power_state"
    return 1
  fi
  
  # Check OIDC issuer
  local oidc_issuer
  oidc_issuer=$(echo "$cluster_info" | jq -r '.oidcIssuerProfile.issuerUrl // empty')
  if [[ -z "$oidc_issuer" ]]; then
    log_warn "OIDC issuer not enabled (workload identity won't work)"
  else
    log_ok "OIDC issuer enabled"
  fi
  
  # Check workload identity
  local workload_identity
  workload_identity=$(echo "$cluster_info" | jq -r '.securityProfile.workloadIdentity.enabled // false')
  if [[ "$workload_identity" != "true" ]]; then
    log_warn "Workload identity not enabled"
  else
    log_ok "Workload identity enabled"
  fi
  
  # Check Defender
  local defender
  defender=$(echo "$cluster_info" | jq -r '.securityProfile.defender.logAnalyticsWorkspaceResourceId // empty')
  if [[ -z "$defender" ]]; then
    log_warn "Microsoft Defender not enabled"
  else
    log_ok "Microsoft Defender enabled"
  fi
  
  log_ok "AKS cluster '$cluster_name' is valid"
}

validate_acr() {
  local acr_name=$1
  log_info "Validating ACR: $acr_name"
  
  if ! az acr show --name "$acr_name" --output none 2>/dev/null; then
    log_error "ACR '$acr_name' does not exist"
    return 1
  fi
  
  local acr_info
  acr_info=$(az acr show --name "$acr_name" -o json)
  
  local state
  state=$(echo "$acr_info" | jq -r '.provisioningState')
  if [[ "$state" != "Succeeded" ]]; then
    log_error "ACR provisioning state: $state"
    return 1
  fi
  
  local admin_enabled
  admin_enabled=$(echo "$acr_info" | jq -r '.adminUserEnabled')
  if [[ "$admin_enabled" == "true" ]]; then
    log_warn "Admin user is enabled (not recommended for production)"
  else
    log_ok "Admin user disabled"
  fi
  
  log_ok "ACR '$acr_name' is valid"
}

validate_keyvault() {
  local kv_name=$1
  log_info "Validating Key Vault: $kv_name"
  
  if ! az keyvault show --name "$kv_name" --output none 2>/dev/null; then
    log_error "Key Vault '$kv_name' does not exist"
    return 1
  fi
  
  local kv_info
  kv_info=$(az keyvault show --name "$kv_name" -o json)
  
  local rbac
  rbac=$(echo "$kv_info" | jq -r '.properties.enableRbacAuthorization')
  if [[ "$rbac" != "true" ]]; then
    log_warn "RBAC authorization not enabled"
  else
    log_ok "RBAC authorization enabled"
  fi
  
  local purge_protection
  purge_protection=$(echo "$kv_info" | jq -r '.properties.enablePurgeProtection // false')
  if [[ "$purge_protection" != "true" ]]; then
    log_warn "Purge protection not enabled"
  else
    log_ok "Purge protection enabled"
  fi
  
  log_ok "Key Vault '$kv_name' is valid"
}

validate_vnet() {
  local rg_name=$1
  local vnet_name=$2
  log_info "Validating VNet: $vnet_name"
  
  if ! az network vnet show --resource-group "$rg_name" --name "$vnet_name" --output none 2>/dev/null; then
    log_error "VNet '$vnet_name' does not exist"
    return 1
  fi
  
  local vnet_info
  vnet_info=$(az network vnet show --resource-group "$rg_name" --name "$vnet_name" -o json)
  
  local state
  state=$(echo "$vnet_info" | jq -r '.provisioningState')
  if [[ "$state" != "Succeeded" ]]; then
    log_error "VNet provisioning state: $state"
    return 1
  fi
  
  log_info "Subnets:"
  echo "$vnet_info" | jq -r '.subnets[] | "   - \(.name): \(.addressPrefix)"'
  
  log_ok "VNet '$vnet_name' is valid"
}

# Main
main() {
  local resource_group=""
  local cluster_name=""
  local acr_name=""
  local keyvault_name=""
  local vnet_name=""
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      -g|--resource-group) resource_group="$2"; shift 2 ;;
      -c|--cluster) cluster_name="$2"; shift 2 ;;
      -r|--registry) acr_name="$2"; shift 2 ;;
      -k|--keyvault) keyvault_name="$2"; shift 2 ;;
      -v|--vnet) vnet_name="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
  done
  
  if [[ -z "$resource_group" ]]; then
    echo "Error: Resource group is required"
    usage
    exit 1
  fi
  
  echo "═══════════════════════════════════════════════════════════"
  echo "       Azure Infrastructure Validation                     "
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  
  validate_resource_group "$resource_group"
  
  [[ -n "$cluster_name" ]] && validate_aks_cluster "$resource_group" "$cluster_name"
  [[ -n "$acr_name" ]] && validate_acr "$acr_name"
  [[ -n "$keyvault_name" ]] && validate_keyvault "$keyvault_name"
  [[ -n "$vnet_name" ]] && validate_vnet "$resource_group" "$vnet_name"
  
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "Summary: $ERRORS errors, $WARNINGS warnings"
  echo "═══════════════════════════════════════════════════════════"
  
  exit $ERRORS
}

main "$@"
