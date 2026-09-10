#!/usr/bin/env bash
set -euo pipefail

# Builds the DVWP image (with the vulnerable plugins/themes baked in) and
# pushes it to Docker Hub. No Dockerfile lives in the repo; the image is
# built from an inline build context.
#
# Usage:
#   DOCKER_USER=vavkamil bin/publish.sh          # pushes vavkamil/dvwp:latest
#   DOCKER_USER=you DVWP_VERSION=1.0 bin/publish.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

: "${DOCKER_USER:?set DOCKER_USER (your Docker Hub username), e.g. DOCKER_USER=vavkamil}"
: "${DVWP_VERSION:=latest}"
IMAGE="$DOCKER_USER/dvwp:$DVWP_VERSION"

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon is not running." >&2
  exit 1
fi

echo "==> Fetching vulnerable plugins/themes..."
"$ROOT/bin/download-plugins.sh"

echo "==> docker login..."
docker login

echo "==> Building $IMAGE (Dockerfile provided inline, none stored in repo)..."
docker build -t "$IMAGE" - <<'EOF'
FROM wordpress:7.1-php8.3-apache

COPY ./otherz /var/www/html/
COPY ./otherz/php.ini /usr/local/etc/php/conf.d/zz-dvwp.ini
COPY ./plugins /var/www/html/wp-content/plugins
COPY ./themes /var/www/html/wp-content/themes
EOF

echo "==> Pushing $IMAGE..."
docker push "$IMAGE"

echo "Done: https://hub.docker.com/r/${DOCKER_USER}/dvwp/tags"