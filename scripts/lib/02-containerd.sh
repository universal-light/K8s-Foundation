#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

log_info "Installiere Container Runtime..."

if ! command_exists containerd; then

    apt-get update
    apt-get install -y containerd

fi

mkdir -p /etc/containerd

if [[ ! -f /etc/containerd/config.toml ]]; then
    containerd config default >/etc/containerd/config.toml
fi

sed -i \
's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml

systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd

if ! systemctl is-active --quiet containerd; then
    log_error "containerd konnte nicht gestartet werden."
    exit 1
fi

####################################
# crictl
####################################

if ! command_exists crictl; then

    VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest \
        | grep tag_name \
        | cut -d'"' -f4)

    ARCH=$(uname -m)

    case "${ARCH}" in
        x86_64)
            ARCH=amd64
            ;;
        aarch64)
            ARCH=arm64
            ;;
        *)
            log_error "Architektur nicht unterstützt."
            exit 1
            ;;
    esac

    curl -L \
    "https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/crictl-${VERSION}-linux-${ARCH}.tar.gz" \
    -o /tmp/crictl.tar.gz

    tar -C /usr/local/bin -xzf /tmp/crictl.tar.gz

    rm /tmp/crictl.tar.gz

fi

cat >/etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

log_ok "containerd bereit."
