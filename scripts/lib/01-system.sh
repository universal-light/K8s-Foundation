#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

log_info "Bereite Ubuntu für Kubernetes vor..."

apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gpg \
    software-properties-common

####################################
# Swap deaktivieren
####################################

if swapon --summary | grep -q .; then
    log_info "Deaktiviere Swap..."
    swapoff -a
fi

sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

####################################
# Kernel Module
####################################

cat >/etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

####################################
# Sysctl
####################################

cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system >/dev/null

####################################
# Zeit synchronisieren
####################################

systemctl enable systemd-timesyncd
systemctl restart systemd-timesyncd

####################################
# Firewall
####################################

if command_exists ufw; then
    log_warn "UFW erkannt."

    ufw allow 6443/tcp || true
    ufw allow 2379:2380/tcp || true
    ufw allow 10250/tcp || true
    ufw allow 10257/tcp || true
    ufw allow 10259/tcp || true
fi

log_ok "System erfolgreich vorbereitet."
