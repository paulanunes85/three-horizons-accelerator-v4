#!/bin/bash
# validate-terraform.sh - Terraform state and configuration validation script
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

Validate Terraform configuration and state for Three Horizons Accelerator.

OPTIONS:
  -d, --dir PATH         Terraform directory (default: current)
  --init                 Run terraform init if needed
  --check-drift          Check for infrastructure drift
  --check-format         Check file formatting
  --check-security       Run tfsec security scan
  -h, --help             Show this help

EXAMPLES:
  $(basename "$0")
  $(basename "$0") -d ./terraform --check-drift
  $(basename "$0") --check-format --check-security

EOF
}

validate_terraform_installed() {
  log_info "Checking Terraform installation..."
  
  if ! command -v terraform &>/dev/null; then
    log_error "Terraform is not installed"
    return 1
  fi
  
  local version
  version=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' || terraform version | head -1)
  log_ok "Terraform installed: $version"
}

validate_terraform_init() {
  log_info "Checking Terraform initialization..."
  
  if [[ ! -d ".terraform" ]]; then
    log_error "Terraform not initialized. Run: terraform init"
    return 1
  fi
  
  log_ok "Terraform initialized"
  
  # Check lock file
  if [[ ! -f ".terraform.lock.hcl" ]]; then
    log_warn "Provider lock file missing"
  else
    log_ok "Provider lock file exists"
  fi
}

validate_terraform_config() {
  log_info "Validating Terraform configuration..."
  
  local validate_output
  if ! validate_output=$(terraform validate -json 2>&1); then
    log_error "Terraform validation failed"
    echo "$validate_output" | jq -r '.diagnostics[]? | "   - \(.severity): \(.summary)"' 2>/dev/null || echo "$validate_output"
    return 1
  fi
  
  local valid
  valid=$(echo "$validate_output" | jq -r '.valid')
  if [[ "$valid" != "true" ]]; then
    log_error "Terraform configuration invalid"
    echo "$validate_output" | jq -r '.diagnostics[]? | "   - \(.summary)"'
    return 1
  fi
  
  log_ok "Terraform configuration valid"
}

validate_terraform_format() {
  log_info "Checking Terraform formatting..."
  
  local unformatted
  unformatted=$(terraform fmt -check -recursive -diff 2>&1 || true)
  
  if [[ -n "$unformatted" ]]; then
    log_warn "Terraform files not formatted"
    echo "$unformatted" | head -20
    echo ""
    log_info "Run: terraform fmt -recursive"
  else
    log_ok "All Terraform files formatted"
  fi
}

validate_terraform_state() {
  log_info "Checking Terraform state..."
  
  if ! terraform state list &>/dev/null 2>&1; then
    log_warn "Cannot access Terraform state (backend may be unavailable)"
    return 0
  fi
  
  local resource_count
  resource_count=$(terraform state list 2>/dev/null | wc -l)
  log_ok "Terraform state accessible ($resource_count resources)"
  
  # Show resource summary
  log_info "Resource types:"
  terraform state list 2>/dev/null | sed 's/\[.*\]//g' | sed 's/\..*//g' | sort | uniq -c | sort -rn | head -10 | while read -r line; do
    echo "   $line"
  done
}

check_terraform_drift() {
  log_info "Detecting infrastructure drift..."
  
  local plan_output
  local exit_code
  
  set +e
  plan_output=$(terraform plan -detailed-exitcode -no-color 2>&1)
  exit_code=$?
  set -e
  
  case $exit_code in
    0)
      log_ok "No drift detected - infrastructure matches state"
      ;;
    1)
      log_error "Error running Terraform plan"
      echo "$plan_output" | tail -20
      return 1
      ;;
    2)
      log_warn "Drift detected - infrastructure has changed"
      echo ""
      echo "$plan_output" | grep -E "^(Plan:|  #|  ~|  \+|  -).*" | head -30
      echo ""
      return 1
      ;;
  esac
}

