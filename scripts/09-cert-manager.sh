#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

[[ "${INSTALL_CERT_MANAGER}" != "true" ]] && exit 0

log_info "Installiere cert-manager..."

install_helm_chart \
    cert-manager \
    jetstack/cert-manager \
    "${CERT_MANAGER_VERSION}" \
    "${ROOT_DIR}/values/cert-manager.yaml" \
    cert-manager

wait_for_rollout deployment cert-manager cert-manager

log_ok "cert-manager installiert."
