#!/usr/bin/env bash

set -Eeuo pipefail

####################################
# Farben
####################################

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

####################################
# Logging
####################################

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

####################################
# Root prüfen
####################################

require_root() {

    if [[ "$EUID" -ne 0 ]]; then
        log_error "Bitte als root ausführen."
        exit 1
    fi

}

####################################
# Command vorhanden?
####################################

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

####################################
# Namespace
####################################

namespace_exists() {

    kubectl get namespace "$1" >/dev/null 2>&1

}

create_namespace() {

    if ! namespace_exists "$1"; then

        log_info "Erstelle Namespace $1"

        kubectl create namespace "$1"

    fi

}

####################################
# Helm
####################################

helm_release_exists() {

    local RELEASE=$1
    local NAMESPACE=$2

    helm status "$RELEASE" \
        -n "$NAMESPACE" \
        >/dev/null 2>&1

}

install_helm_chart() {

    local RELEASE=$1
    local CHART=$2
    local VERSION=$3
    local VALUES=$4
    local NAMESPACE=$5

    helm upgrade \
        --install \
        "$RELEASE" \
        "$CHART" \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --version "$VERSION" \
        --values "$VALUES"

}

####################################
# Kubernetes API
####################################

wait_for_api() {

    log_info "Warte auf Kubernetes API..."

    for i in {1..60}
    do

        if kubectl get --raw=/readyz >/dev/null 2>&1
        then
            log_ok "API Server bereit."
            return
        fi

        sleep 2

    done

    log_error "API Server nicht erreichbar."

    exit 1

}

####################################
# Rollout
####################################

wait_for_rollout() {

    local TYPE=$1
    local NAME=$2
    local NAMESPACE=$3

    kubectl rollout status \
        "${TYPE}/${NAME}" \
        -n "${NAMESPACE}" \
        --timeout="${WAIT_TIMEOUT}s"

}

####################################
# Node Ready
####################################

wait_for_node_ready() {

    log_info "Warte auf Ready Node..."

    for i in {1..120}
    do

        STATUS=$(kubectl get nodes \
            --no-headers \
            2>/dev/null \
            | awk '{print $2}')

        if [[ "$STATUS" == "Ready" ]]; then

            log_ok "Node Ready."

            return

        fi

        sleep 2

    done

    log_error "Node wurde nicht Ready."

    kubectl get nodes

    exit 1

}
