#!/usr/bin/env bash

set -euo pipefail

source config.env
source scripts/lib/common.sh

if [ "$INSTALL_CILIUM" != "true" ]; then
    log_warn "Cilium Installation deaktiviert."
    exit 0
fi

log_info "Installiere Cilium..."

wait_for_api

if kubectl get daemonset cilium -n kube-system >/dev/null 2>&1; then
    log_ok "Cilium bereits installiert."
    exit 0
fi

#######################################
# Helm Repository
#######################################

if ! helm repo list | grep -q cilium; then
    helm repo add cilium https://helm.cilium.io
fi

helm repo update

#######################################
# Installation
#######################################

helm upgrade \
    --install cilium \
    cilium/cilium \
    --namespace kube-system \
    --version "${CILIUM_VERSION}" \
    --values values/cilium.yaml

#######################################
# Warten
#######################################

log_info "Warte auf Cilium..."

kubectl rollout status daemonset/cilium \
    -n kube-system \
    --timeout=10m

kubectl rollout status deployment/cilium-operator \
    -n kube-system \
    --timeout=10m

#######################################
# Kontrolle
#######################################

READY=$(kubectl get nodes --no-headers | awk '{print $2}')

if [[ "$READY" == "Ready" ]]; then
    log_ok "Node Ready."
else
    log_error "Node nicht Ready."
    kubectl get nodes
    exit 1
fi

log_ok "Cilium erfolgreich installiert."
