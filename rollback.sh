#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

require_root

log_warn "================================================="
log_warn " Kubernetes Cluster wird vollständig zurückgesetzt"
log_warn "================================================="
echo

read -rp "Möchtest du wirklich fortfahren? (yes/no): " ANSWER

if [[ "${ANSWER}" != "yes" ]]; then
    log_info "Abgebrochen."
    exit 0
fi

########################################
# Cilium entfernen
########################################

if command_exists helm; then
    if helm ls -n kube-system | grep -q "^cilium"; then
        log_info "Entferne Cilium..."
        helm uninstall cilium -n kube-system || true
    fi
fi

########################################
# Ingress entfernen
########################################

if command_exists helm; then
    if helm ls -A | grep -q ingress-nginx; then
        log_info "Entferne Ingress..."
        helm uninstall ingress-nginx -n ingress-nginx || true
    fi
fi

########################################
# Metrics Server entfernen
########################################

if command_exists helm; then
    if helm ls -A | grep -q metrics-server; then
        log_info "Entferne Metrics Server..."
        helm uninstall metrics-server -n kube-system || true
    fi
fi

########################################
# MetalLB entfernen
########################################

if command_exists helm; then
    if helm ls -A | grep -q metallb; then
        log_info "Entferne MetalLB..."
        helm uninstall metallb -n metallb-system || true
    fi
fi

########################################
# kubeadm Reset
########################################

log_info "Setze Kubernetes zurück..."

kubeadm reset -f

########################################
# kubeconfig löschen
########################################

log_info "Entferne kubeconfig..."

rm -rf "$HOME/.kube"

########################################
# CNI löschen
########################################

log_info "Entferne CNI..."

rm -rf /etc/cni/net.d
rm -rf /opt/cni/bin

########################################
# Kubernetes Daten löschen
########################################

rm -rf /var/lib/etcd
rm -rf /var/lib/kubelet
rm -rf /etc/kubernetes

########################################
# Netzwerk bereinigen
########################################

ip link delete cilium_host 2>/dev/null || true
ip link delete cilium_net 2>/dev/null || true
ip link delete cilium_vxlan 2>/dev/null || true

########################################
# iptables bereinigen
########################################

iptables -F || true
iptables -t nat -F || true
iptables -t mangle -F || true

ip6tables -F || true
ip6tables -t nat -F || true
ip6tables -t mangle -F || true

########################################
# Dienste neu starten
########################################

systemctl restart containerd || true
systemctl restart kubelet || true

########################################
# Logs
########################################

rm -f "${ROOT_DIR}/logs/"*.log

########################################

log_ok "Rollback abgeschlossen."

echo
echo "Der Server befindet sich wieder in einem sauberen Zustand."
echo
echo "Zum Neuaufsetzen:"
echo
echo "sudo ./install.sh"
