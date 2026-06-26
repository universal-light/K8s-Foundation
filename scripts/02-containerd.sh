#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Installiere containerd..."

if command -v containerd >/dev/null 2>&1; then
    echo "[OK] containerd ist bereits installiert."
else
    sudo apt-get update
    sudo apt-get install -y containerd
fi

echo "[INFO] Erstelle Konfigurationsverzeichnis..."
sudo mkdir -p /etc/containerd

if [ ! -f /etc/containerd/config.toml ]; then
    echo "[INFO] Erzeuge Standardkonfiguration..."
    containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
else
    echo "[OK] config.toml existiert bereits."
fi

echo "[INFO] Aktiviere SystemdCgroup..."

sudo sed -i \
    's/SystemdCgroup = false/SystemdCgroup = true/' \
    /etc/containerd/config.toml

echo "[INFO] Starte containerd neu..."

sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd

echo "[INFO] Prüfe Status..."

if systemctl is-active --quiet containerd; then
    echo "[OK] containerd läuft."
else
    echo "[ERROR] containerd konnte nicht gestartet werden."
    exit 1
fi

echo "[INFO] Installiere crictl..."

if ! command -v crictl >/dev/null 2>&1; then
    VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest \
        | grep tag_name \
        | cut -d '"' -f4)

    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64)
            ARCH=amd64
            ;;
        aarch64)
            ARCH=arm64
            ;;
        *)
            echo "[ERROR] Architektur $ARCH wird nicht unterstützt."
            exit 1
            ;;
    esac

    curl -L \
      "https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/crictl-${VERSION}-linux-${ARCH}.tar.gz" \
      -o /tmp/crictl.tar.gz

    sudo tar -C /usr/local/bin -xzf /tmp/crictl.tar.gz
    rm /tmp/crictl.tar.gz
fi

sudo tee /etc/crictl.yaml >/dev/null <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

echo "[OK] containerd erfolgreich eingerichtet."
