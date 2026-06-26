#!/usr/bin/env bash

set -e

echo "Cluster wird zurückgesetzt..."

kubeadm reset -f

rm -rf ~/.kube

rm -rf /etc/cni/net.d

systemctl restart containerd

systemctl restart kubelet

echo "Fertig."
