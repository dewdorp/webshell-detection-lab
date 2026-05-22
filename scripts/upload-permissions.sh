#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: LAB_UPLOAD_EXECUTABLE=1 %s prepare-dir|prepare-file <path>\n' "$0" >&2
}

upload_exec_enabled() {
  case "${LAB_UPLOAD_EXECUTABLE:-0}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

prepare_dir() {
  local target="$1"
  mkdir -p "$target"
  if upload_exec_enabled; then
    chmod 0775 "$target"
  fi
}

prepare_file() {
  local target="$1"
  if [ ! -f "$target" ]; then
    printf 'Upload file does not exist: %s\n' "$target" >&2
    exit 1
  fi

  if upload_exec_enabled; then
    chmod 0775 "$target"
  fi
}

command="${1:-}"
target="${2:-}"

if [ -z "$command" ] || [ -z "$target" ]; then
  usage
  exit 2
fi

case "$command" in
  prepare-dir) prepare_dir "$target" ;;
  prepare-file) prepare_file "$target" ;;
  *) usage; exit 2 ;;
esac
