#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_DIR="$ROOT_DIR/runtime/pids"
ACTIVE_FILE="$ROOT_DIR/runtime/active-server.json"

mkdir -p "$PID_DIR"
stopped=0

for pid_file in "$PID_DIR"/*.pid; do
  [ -e "$pid_file" ] || continue
  pid="$(cat "$pid_file")"
  name="$(basename "$pid_file" .pid)"
  if [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1; then
    printf 'Stopping %s server with PID %s\n' "$name" "$pid"
    kill "$pid" >/dev/null 2>&1 || true
    sleep 1
    if kill -0 "$pid" >/dev/null 2>&1; then
      printf 'Force stopping %s server with PID %s\n' "$name" "$pid"
      kill -9 "$pid" >/dev/null 2>&1 || true
    fi
    stopped=1
  fi
  rm -f "$pid_file"
done

rm -f "$ACTIVE_FILE"

if [ "$stopped" -eq 0 ]; then
  printf 'No active lab server was recorded.\n'
fi
