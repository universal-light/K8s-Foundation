#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[ OK ]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

require_root() {

    if [ "$EUID" -ne 0 ]; then
        log_error "Bitte als root oder mit sudo ausführen."
        exit 1
    fi

}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

wait_for_api() {

    log_info "Warte auf Kubernetes API..."

    for i in {1..60}; do

        if kubectl get --raw=/readyz >/dev/null 2>&1; then
            log_ok "API Server erreichbar."
            return 0
        fi

        sleep 2

    done

    log_error "API Server nicht erreichbar."

    return 1

}

wait_for_node_ready() {

    log_info "Warte auf Node..."

    for i in {1..120}; do

        STATUS=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}')

        if [[ "$STATUS" == "Ready" || "$STATUS" == "NotReady" ]]; then
            log_ok "Node gefunden ($STATUS)."
            return 0
        fi

        sleep 2

    done

    log_error "Node wurde nicht gefunden."

    return 1

}
