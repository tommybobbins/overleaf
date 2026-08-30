#!/usr/bin/env bash
set -euo pipefail

REQUIRED_TOOLS=(kind kubectl helm podman argocd)
unset DEBIAN_VERSION
MISSING=()

if [[ -e /etc/debian_version ]]; then
  echo ""
  echo "This looks like a Debian based Linux"
  DEBIAN_VERSION=true
  if [[ $(uname -m) == "aarch64" ]]
    then
       ARCH=arm64
  elif [[ $(uname -m) == "amd64" ]]
    then
       ARCH=amd64
  fi
else
  DEBIAN_VERSION=false
fi  

for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    MISSING+=("$tool")
  else
    echo "  [ok] $tool $(timeout 1 ${tool} version --short 2>/dev/null | head -1 || timeout 1 ${tool} version 2>/dev/null | head -1)"
    #echo "  [ok] $tool $(timeout 1 ${tool} version --short 2>/dev/null | head -1 || timeout 1 ${tool} --version 2>/dev/null | head -1 || timeout 1 ${tool} version 2>/dev/null | head -1)"
  fi
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
  echo ""
  echo " Nothing missing. Continue"
  exit 0
elif [[ ${#MISSING[@]} -gt 0 ]] && [[ ${DEBIAN_VERSION} == "false" ]]; then
  echo ""
  echo "Missing tools: ${MISSING[*]}"
  echo ""
  echo "Install via Homebrew:"
  echo "  brew install kind kubectl helm podman"
  echo "  brew install argocd"
  exit 1
elif [[ ${#MISSING[@]} -gt 0 ]] &&  [[ ${DEBIAN_VERSION} == "true" ]]; then
  echo ""
  echo "Missing tools: ${MISSING[*]}"
  echo ""
  echo "Install via apt:"
  echo "  sudo apt update"
  echo "  sudo apt install kind kubectl"
  echo "  curl -sSL -o /tmp/argocd-linux-${ARCH} https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${ARCH}"
  echo "  sudo install -m 555 /tmp/argocd-linux-${ARCH} /usr/local/bin/argocd"
  echo "  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4"
  echo "  chmod 700 /tmp/get_helm.sh"
  echo "  /tmp/get_helm.sh"
  echo "  rm /tmp/argocd-linux-${ARCH} /tmp/get_helm.sh"
  echo ""
  echo "  curl -sSL -o /tmp/podman.tar.gz https://github.com/podman-container-tools/podman/releases/download/v6.0.2/podman-remote-static-linux_${ARCH}.tar.gz"
  echo "  tar zxvf /tmp/podman.tar.gz"
  echo "  sudo cp bin/podman-remote-static-linux_${ARCH} /usr/local/bin/podman"
  echo "  rm -rf bin"
  echo "  rm -rf /tmp/podman.tar.gz; rm -rf /tmp/bin/podman-remote-static-linux_${ARCH}"
  echo ""
  exit 1
else 
  echo "  I don't know what this version of *nux/macOS is"
  exit 2
fi

echo ""
echo "Checking podman machine..."

if [[ if ${DEBIAN_VERSION} == "true" ]]; then
  echo "  This still looks like Debian, no need to run podman machine init."
  echo ""
elif [[ ! $(podman machine list 2>/dev/null | grep -q running) ]]; then
  echo "  No running podman machine found. Starting default machine..."
  exit 1
  podman machine init --memory 8192 --cpus 4 --disk-size 40 2>/dev/null || true
  podman machine start
else
  echo "  [ok] podman machine running"
fi

echo ""
echo "All prerequisites satisfied."
