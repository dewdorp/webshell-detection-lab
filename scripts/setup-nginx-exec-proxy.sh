#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN:-${LAB_DOMAIN:-secutrace.co.kr}}"
NGINX_AVAILABLE="${NGINX_AVAILABLE:-/etc/nginx/sites-available/webshell-detection-lab}"
NGINX_SNIPPET_DIR="${NGINX_SNIPPET_DIR:-/etc/nginx/snippets}"
NGINX_EXEC_SNIPPET="$NGINX_SNIPPET_DIR/webshell-lab-exec-proxy.conf"
NGINX_EXEC_SNIPPET_INCLUDE="$NGINX_SNIPPET_DIR/webshell-lab-exec-proxy*.conf"
LAB_EXEC_HANDLER_PORT="${LAB_EXEC_HANDLER_PORT:-18080}"
LAB_EXEC_PROXY_PREFIX="${LAB_EXEC_PROXY_PREFIX:-/exec/}"
LAB_JSP_EXEC_PROXY_PREFIX="${LAB_JSP_EXEC_PROXY_PREFIX:-/jsp-exec/}"
LAB_TOMCAT_UPSTREAM_HOST="${LAB_TOMCAT_UPSTREAM_HOST:-127.0.0.1}"
LAB_TOMCAT_UPSTREAM_PORT="${LAB_TOMCAT_UPSTREAM_PORT:-8080}"
LAB_TOMCAT_CONTEXT_NAME="${LAB_TOMCAT_CONTEXT_NAME:-webshell-lab-jsp}"

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo DOMAIN=$DOMAIN $0" >&2
    exit 1
  fi
}

need_command() {
  local command_name="$1"
  local help_text="$2"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n%s\n' "$command_name" "$help_text" >&2
    exit 1
  fi
}

normalize_prefix() {
  local prefix="$1"
  case "$prefix" in
    /*) ;;
    *) prefix="/$prefix" ;;
  esac
  case "$prefix" in
    */) ;;
    *) prefix="$prefix/" ;;
  esac
  printf '%s' "$prefix"
}

write_proxy_snippet() {
  LAB_EXEC_PROXY_PREFIX="$(normalize_prefix "$LAB_EXEC_PROXY_PREFIX")"
  LAB_JSP_EXEC_PROXY_PREFIX="$(normalize_prefix "$LAB_JSP_EXEC_PROXY_PREFIX")"

  mkdir -p "$NGINX_SNIPPET_DIR"
  cat > "$NGINX_EXEC_SNIPPET" <<CONF
location ^~ $LAB_EXEC_PROXY_PREFIX {
    proxy_pass http://127.0.0.1:$LAB_EXEC_HANDLER_PORT/uploads/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
}

location ^~ $LAB_JSP_EXEC_PROXY_PREFIX {
    proxy_pass http://$LAB_TOMCAT_UPSTREAM_HOST:$LAB_TOMCAT_UPSTREAM_PORT/$LAB_TOMCAT_CONTEXT_NAME/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
}
CONF
}

ensure_nginx_include() {
  if [ ! -f "$NGINX_AVAILABLE" ]; then
    cat >&2 <<MSG
Nginx site config was not found: $NGINX_AVAILABLE
Run SSL setup first, for example:
  sudo DOMAIN=$DOMAIN ADMIN_EMAIL=you@example.com ./scripts/setup-nginx-ssl.sh
MSG
    exit 1
  fi

  python3 - "$NGINX_AVAILABLE" "$DOMAIN" "$NGINX_EXEC_SNIPPET_INCLUDE" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
domain = sys.argv[2]
include_path = sys.argv[3]
include_line = f"    include {include_path};\n"
text = path.read_text()
lines = text.splitlines(keepends=True)

out = []
changed = False
matched = False
i = 0
while i < len(lines):
    line = lines[i]
    if line.lstrip().startswith("server") and "{" in line:
        block = [line]
        depth = line.count("{") - line.count("}")
        i += 1
        while i < len(lines) and depth > 0:
            block.append(lines[i])
            depth += lines[i].count("{") - lines[i].count("}")
            i += 1

        block_text = "".join(block)
        if f"server_name {domain}" in block_text:
            matched = True
            if include_path not in block_text:
                insert_at = None
                for index, block_line in enumerate(block):
                    if "client_max_body_size" in block_line:
                        insert_at = index + 1
                        break
                if insert_at is None:
                    for index, block_line in enumerate(block):
                        if "server_name" in block_line:
                            insert_at = index + 1
                            break
                if insert_at is None:
                    insert_at = 1
                block.insert(insert_at, include_line)
                changed = True
        out.extend(block)
        continue

    out.append(line)
    i += 1

if not matched:
    raise SystemExit(f"No server block with server_name {domain} was found in {path}")

if changed:
    path.write_text("".join(out))
PY
}

need_root
need_command nginx "Install nginx first."
need_command python3 "Install python3 first."
write_proxy_snippet
ensure_nginx_include
nginx -t
systemctl reload nginx || systemctl restart nginx

cat <<MSG

Nginx HTTPS execution proxy is configured for:
  https://$DOMAIN$LAB_EXEC_PROXY_PREFIX<file>.php
  https://$DOMAIN$LAB_EXEC_PROXY_PREFIX<file>.js
  https://$DOMAIN$LAB_EXEC_PROXY_PREFIX<file>.py
  https://$DOMAIN$LAB_JSP_EXEC_PROXY_PREFIX<file>.jsp

Keep Apache execution handlers bound to loopback with:
  LAB_EXEC_HANDLER_HOST=127.0.0.1
MSG
