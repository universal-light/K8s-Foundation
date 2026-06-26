#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

PASS=0
WARN=0
FAIL=0

print_result() {

    local STATUS="$1"
    local NAME="$2"

    case "$STATUS" in
        OK)
            echo -e "\033[32m[ OK ]\033[0m ${NAME}"
            ((PASS++))
            ;;
        WARN)
            echo -e "\033[33m[WARN]\033[0m ${NAME}"
            ((WARN++))
            ;;
        FAIL)
            echo -e "\033[31m[FAIL]\033[0m ${NAME}"
            ((FAIL++))
            ;;
    esac
}

echo
echo "==========================================="
echo " Kubernetes Bootstrap Healthcheck"
echo "==========================================="
echo

############################################################
# Container Runtime
############################################################

if systemctl is-active --quiet containerd; then
    print_result OK "containerd"
else
    print_result FAIL "containerd"
fi

############################################################
# kubelet
############################################################

if systemctl is-active --quiet kubelet; then
    print_result OK "kubelet"
else
    print_result FAIL "kubelet"
fi

############################################################
# API Server
############################################################

if kubectl get --raw=/readyz >/dev/null 2>&1; then
    print_result OK "Kubernetes API"
else
    print_result FAIL "Kubernetes API"
fi

############################################################
# Nodes
############################################################

READY=$(kubectl get nodes --no-headers 2>/dev/null | awk '$2=="Ready"{count++} END{print count+0}')

if [[ "$READY" -gt 0 ]]; then
    print_result OK "Node Ready (${READY})"
else
    print_result FAIL "Node Ready"
fi

############################################################
# CoreDNS
############################################################

if kubectl get deployment coredns -n kube-system >/dev/null 2>&1; then

    AVAILABLE=$(kubectl get deployment coredns -n kube-system \
        -o jsonpath='{.status.availableReplicas}')

    if [[ "${AVAILABLE:-0}" -ge 1 ]]; then
        print_result OK "CoreDNS"
    else
        print_result FAIL "CoreDNS"
    fi

fi

############################################################
# Helm
############################################################

if command -v helm >/dev/null 2>&1; then
    print_result OK "Helm"
else
    print_result FAIL "Helm"
fi

############################################################
# Cilium
############################################################

if helm status cilium -n kube-system >/dev/null 2>&1; then
    print_result OK "Cilium"
else
    print_result WARN "Cilium"
fi

############################################################
# Hubble
############################################################

if kubectl get deployment hubble-relay -n kube-system >/dev/null 2>&1; then
    print_result OK "Hubble"
else
    print_result WARN "Hubble"
fi

############################################################
# Ingress
############################################################

if helm status ingress-nginx -n ingress-nginx >/dev/null 2>&1; then
    print_result OK "Ingress NGINX"
else
    print_result WARN "Ingress NGINX"
fi

############################################################
# MetalLB
############################################################

if helm status metallb -n metallb-system >/dev/null 2>&1; then
    print_result OK "MetalLB"
else
    print_result WARN "MetalLB"
fi

############################################################
# Cert Manager
############################################################

if helm status cert-manager -n cert-manager >/dev/null 2>&1; then
    print_result OK "cert-manager"
else
    print_result WARN "cert-manager"
fi

############################################################
# Metrics Server
############################################################

if kubectl top nodes >/dev/null 2>&1; then
    print_result OK "Metrics Server"
else
    print_result WARN "Metrics Server"
fi

############################################################
# StorageClass
############################################################

if kubectl get storageclass >/dev/null 2>&1; then
    print_result OK "StorageClass"
else
    print_result WARN "StorageClass"
fi

############################################################
# Cluster Info
############################################################

if kubectl cluster-info >/dev/null 2>&1; then
    print_result OK "Cluster Info"
else
    print_result FAIL "Cluster Info"
fi

############################################################
# Versionen
############################################################

echo
echo "-------------------------------------------"

echo "Kubernetes : $(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')"

echo "Node(s):"
kubectl get nodes

echo
echo "Pods:"
kubectl get pods -A

echo
echo "-------------------------------------------"

echo "Erfolgreich : ${PASS}"
echo "Warnungen   : ${WARN}"
echo "Fehler      : ${FAIL}"

echo "-------------------------------------------"

if [[ "$FAIL" -eq 0 ]]; then
    echo
    echo "✅ Cluster Status: HEALTHY"
else
    echo
    echo "❌ Cluster Status: UNHEALTHY"
fi

echo
