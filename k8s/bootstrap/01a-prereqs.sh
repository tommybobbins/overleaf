#!/usr/bin/env bash
set -euo pipefail

REQUIRED_TOOLS=(kind kubectl helm podman argocd)
unset DEBIAN_VERSION
MISSING=()

if [[ -e /etc/debian_version ]]; then
  echo ""
  echo "This looks like a Debian based Linux"
  DEBIAN_VERSION=true
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
  echo "  sudo apt install kind kubectl helm"
  echo "  curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
  echo "  sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
  echo "  rm argocd-linux-amd64"
  echo ""
  echo "  curl -sSL -o podman.tar.gz https://github.com/podman-container-tools/podman/releases/download/v6.0.2/podman-remote-static-linux_amd64.tar.gz"
  echo "  tar xvf podman.tar.gz"
  echo "  cp bin/podman-remote-static-linux_amd64 /usr/local/bin/podman"
  echo "  rm -rf podman.tar.gz; rm -rf bin/podman-remote-static-linux_amd64"
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
