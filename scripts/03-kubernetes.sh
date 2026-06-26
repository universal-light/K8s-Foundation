#!/usr/bin/env bash
set -euo pipefail

source config.env

echo "[INFO] Installiere Kubernetes..."

# Voraussetzungen
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Keyring-Verzeichnis
sudo mkdir -p /etc/apt/keyrings

# Repository nur hinzufügen, wenn es noch nicht existiert
if [ ! -f /etc/apt/sources.list.d/kubernetes.list ]; then

    echo "[INFO] Kubernetes Repository hinzufügen..."

    curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key \
        | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" \
        | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
fi

sudo apt-get update

echo "[INFO] Installiere kubelet, kubeadm und kubectl..."

sudo apt-get install -y \
    kubelet \
    kubeadm \
    kubectl

sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable kubelet

echo "[OK] Kubernetes erfolgreich installiert."

echo ""
echo "Versionen:"
kubectl version --client
kubeadm version
kubelet --version
