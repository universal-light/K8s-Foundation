#!/usr/bin/env bash
set -euo pipefail

source config.env

echo "[INFO] Initialisiere Kubernetes Cluster..."

# Cluster bereits vorhanden?
if [ -f /etc/kubernetes/admin.conf ]; then
    echo "[OK] Cluster bereits initialisiert."
    exit 0
fi

# kubelet muss laufen
if ! systemctl is-active --quiet kubelet; then
    echo "[ERROR] kubelet läuft nicht."
    exit 1
fi

echo "[INFO] Starte kubeadm..."

sudo kubeadm init \
    --pod-network-cidr="${POD_CIDR}" \
    --upload-certs

echo "[OK] Cluster erstellt."

echo "[INFO] Konfiguriere kubectl..."

mkdir -p "$HOME/.kube"

sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"

sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

echo "[INFO] Erzeuge Join Command..."

sudo kubeadm token create --print-join-command \
    | tee join-command.sh

chmod +x join-command.sh

echo ""
echo "[OK] Cluster erfolgreich initialisiert."
echo ""
echo "Worker können mit folgendem Script beitreten:"
echo ""
echo "./join-command.sh"
