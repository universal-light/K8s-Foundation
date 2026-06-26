#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${ROOT_DIR}/config.env"
source "${ROOT_DIR}/scripts/lib/common.sh"

require_root

LOG_DIR="${ROOT_DIR}/logs"
mkdir -p "${LOG_DIR}"

LOG_FILE="${LOG_DIR}/install.log"

exec > >(tee -a "${LOG_FILE}") 2>&1

log_info "========================================"
log_info " Kubernetes Bootstrap"
log_info "========================================"

log_info "Cluster Name : ${CLUSTER_NAME}"
log_info "Kubernetes   : ${K8S_VERSION}"

run_script() {

    local script="$1"

    log_info ""
    log_info "----------------------------------------"
    log_info "Starte ${script}"
    log_info "----------------------------------------"

    bash "${ROOT_DIR}/scripts/${script}"

    log_ok "${script} abgeschlossen."
}

run_script "01-system.sh"
run_script "02-containerd.sh"
run_script "03-kubernetes.sh"
run_script "04-init-cluster.sh"

if [[ "${INSTALL_HELM}" == "true" ]]; then
    run_script "05-helm.sh"
fi

if [[ "${INSTALL_FLANNEL}" == "true" ]]; then
    run_script "06-flannel.sh"
fi

if [[ "${INSTALL_INGRESS}" == "true" ]]; then
    run_script "07-ingress-nginx.sh"
fi

if [[ "${INSTALL_METALLB}" == "true" ]]; then
    run_script "08-metallb.sh"
fi

if [[ "${INSTALL_METRICS_SERVER}" == "true" ]]; then
    run_script "10-metrics-server.sh"
fi

run_script "99-healthcheck.sh"

log_ok ""
log_ok "Bootstrap erfolgreich abgeschlossen."
