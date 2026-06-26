#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

[[ "${INSTALL_METALLB}" != "true" ]] && exit 0

log_info "Installiere MetalLB..."

install_helm_chart \
    metallb \
    metallb/metallb \
    "${METALLB_VERSION}" \
    "${ROOT_DIR}/values/metallb.yaml" \
    metallb-system

wait_for_rollout deployment controller metallb-system

log_info "Erzeuge IPAddressPool..."

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - ${METALLB_IP_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec: {}
EOF

log_ok "MetalLB installiert."
