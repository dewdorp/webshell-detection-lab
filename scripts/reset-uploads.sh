#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT_DIR/scripts/stop-server.sh" >/dev/null 2>&1 || true

for runtime_dir in \
  "$ROOT_DIR/servers/node-express" \
  "$ROOT_DIR/servers/php-apache" \
  "$ROOT_DIR/servers/jsp-tomcat" \
  "$ROOT_DIR/servers/aspnet-core"; do
  mkdir -p "$runtime_dir/uploads" "$runtime_dir/logs"
  find "$runtime_dir/uploads" -mindepth 1 -maxdepth 1 -type f -delete
  find "$runtime_dir/logs" -mindepth 1 -maxdepth 1 -type f -delete
done

rm -f "$ROOT_DIR/runtime/active-server.json" "$ROOT_DIR/runtime/current"
mkdir -p "$ROOT_DIR/runtime/pids"
find "$ROOT_DIR/runtime/pids" -mindepth 1 -maxdepth 1 -type f -delete

printf 'Uploads, logs, and runtime state reset.\n'
