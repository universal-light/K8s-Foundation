#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

[[ "${INSTALL_INGRESS}" != "true" ]] && exit 0

log_info "Installiere Ingress NGINX..."

install_helm_chart \
    ingress-nginx \
    ingress-nginx/ingress-nginx \
    "${INGRESS_NGINX_VERSION}" \
    "${ROOT_DIR}/values/ingress-nginx.yaml" \
    ingress-nginx

wait_for_rollout deployment ingress-nginx-controller ingress-nginx

kubectl get svc -n ingress-nginx

log_ok "Ingress Controller bereit."
