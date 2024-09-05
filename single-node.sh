#!/bin/sh

# Periksa jumlah argumen
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <hostname> <email>"
    exit 1
fi

# Ambil parameter dari baris perintah
HOSTNAME=$1
EMAIL=$2

echo "Installing K3S"
curl  -sfL https://get.k3s.io  | INSTALL_K3S_VERSION="v1.30.4+k3s1" sh -s - --write-kubeconfig-mode 644

sudo chmod 747 /var/lib/rancher/k3s/server/manifests/ # Write permissions granted for other users not in the root usergroup. This currently doesn't work!

cat > /var/lib/rancher/k3s/server/manifests/rancher.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: cattle-system
---
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
  labels:
    certmanager.k8s.io/disable-validation: "true"
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  namespace: kube-system
  name: cert-manager
spec:
  targetNamespace: cert-manager
  version: v1.10.2
  chart: cert-manager
  repo: https://charts.jetstack.io
  set:
    installCRDs: "true"
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: rancher
  namespace: kube-system
spec:
  targetNamespace: cattle-system
  version: v2.9.1
  chart: rancher
  repo: https://releases.rancher.com/server-charts/latest
  set:
    ingress.tls.source: "letsEncrypt"
    letsEncrypt.ingress.class: "traefik"
    letsEncrypt.email: "$EMAIL"
    hostname: "$HOSTNAME"
    antiAffinity: "required"
    replicas: 1
EOF

echo "Rancher should be booted up in a few mins"
