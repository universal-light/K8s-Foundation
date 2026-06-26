#!/usr/bin/env bash

set -euo pipefail

source config.env
source scripts/lib/common.sh

require_root

log_info "Starte Kubernetes Bootstrap..."

for script in scripts/*.sh
do

    [[ "$script" == *"lib"* ]] && continue

    log_info "Starte $(basename "$script")"

    bash "$script"

done

log_ok "Bootstrap abgeschlossen."
