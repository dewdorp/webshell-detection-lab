#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check_command() {
  local label="$1"
  local command_name="$2"
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '[ok] %s: %s\n' "$label" "$(command -v "$command_name")"
  else
    printf '[missing] %s: install %s\n' "$label" "$command_name"
  fi
}

printf 'Checking prerequisites for %s\n\n' "$ROOT_DIR"
check_command "Node.js runtime" "node"
check_command "npm package manager" "npm"
check_command "PHP runtime" "php"
check_command "Java runtime" "java"
check_command "Maven build tool" "mvn"
check_command ".NET CLI" "dotnet"

printf '\nRun one of:\n'
printf '  ./scripts/switch-server.sh node\n'
printf '  ./scripts/switch-server.sh php\n'
printf '  ./scripts/switch-server.sh jsp\n'
printf '  ./scripts/switch-server.sh aspnet\n'
