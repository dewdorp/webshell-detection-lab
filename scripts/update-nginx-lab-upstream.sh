#!/usr/bin/env bash
set -euo pipefail

LAB_UPSTREAM_HOST="${LAB_UPSTREAM_HOST:-127.0.0.1}"
LAB_UPSTREAM_PORT="${LAB_UPSTREAM_PORT:-8080}"
NGINX_AVAILABLE="${LAB_NGINX_SITE:-/etc/nginx/sites-available/webshell-detection-lab}"
NGINX_ENABLED="${LAB_NGINX_ENABLED_SITE:-/etc/nginx/sites-enabled/webshell-detection-lab}"
OLD_UPLOAD_UI_SNIPPET="${LAB_UPLOAD_UI_SNIPPET:-/etc/nginx/snippets/webshell-lab-upload-ui.conf}"

if [ "$LAB_UPSTREAM_HOST" = "0.0.0.0" ] || [ "$LAB_UPSTREAM_HOST" = "::" ]; then
  LAB_UPSTREAM_HOST="127.0.0.1"
fi

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    printf 'Nginx root upstream update needs root. Run switch-server.sh with sudo or set LAB_AUTO_NGINX_UPSTREAM=0.\n' >&2
    exit 1
  fi
}

reload_nginx() {
  nginx -t
  if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files nginx.service >/dev/null 2>&1; then
    systemctl reload nginx || systemctl restart nginx
  elif command -v service >/dev/null 2>&1; then
    service nginx reload || service nginx restart
  else
    nginx -s reload
  fi
}

update_site() {
  local target="proxy_pass http://$LAB_UPSTREAM_HOST:$LAB_UPSTREAM_PORT;"
  local tmp backup
  tmp="$(mktemp)"
  backup="$NGINX_AVAILABLE.bak.$(date -u +%Y%m%dT%H%M%SZ)"

  awk -v target="$target" -v old_snippet="$OLD_UPLOAD_UI_SNIPPET" '
    index($0, old_snippet) { changed++; next }
    /^[[:space:]]*location[[:space:]]+\/[[:space:]]*\{/ { in_root = 1 }
    in_root && /^[[:space:]]*proxy_pass[[:space:]]+http:\/\/[^;]+;[[:space:]]*$/ {
      sub(/proxy_pass[[:space:]]+http:\/\/[^;]+;/, target)
      changed++
    }
    { print }
    in_root && /^[[:space:]]*\}/ { in_root = 0 }
    END { if (changed == 0) exit 2 }
  ' "$NGINX_AVAILABLE" > "$tmp" || {
    local status=$?
    rm -f "$tmp"
    if [ "$status" -eq 2 ]; then
      printf 'Could not find a root location proxy_pass in %s\n' "$NGINX_AVAILABLE" >&2
      exit 1
    fi
    exit "$status"
  }

  if cmp -s "$NGINX_AVAILABLE" "$tmp"; then
    rm -f "$tmp"
    printf 'Nginx root upstream is already http://%s:%s\n' "$LAB_UPSTREAM_HOST" "$LAB_UPSTREAM_PORT"
  else
    cp "$NGINX_AVAILABLE" "$backup"
    mv "$tmp" "$NGINX_AVAILABLE"
    printf 'Nginx site backup written to %s\n' "$backup"
  fi

  rm -f "$OLD_UPLOAD_UI_SNIPPET"
  if [ ! -e "$NGINX_ENABLED" ]; then
    ln -sfn "$NGINX_AVAILABLE" "$NGINX_ENABLED"
  fi
  reload_nginx
  printf 'Nginx root upstream updated to http://%s:%s\n' "$LAB_UPSTREAM_HOST" "$LAB_UPSTREAM_PORT"
  printf 'Removed legacy /lab-upload/ snippet if present.\n'
}

need_root

if [ ! -f "$NGINX_AVAILABLE" ]; then
  printf 'Nginx site config not found at %s; skipping root upstream update.\n' "$NGINX_AVAILABLE"
  exit 0
fi

update_site
