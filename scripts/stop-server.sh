#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_PORT="${LAB_PORT:-8080}"
PID_DIR="$ROOT_DIR/runtime/pids"
ACTIVE_FILE="$ROOT_DIR/runtime/active-server.json"

mkdir -p "$PID_DIR"

stopped=0

stop_pid() {
  local name="$1"
  local pid="$2"

  if [ -z "$pid" ] || ! kill -0 "$pid" >/dev/null 2>&1; then
    return
  fi

  printf 'Stopping %s with PID %s\n' "$name" "$pid"
  kill "$pid" >/dev/null 2>&1 || true
  sleep 1
  if kill -0 "$pid" >/dev/null 2>&1; then
    printf 'Force stopping %s with PID %s\n' "$name" "$pid"
    kill -9 "$pid" >/dev/null 2>&1 || true
  fi
  stopped=1
}

port_pids() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -tiTCP:"$LAB_PORT" -sTCP:LISTEN 2>/dev/null || true
    return
  fi

  if command -v fuser >/dev/null 2>&1; then
    fuser "$LAB_PORT"/tcp 2>/dev/null || true
    return
  fi

  if command -v ss >/dev/null 2>&1; then
    ss -ltnp "sport = :$LAB_PORT" 2>/dev/null |
      sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' || true
  fi
}

for pid_file in "$PID_DIR"/*.pid; do
  [ -e "$pid_file" ] || continue
  pid="$(cat "$pid_file")"
  name="$(basename "$pid_file" .pid)"

  stop_pid "$name server" "$pid"
  rm -f "$pid_file"
done

for pid in $(port_pids | tr ' ' '\n' | sort -u); do
  stop_pid "process listening on port $LAB_PORT" "$pid"
done

rm -f "$ACTIVE_FILE"

if [ "$stopped" -eq 0 ]; then
  printf 'No active lab server was recorded or listening on port %s.\n' "$LAB_PORT"
fi
