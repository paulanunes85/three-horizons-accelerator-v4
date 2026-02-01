---
description: 'Shell/Bash scripting standards, error handling patterns, and best practices for automation scripts in Three Horizons Accelerator'
applyTo: '**/*.sh,**/scripts/**'
---

# Shell Scripting Standards

## Script Header Template

```bash
#!/bin/bash
# =============================================================================
# SCRIPT_NAME - Brief description
# =============================================================================
#
# Purpose: What this script does
# Usage: ./script-name.sh [options]
#
# Arguments:
#   --option     Description of option
#   --help       Show usage information
#
# Examples:
#   ./script-name.sh --environment dev
#   ./script-name.sh --help
#
# =============================================================================

set -euo pipefail
```

## Required Strict Mode

ALWAYS start scripts with:

```bash
set -euo pipefail

# -e: Exit on error
# -u: Exit on undefined variable
# -o pipefail: Exit on pipe failures
```

## Color and Logging Standards

```bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }
log_step()    { echo -e "${PURPLE}[STEP]${NC} $1"; }
```

## Usage Function Pattern

```bash
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Description of what the script does.

Options:
    -e, --environment    Environment (dev, staging, prod)
    -r, --region         Azure region
    -h, --help           Show this help message
    -v, --verbose        Enable verbose output

Examples:
    $(basename "$0") --environment dev
    $(basename "$0") -e prod -r eastus2

EOF
    exit 1
}
```

## Argument Parsing

```bash
# Default values
ENVIRONMENT=""
REGION="eastus2"
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$ENVIRONMENT" ]]; then
    log_error "Environment is required"
    usage
fi
```

## Prerequisite Checking

```bash
check_prerequisites() {
    local missing=()
    
    command -v az &>/dev/null || missing+=("az (Azure CLI)")
    command -v terraform &>/dev/null || missing+=("terraform")
    command -v kubectl &>/dev/null || missing+=("kubectl")
    command -v jq &>/dev/null || missing+=("jq")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing prerequisites:"
        for tool in "${missing[@]}"; do
            log_error "  - $tool"
        done
        exit 1
    fi
    
    log_success "All prerequisites met"
}
```

## Error Handling

```bash
# Trap for cleanup on error
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code: $exit_code"
    fi
    # Cleanup temporary files
    rm -rf "${TMPDIR:-/tmp}/script-$$-*" 2>/dev/null || true
}
trap cleanup EXIT

# Error function
die() {
    log_error "$1"
    exit "${2:-1}"
}
```

## Confirmation Prompts

```bash
confirm() {
    local prompt="${1:-Are you sure?}"
    read -r -p "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Usage
if ! confirm "Deploy to production?"; then
    log_info "Deployment cancelled"
    exit 0
fi
```

## Variable Naming

- Use UPPERCASE for environment variables and constants
- Use lowercase for local variables
- Use descriptive names: `RESOURCE_GROUP_NAME` not `RG`

## Security Requirements

- NEVER echo passwords or secrets
- Use `read -s` for sensitive input
- Store secrets in Azure Key Vault
- Validate all user inputs
- Use shellcheck for linting

## Common Patterns

### Retry Logic

```bash
retry() {
    local max_attempts="${1:-3}"
    local delay="${2:-5}"
    shift 2
    local attempt=1
    
    until "$@"; do
        if [[ $attempt -ge $max_attempts ]]; then
            log_error "Command failed after $max_attempts attempts"
            return 1
        fi
        log_warning "Attempt $attempt failed. Retrying in ${delay}s..."
        sleep "$delay"
        ((attempt++))
    done
}

# Usage
retry 3 5 az group create --name "$RG_NAME" --location "$LOCATION"
```

### Progress Indicator

```bash
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}
```

## Validation

- Run `shellcheck` on all scripts
- Test scripts in dev environment first
- Include `--dry-run` option for destructive operations

