#!/usr/bin/env bash
set -euxo pipefail

CLUSTER_NETWORK=""
CLUSTER="Kubernetes" #This is a fixed value

istioctl operator init

cat <<EOF > vm-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: "${CLUSTER}"
      network: "${CLUSTER_NETWORK}"
  meshConfig:
    accessLogFile: /dev/stdout
EOF

istioctl install -f vm-cluster.yaml -y
