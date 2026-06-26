#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

log_info "Installiere Kubernetes ${K8S_VERSION}..."

mkdir -p /etc/apt/keyrings

if [[ ! -f /etc/apt/sources.list.d/kubernetes.list ]]; then

    curl -fsSL \
    https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key \
    | gpg --dearmor \
    -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /
EOF

fi

apt-get update

apt-get install -y \
    kubelet \
    kubeadm \
    kubectl

apt-mark hold \
    kubelet \
    kubeadm \
    kubectl

systemctl enable kubelet

log_ok "Kubernetes installiert."

kubectl version --client || true
kubeadm version
kubelet --version
