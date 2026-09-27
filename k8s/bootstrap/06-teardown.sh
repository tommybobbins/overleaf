#!/usr/bin/env bash

echo "  Removing the aardvark-dns network...."
podman container stop overleaf-control-plane kind-registry
echo "  Done...."
rm -rf /run/user/1000/containers/networks/aardvark-dns
echo "  Deleting the overleaf cluster"
KIND_EXPERIMENTAL_PROVIDER=podman kind delete cluster -n overleaf
