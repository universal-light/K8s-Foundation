#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

[[ "${INSTALL_FLANNEL}" != "true" ]] && exit 0

log_info "Installiere Flannel..."

wait_for_api

# Prüfen, ob Flannel bereits installiert ist
if kubectl get daemonset kube-flannel-ds -n kube-flannel >/dev/null 2>&1; then
    log_ok "Flannel bereits installiert."
    exit 0
fi

kubectl apply -f \
https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

log_info "Warte auf Flannel..."

kubectl rollout status \
    daemonset/kube-flannel-ds \
    -n kube-flannel \
    --timeout="${WAIT_TIMEOUT}s"

wait_for_node_ready

kubectl get pods -n kube-flannel

log_ok "Flannel erfolgreich installiert."
