#!/usr/bin/env bash
set -euo pipefail

CLUSTER="${1:-devcluster}"
TAG="${2:-latest}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Building images with tag '$TAG' and importing into k3d cluster '$CLUSTER'"

# Build product service image
docker build -t "denzel1999/productservice:${TAG}" -f "${ROOT_DIR}/dotnet-docker/Products/Dockerfile" "${ROOT_DIR}/dotnet-docker"

# Build store frontend image
docker build -t "denzel1999/storeimage:${TAG}" -f "${ROOT_DIR}/dotnet-observability/eShopLite/Store/Dockerfile" "${ROOT_DIR}/dotnet-observability"

# Save images to temp tar files
TMP1=$(mktemp -u --suffix=.tar /tmp/productservice-XXXXX)
TMP2=$(mktemp -u --suffix=.tar /tmp/storeimage-XXXXX)

docker save "denzel1999/productservice:${TAG}" -o "${TMP1}"
docker save "denzel1999/storeimage:${TAG}" -o "${TMP2}"

# Import into k3d
k3d image import -c "${CLUSTER}" "${TMP1}" "${TMP2}"

# Cleanup
rm -f "${TMP1}" "${TMP2}"

# Restart deployments so pods pick up the images
kubectl rollout restart deployment productsbackend -n default || true
kubectl rollout restart deployment storefrontend -n default || true

echo "Done. Check pods with: kubectl get pods -A -o wide" 
