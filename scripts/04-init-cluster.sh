#!/usr/bin/env bash

set -euo pipefail

source config.env
source scripts/lib/common.sh

log_info "Initialisiere Cluster..."

if [ -f /etc/kubernetes/admin.conf ]; then
    log_ok "Cluster bereits vorhanden."
    exit 0
fi

kubeadm init \
    --pod-network-cidr="${POD_CIDR}" \
    --upload-certs

mkdir -p "$HOME/.kube"

cp /etc/kubernetes/admin.conf "$HOME/.kube/config"

chown "$(id -u):$(id -g)" "$HOME/.kube/config"

wait_for_api

wait_for_node_ready

kubeadm token create \
    --print-join-command \
    > join-command.sh

chmod +x join-command.sh

if [ "$SINGLE_NODE" = true ]; then

    kubectl taint nodes \
        --all \
        node-role.kubernetes.io/control-plane- || true

fi

log_ok "Cluster erfolgreich initialisiert."
