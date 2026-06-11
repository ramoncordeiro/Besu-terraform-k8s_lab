#!/usr/bin/env bash


set -euo pipefail



K3S_KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
UBUNTU_HOME="/home/ubuntu"
UBUNTU_KUBECONFIG="${UBUNTU_HOME}/.kube/config"
HELM_VERSION="v3.17.0"

# color logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

fail() { echo -e "${RED}FAIL: $1${NC}" >&2; exit 1; }
ok()   { echo -e "${GREEN}OK: $1${NC}"; }
info() { echo -e "${YELLOW}INFO: $1${NC}"; }

#step 1: Install k3s

info "Installing k3s..."

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable=traefik --disable=servicelb" sh -

info "waiting k3s to be ready..."
for i in {1..30}; do
    if systemctl is-active --quiet k3s; then
        break
    fi
    sleep 2
done

systemctl is-active --quiet k3s || fail "k3s did not start"
ok "k3s is running"

# Step 2: config kubeconfig for ubuntu user
info "Configuring kubeconfig for ubuntu user..."
mkdir -p "$(dirname "${UBUNTU_KUBECONFIG}")"
cp "${K3S_KUBECONFIG}" "${UBUNTU_KUBECONFIG}"


chown ubuntu:ubuntu "${UBUNTU_KUBECONFIG}"
chmod 600 "${UBUNTU_KUBECONFIG}"
ok "kubeconfig copied to ${UBUNTU_KUBECONFIG}"

#Use AWS-public-IP (change to the public ip address of EC2)
IP_PUBLICO=$(curl -sf http://169.254.169.254/latest/meta-data/public-ipv4)
sed -i "s|https://127.0.0.1:6443|https://${IP_PUBLICO}:6443|" "${UBUNTU_KUBECONFIG}"
ok "kubeconfig updated with public IP ${IP_PUBLICO}:6443"

# step 3: instll helm3

info "Installing Helm ${HELM_VERSION}..."
curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -o get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh --version "${HELM_VERSION}"
rm -f get_helm.sh

HELM_VERSION_INSTALLED=$(helm version --short)
ok "Helm ${HELM_VERSION_INSTALLED} installed"

# Step: health check final

info "verifying cluster health..."
export KUBECONFIG="${K3S_KUBECONFIG}"

# wait for the node to be ready
for i in {1..30}; do
    if kubectl get nodes | grep -q "Ready"; then
        break
    fi
    sleep 2
done

kubectl get nodes | grep -q "Ready" || fail "Node k3s did not become ready"

info "cluster node "
kubectl get nodes -o wide

ok "Cluster k3s is healthy and Ready"