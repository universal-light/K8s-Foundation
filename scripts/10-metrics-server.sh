#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

[[ "${INSTALL_METRICS_SERVER}" != "true" ]] && exit 0

log_info "Installiere Metrics Server..."

install_helm_chart \
    metrics-server \
    metrics-server/metrics-server \
    "${METRICS_SERVER_VERSION}" \
    "${ROOT_DIR}/values/metrics-server.yaml" \
    kube-system

wait_for_rollout deployment metrics-server kube-system

kubectl top nodes >/dev/null 2>&1 || true

log_ok "Metrics Server installiert."
