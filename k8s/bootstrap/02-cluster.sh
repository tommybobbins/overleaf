#!/usr/bin/env bash
set -euo pipefail



#if [[ ! -e /etc/systemd/system/user@.service.d/delegate.conf ]]
#then
#  echo "  delegate.conf missing from systemd, adding...."
#  echo "  sudo password may be required...."
#  sudo mkdir -p /etc/systemd/system/user@.service.d
#  printf "[Service]\nDelegate=yes\n" | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
#  sudo systemctl daemon-reload
#else 
#  echo "  delegate.conf found, no need to add..."
#fi

if [[ -e /etc/debian_version ]]; then
  DEBIAN_VERSION=true
  export BUILD_ARGS="systemd-run --scope --user -p Delegate=yes"
else
  DEBIAN_VERSION=false
  export BUILD_ARGS=""
fi  


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-overleaf}"

export KIND_EXPERIMENTAL_PROVIDER=podman

echo "==> Creating kind cluster '${CLUSTER_NAME}'..."

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "  Cluster '${CLUSTER_NAME}' already exists, skipping."
else
 KIND_EXPERIMENTAL_PROVIDER=podman ${BUILD_ARGS} kind create cluster \
    --name "${CLUSTER_NAME}" \
    --config "${SCRIPT_DIR}/../kind/cluster.yaml" \
    --wait 120s
  echo "  [ok] Cluster created."
fi

echo ""
echo "==> Setting kubectl context..."
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

echo ""
echo "Cluster ready. Next: run 03-local-registry.sh"
