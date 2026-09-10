#!/usr/bin/env bash
set -euo pipefail

# Pulls Apache access.log and error.log out of the running WordPress
# container into ./logs/.
#
#   bin/pull-logs.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! docker-compose ps --services 2>/dev/null | grep -q '^wordpress$'; then
  echo "ERROR: stack not running. Start it first with: docker-compose up -d" >&2
  exit 1
fi

CONTAINER="$(docker-compose ps -q wordpress | head -n1)"
[ -n "$CONTAINER" ] || { echo "ERROR: wordpress container not found." >&2; exit 1; }

mkdir -p logs

for log in access error; do
  if docker cp "$CONTAINER:/var/log/apache2/$log.log" "logs/$log.log" 2>/dev/null; then
    echo "Saved logs/$log.log"
  else
    echo "WARNING: no $log.log found in container (file may not have been created yet)." >&2
    : > "logs/$log.log"
  fi
done

echo "Logs: $ROOT/logs/"