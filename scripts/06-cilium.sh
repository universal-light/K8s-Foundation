#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

[[ "${INSTALL_CILIUM}" != "true" ]] && exit 0

log_info "Installiere Cilium..."

wait_for_api

install_helm_chart \
    cilium \
    cilium/cilium \
    "${CILIUM_VERSION}" \
    "${ROOT_DIR}/values/cilium.yaml" \
    kube-system

log_info "Warte auf Cilium..."

wait_for_rollout daemonset cilium kube-system

kubectl wait \
    --for=condition=Available \
    deployment/cilium-operator \
    -n kube-system \
    --timeout="${WAIT_TIMEOUT}s"

wait_for_node_ready

kubectl get pods -n kube-system -l k8s-app=cilium

log_ok "Cilium erfolgreich installiert."
