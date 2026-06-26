#!/usr/bin/env bash
set -euo pipefail

source config.env

echo "== Kubernetes Bootstrap =="

for script in scripts/*.sh; do
    echo ">>> $(basename "$script")"
    bash "$script"
done

echo ""
echo "=================================="
echo " Bootstrap abgeschlossen"
echo "=================================="