validate_terraform_providers() {
  log_info "Checking Terraform providers..."
  
  # List installed providers
  local providers
  providers=$(terraform version -json 2>/dev/null | jq -r '.provider_selections // {} | to_entries[] | "\(.key): \(.value)"' 2>/dev/null || echo "")
  
  if [[ -n "$providers" ]]; then
    log_info "Installed providers:"
    echo "$providers" | while read -r line; do
      echo "   - $line"
    done
  fi
  
  # Check for outdated providers
  if [[ -f ".terraform.lock.hcl" ]]; then
    local provider_count
    provider_count=$(grep -c "provider" .terraform.lock.hcl 2>/dev/null || echo "0")
    log_ok "$provider_count providers locked"
  fi
}

check_tfsec() {
  log_info "Running security scan (tfsec)..."
  
  if ! command -v tfsec &>/dev/null; then
    log_warn "tfsec not installed - skipping security scan"
    log_info "Install with: brew install tfsec"
    return 0
  fi
  
  local tfsec_output
  set +e
  tfsec_output=$(tfsec . --format json 2>/dev/null)
  local exit_code=$?
  set -e
  
  if [[ $exit_code -eq 0 ]]; then
    log_ok "No security issues found"
  else
    local high_count
    local medium_count
    local low_count
    
    high_count=$(echo "$tfsec_output" | jq '[.results[]? | select(.severity == "HIGH")] | length' 2>/dev/null || echo "0")
    medium_count=$(echo "$tfsec_output" | jq '[.results[]? | select(.severity == "MEDIUM")] | length' 2>/dev/null || echo "0")
    low_count=$(echo "$tfsec_output" | jq '[.results[]? | select(.severity == "LOW")] | length' 2>/dev/null || echo "0")
    
    if [[ "$high_count" -gt 0 ]]; then
      log_error "$high_count HIGH severity issues"
    fi
    if [[ "$medium_count" -gt 0 ]]; then
      log_warn "$medium_count MEDIUM severity issues"
    fi
    if [[ "$low_count" -gt 0 ]]; then
      log_info "$low_count LOW severity issues"
    fi
    
    # Show top 5 issues
    log_info "Top issues:"
    echo "$tfsec_output" | jq -r '.results[]? | "   - [\(.severity)] \(.rule_description) (\(.location.filename):\(.location.start_line))"' 2>/dev/null | head -5
  fi
}

check_required_variables() {
  log_info "Checking required variables..."
  
  # Find variables without defaults
  local required_vars
  required_vars=$(grep -h "^variable" *.tf 2>/dev/null | grep -v "default" | sed 's/variable "\([^"]*\)".*/\1/' || echo "")
  
  if [[ -n "$required_vars" ]]; then
    log_info "Variables without defaults (must be provided):"
    echo "$required_vars" | while read -r var; do
      [[ -n "$var" ]] && echo "   - $var"
    done
  fi
  
  # Check tfvars files
  local tfvars_count
  tfvars_count=$(ls -1 *.tfvars 2>/dev/null | wc -l || echo "0")
  log_info "$tfvars_count tfvars files found"
}

# Main
main() {
  local terraform_dir="."
  local run_init=false
  local check_drift=false
  local check_format=false
  local check_security=false
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      -d|--dir) terraform_dir="$2"; shift 2 ;;
      --init) run_init=true; shift ;;
      --check-drift) check_drift=true; shift ;;
      --check-format) check_format=true; shift ;;
      --check-security) check_security=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
  done
  
  # Change to terraform directory
  if [[ "$terraform_dir" != "." ]]; then
    cd "$terraform_dir"
  fi
  
  echo "═══════════════════════════════════════════════════════════"
  echo "       Terraform Validation                                "
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  log_info "Working directory: $(pwd)"
  echo ""
  
  validate_terraform_installed
  
  # Run init if requested
  if $run_init && [[ ! -d ".terraform" ]]; then
    log_info "Running terraform init..."
    terraform init
  fi
  
  validate_terraform_init
  validate_terraform_config
  validate_terraform_providers
  check_required_variables
  
  if $check_format; then
    echo ""
    validate_terraform_format
  fi
  
  validate_terraform_state
  
  if $check_drift; then
    echo ""
    check_terraform_drift
  fi
  
  if $check_security; then
    echo ""
    check_tfsec
  fi
  
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "Summary: $ERRORS errors, $WARNINGS warnings"
  echo "═══════════════════════════════════════════════════════════"
  
  exit $ERRORS
}

main "$@"
