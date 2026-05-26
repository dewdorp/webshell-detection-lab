#!/usr/bin/env bash
set -euo pipefail

LAB_UPSTREAM_HOST="${LAB_UPSTREAM_HOST:-127.0.0.1}"
LAB_UPSTREAM_PORT="${LAB_UPSTREAM_PORT:-8080}"
NGINX_AVAILABLE="${LAB_NGINX_SITE:-/etc/nginx/sites-available/webshell-detection-lab}"
NGINX_ENABLED="${LAB_NGINX_ENABLED_SITE:-/etc/nginx/sites-enabled/webshell-detection-lab}"
SNIPPET_PATH="${LAB_UPLOAD_UI_SNIPPET:-/etc/nginx/snippets/webshell-lab-upload-ui.conf}"
INCLUDE_LINE="    include $SNIPPET_PATH;"

if [ "$LAB_UPSTREAM_HOST" = "0.0.0.0" ] || [ "$LAB_UPSTREAM_HOST" = "::" ]; then
  LAB_UPSTREAM_HOST="127.0.0.1"
fi

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    printf 'Nginx upload UI proxy update needs root. Run switch-server.sh with sudo or set LAB_AUTO_NGINX_UPSTREAM=0.\n' >&2
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

write_snippet() {
  mkdir -p "$(dirname "$SNIPPET_PATH")"
  cat > "$SNIPPET_PATH" <<CONF
# Managed by webshell-detection-lab. Routes only the lab upload UI to the active runtime.
location = /upload.html {
    return 302 /lab-upload/upload.html;
}

location = /upload {
    return 302 /lab-upload/upload.html;
}

location ^~ /lab-upload/ {
    proxy_pass http://$LAB_UPSTREAM_HOST:$LAB_UPSTREAM_PORT/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
CONF
}

ensure_include() {
  local tmp backup
  tmp="$(mktemp)"
  backup="$NGINX_AVAILABLE.bak.$(date -u +%Y%m%dT%H%M%SZ)"

  if grep -Fq "$SNIPPET_PATH" "$NGINX_AVAILABLE"; then
    return
  fi

  awk -v include_line="$INCLUDE_LINE" '
    !inserted && /^[[:space:]]*location[[:space:]]+/ {
      print include_line
      inserted = 1
    }
    { print }
    END { if (!inserted) exit 2 }
  ' "$NGINX_AVAILABLE" > "$tmp" || {
    local status=$?
    rm -f "$tmp"
    if [ "$status" -eq 2 ]; then
      printf 'Could not find a location block in %s to place the lab upload UI include.\n' "$NGINX_AVAILABLE" >&2
      exit 1
    fi
    exit "$status"
  }

  cp "$NGINX_AVAILABLE" "$backup"
  mv "$tmp" "$NGINX_AVAILABLE"
  printf 'Nginx site backup written to %s\n' "$backup"
}

need_root

if [ ! -f "$NGINX_AVAILABLE" ]; then
  printf 'Nginx site config not found at %s; skipping lab upload UI proxy update.\n' "$NGINX_AVAILABLE"
  exit 0
fi

write_snippet
ensure_include
if [ ! -e "$NGINX_ENABLED" ]; then
  ln -sfn "$NGINX_AVAILABLE" "$NGINX_ENABLED"
fi
reload_nginx
printf 'Nginx lab upload UI proxy updated at /lab-upload/ -> http://%s:%s\n' "$LAB_UPSTREAM_HOST" "$LAB_UPSTREAM_PORT"
printf 'Existing site root location is preserved.\n'
