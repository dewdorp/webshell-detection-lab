#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME="${1:-}"
LAB_PORT="${LAB_PORT:-8080}"
LAB_HOST="${LAB_HOST:-0.0.0.0}"
PID_DIR="$ROOT_DIR/runtime/pids"
ACTIVE_FILE="$ROOT_DIR/runtime/active-server.json"
CURRENT_LINK="$ROOT_DIR/runtime/current"
UPLOAD_PERMISSIONS_SCRIPT="$ROOT_DIR/scripts/upload-permissions.sh"
UPLOAD_EXEC_HANDLER_SCRIPT="$ROOT_DIR/scripts/setup-upload-exec-handler.sh"
NGINX_UPSTREAM_SCRIPT="$ROOT_DIR/scripts/update-nginx-lab-upstream.sh"

truthy() {
  case "${1:-0}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

upload_exec_handler_enabled() {
  truthy "${LAB_AUTO_EXEC_HANDLER:-0}"
}

nginx_upstream_update_enabled() {
  if [ -n "${LAB_AUTO_NGINX_UPSTREAM+x}" ]; then
    truthy "$LAB_AUTO_NGINX_UPSTREAM"
  else
    return 0
  fi
}

if upload_exec_handler_enabled && [ -z "${LAB_UPLOAD_EXECUTABLE+x}" ]; then
  export LAB_UPLOAD_EXECUTABLE=1
fi

usage() { printf 'Usage: %s node|php|jsp|aspnet\n' "$0"; }

require_command() {
  local command_name="$1"
  local help_text="$2"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n%s\n' "$command_name" "$help_text" >&2
    exit 1
  fi
}

prepare_upload_dir() {
  local upload_dir="$1"
  bash "$UPLOAD_PERMISSIONS_SCRIPT" prepare-dir "$upload_dir"
}

maybe_setup_upload_exec_handler() {
  local runtime="$1"
  if upload_exec_handler_enabled; then
    bash "$UPLOAD_EXEC_HANDLER_SCRIPT" "$runtime"
  fi
}

nginx_upstream_host() {
  if [ -n "${LAB_NGINX_UPSTREAM_HOST:-}" ]; then
    printf '%s\n' "$LAB_NGINX_UPSTREAM_HOST"
  elif [ "$LAB_HOST" = "0.0.0.0" ] || [ "$LAB_HOST" = "::" ]; then
    printf '127.0.0.1\n'
  else
    printf '%s\n' "$LAB_HOST"
  fi
}

maybe_update_nginx_upstream() {
  if ! nginx_upstream_update_enabled; then
    return
  fi
  if [ ! -x "$NGINX_UPSTREAM_SCRIPT" ]; then
    return
  fi

  local upstream_host
  upstream_host="$(nginx_upstream_host)"

  if [ "$(id -u)" -eq 0 ]; then
    LAB_UPSTREAM_HOST="$upstream_host" LAB_UPSTREAM_PORT="$LAB_PORT" bash "$NGINX_UPSTREAM_SCRIPT"
  elif command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    sudo env LAB_UPSTREAM_HOST="$upstream_host" LAB_UPSTREAM_PORT="$LAB_PORT" bash "$NGINX_UPSTREAM_SCRIPT"
  else
    printf 'Nginx root upstream was not updated because root/sudo is unavailable.\n' >&2
    printf 'Run: sudo LAB_UPSTREAM_HOST=%s LAB_UPSTREAM_PORT=%s %s\n' "$upstream_host" "$LAB_PORT" "$NGINX_UPSTREAM_SCRIPT" >&2
  fi
}

write_active_file() {
  local runtime="$1" pid="$2" server_dir="$3" upload_dir="$4" started_at
  started_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  cat > "$ACTIVE_FILE" <<JSON
{
  "runtime": "$runtime",
  "pid": $pid,
  "host": "$LAB_HOST",
  "port": $LAB_PORT,
  "serverDir": "$server_dir",
  "uploadPath": "$upload_dir",
  "uploadExecutable": "${LAB_UPLOAD_EXECUTABLE:-0}",
  "uploadExecHandler": "${LAB_AUTO_EXEC_HANDLER:-0}",
  "startedAt": "$started_at"
}
JSON
}

start_server() {
  local runtime="$1"
  local server_dir="$2"
  shift 2
  local upload_dir="$server_dir/uploads"
  local log_dir="$server_dir/logs"
  local pid_file="$PID_DIR/$runtime.pid"
  mkdir -p "$PID_DIR" "$upload_dir" "$log_dir"
  prepare_upload_dir "$upload_dir"
  maybe_setup_upload_exec_handler "$runtime"
  (cd "$server_dir" && "$@" > "$log_dir/server.out.log" 2> "$log_dir/server.err.log" & echo $! > "$pid_file")
  local pid
  pid="$(cat "$pid_file")"
  sleep 1
  if ! kill -0 "$pid" >/dev/null 2>&1; then
    printf 'Failed to start %s. Check %s/server.err.log\n' "$runtime" "$log_dir" >&2
    exit 1
  fi
  rm -f "$CURRENT_LINK"
  ln -s "$server_dir" "$CURRENT_LINK" 2>/dev/null || true
  write_active_file "$runtime" "$pid" "$server_dir" "$upload_dir"
  maybe_update_nginx_upstream
  printf '%s server started on http://%s:%s with PID %s\n' "$runtime" "$LAB_HOST" "$LAB_PORT" "$pid"
  printf 'External URL example: http://secutrace.co.kr:%s\n' "$LAB_PORT"
  printf 'Agent watch path: %s\n' "$upload_dir"
  if [ "${LAB_UPLOAD_EXECUTABLE:-0}" != "0" ]; then printf 'Executable upload permissions: enabled via LAB_UPLOAD_EXECUTABLE=%s\n' "${LAB_UPLOAD_EXECUTABLE:-0}"; fi
  if upload_exec_handler_enabled; then printf 'Automatic upload execution handler: enabled via LAB_AUTO_EXEC_HANDLER=%s\n' "${LAB_AUTO_EXEC_HANDLER:-0}"; fi
  if nginx_upstream_update_enabled; then printf 'Automatic Nginx root upstream: enabled for http://%s:%s\n' "$(nginx_upstream_host)" "$LAB_PORT"; fi
  if [ -L "$CURRENT_LINK" ]; then printf 'Stable symlink path: %s/uploads\n' "$CURRENT_LINK"; fi
}

if [ -z "$RUNTIME" ]; then usage; exit 1; fi
mkdir -p "$PID_DIR"
"$ROOT_DIR/scripts/stop-server.sh" >/dev/null 2>&1 || true

case "$RUNTIME" in
  node)
    require_command node "Install Node.js, then run npm install inside servers/node-express."
    require_command npm "Install npm, then run npm install inside servers/node-express."
    if [ ! -d "$ROOT_DIR/servers/node-express/node_modules" ]; then
      printf 'Installing Node dependencies...\n'
      (cd "$ROOT_DIR/servers/node-express" && npm install)
    fi
    start_server "node" "$ROOT_DIR/servers/node-express" node server.js
    ;;
  php)
    require_command php "Install PHP or configure Apache/PHP separately."
    start_server "php" "$ROOT_DIR/servers/php-apache" php -S "$LAB_HOST:$LAB_PORT" index.php
    ;;
  jsp)
    require_command java "Install a Java runtime."
    require_command mvn "Install Maven."
    start_server "jsp" "$ROOT_DIR/servers/jsp-tomcat" mvn -q compile exec:java -Dexec.mainClass=lab.EmbeddedTomcatServer -Dlab.port="$LAB_PORT" -Dlab.host="$LAB_HOST"
    ;;
  aspnet)
    require_command dotnet "Install the .NET SDK."
    start_server "aspnet" "$ROOT_DIR/servers/aspnet-core" dotnet run --urls "http://$LAB_HOST:$LAB_PORT"
    ;;
  *) usage; exit 1 ;;
esac
