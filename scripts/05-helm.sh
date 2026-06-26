#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

if [[ "${INSTALL_HELM}" != "true" ]]; then
    log_warn "Helm Installation deaktiviert."
    exit 0
fi

log_info "Installiere Helm..."

if command_exists helm; then

    VERSION=$(helm version --short | sed 's/^v//' | cut -d'+' -f1)

    if [[ "${VERSION}" == "${HELM_VERSION}" ]]; then
        log_ok "Helm ${VERSION} bereits installiert."
    else
        log_warn "Helm ${VERSION} gefunden."
        log_info "Upgrade auf ${HELM_VERSION}..."
    fi
else

    ARCH=$(uname -m)

    case "${ARCH}" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        *)
            log_error "Architektur ${ARCH} wird nicht unterstützt."
            exit 1
            ;;
    esac

    TMP_DIR=$(mktemp -d)

    cd "${TMP_DIR}"

    curl -fsSL \
        "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" \
        -o helm.tar.gz

    tar -xzf helm.tar.gz

    install "linux-${ARCH}/helm" /usr/local/bin/helm

    cd /

    rm -rf "${TMP_DIR}"

fi

helm version

#########################################
# Repositories
#########################################

log_info "Füge Helm Repositories hinzu..."

declare -A REPOS=(
    ["cilium"]="https://helm.cilium.io"
    ["ingress-nginx"]="https://kubernetes.github.io/ingress-nginx"
    ["jetstack"]="https://charts.jetstack.io"
    ["metallb"]="https://metallb.github.io/metallb"
    ["metrics-server"]="https://kubernetes-sigs.github.io/metrics-server"
)

for NAME in "${!REPOS[@]}"
do

    if ! helm repo list | awk '{print $1}' | grep -qx "${NAME}"; then
        helm repo add "${NAME}" "${REPOS[$NAME]}"
    fi

done

helm repo update

log_ok "Helm bereit."
