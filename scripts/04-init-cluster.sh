#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

log_info "Initialisiere Kubernetes Cluster..."

if [[ -f /etc/kubernetes/admin.conf ]]; then
    log_ok "Cluster bereits initialisiert."
    exit 0
fi

INIT_ARGS=(
    "--pod-network-cidr=${POD_CIDR}"
    "--service-cidr=${SERVICE_CIDR}"
    "--upload-certs"
)

if [[ -n "${CONTROL_PLANE_ENDPOINT}" ]]; then
    INIT_ARGS+=("--control-plane-endpoint=${CONTROL_PLANE_ENDPOINT}")
fi

kubeadm init "${INIT_ARGS[@]}"

mkdir -p "${HOME}/.kube"

cp /etc/kubernetes/admin.conf "${HOME}/.kube/config"

chown "$(id -u):$(id -g)" "${HOME}/.kube/config"

export KUBECONFIG="${HOME}/.kube/config"

wait_for_api

log_info "Erzeuge Join Command..."

kubeadm token create \
    --print-join-command \
    > "${ROOT_DIR}/join-command.sh"

chmod +x "${ROOT_DIR}/join-command.sh"

if [[ "${SINGLE_NODE}" == "true" ]]; then

    log_info "Entferne Control Plane Taint..."

    kubectl taint nodes \
        --all \
        node-role.kubernetes.io/control-plane- \
        || true

fi

kubectl get nodes

log_ok "Cluster erfolgreich initialisiert."
