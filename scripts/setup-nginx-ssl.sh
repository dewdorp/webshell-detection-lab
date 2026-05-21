#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN:-secutrace.co.kr}"
LAB_UPSTREAM_HOST="${LAB_UPSTREAM_HOST:-127.0.0.1}"
LAB_UPSTREAM_PORT="${LAB_UPSTREAM_PORT:-8080}"
ADMIN_EMAIL="${ADMIN_EMAIL:-}"
NGINX_AVAILABLE="/etc/nginx/sites-available/webshell-detection-lab"
NGINX_ENABLED="/etc/nginx/sites-enabled/webshell-detection-lab"

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo DOMAIN=$DOMAIN ADMIN_EMAIL=you@example.com $0"
    exit 1
  fi
}

install_packages() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y nginx certbot python3-certbot-nginx
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y nginx certbot python3-certbot-nginx
  elif command -v yum >/dev/null 2>&1; then
    yum install -y nginx certbot python3-certbot-nginx
  else
    echo "Install nginx, certbot, and the certbot nginx plugin manually for this distribution."
  fi
}

write_nginx_config() {
  cat > "$NGINX_AVAILABLE" <<CONF
server {
    listen 80;
    server_name $DOMAIN;

    client_max_body_size 100m;

    location / {
        proxy_pass http://$LAB_UPSTREAM_HOST:$LAB_UPSTREAM_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
CONF

  ln -sfn "$NGINX_AVAILABLE" "$NGINX_ENABLED"
  nginx -t
  systemctl enable nginx
  systemctl reload nginx || systemctl restart nginx
}

issue_certificate() {
  if [ -n "$ADMIN_EMAIL" ]; then
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$ADMIN_EMAIL" --redirect
  else
    certbot --nginx -d "$DOMAIN" --register-unsafely-without-email --non-interactive --agree-tos --redirect
  fi
}

need_root
install_packages
write_nginx_config
issue_certificate

cat <<MSG

Nginx and SSL are configured for:
  https://$DOMAIN/

Start the lab server behind Nginx with:
  LAB_HOST=$LAB_UPSTREAM_HOST LAB_PORT=$LAB_UPSTREAM_PORT ./scripts/switch-server.sh node

Recommended firewall:
  allow TCP 80 from the internet for ACME HTTP-01 validation and HTTP redirect
  allow TCP 443 only from trusted test IP ranges if the lab is not public
  keep TCP $LAB_UPSTREAM_PORT closed externally
MSG
