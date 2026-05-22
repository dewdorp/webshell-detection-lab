#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME="${1:-}"
LAB_DOMAIN="${LAB_DOMAIN:-${DOMAIN:-secutrace.co.kr}}"
LAB_EXEC_HANDLER_PORT="${LAB_EXEC_HANDLER_PORT:-18080}"
APACHE_SITE_DIR="${APACHE_SITE_DIR:-/etc/apache2/sites-available}"
APACHE_ENABLED_DIR="${APACHE_ENABLED_DIR:-/etc/apache2/sites-enabled}"
TOMCAT_CONTEXT_NAME="${LAB_TOMCAT_CONTEXT_NAME:-webshell-lab-jsp}"
TOMCAT_CONTEXT_FILE="${LAB_TOMCAT_CONTEXT_FILE:-}"
TOMCAT_SERVICE="${LAB_TOMCAT_SERVICE:-}"

usage() {
  printf 'Usage: LAB_AUTO_EXEC_HANDLER=1 %s php|node|jsp|aspnet\n' "$0" >&2
}

auto_exec_enabled() {
  case "${LAB_AUTO_EXEC_HANDLER:-0}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

write_root_file() {
  local target="$1"
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  as_root mkdir -p "$(dirname "$target")"
  as_root install -m 0644 "$tmp" "$target"
  rm -f "$tmp"
}

need_command() {
  local command_name="$1"
  local help_text="$2"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n%s\n' "$command_name" "$help_text" >&2
    exit 1
  fi
}

apache_available() {
  command -v a2ensite >/dev/null 2>&1 && command -v apache2ctl >/dev/null 2>&1
}

need_apache() {
  if ! apache_available; then
    cat >&2 <<MSG
Apache tooling was not found. Install Apache first, for example:
  sudo apt update
  sudo apt install -y apache2
MSG
    exit 1
  fi
}

disable_apache_exec_sites() {
  if ! apache_available; then
    return
  fi

  for site in webshell-lab-exec-php webshell-lab-exec-node webshell-lab-exec-python; do
    if [ -e "$APACHE_ENABLED_DIR/$site.conf" ] || [ -e "$APACHE_SITE_DIR/$site.conf" ]; then
      as_root a2dissite "$site.conf" >/dev/null 2>&1 || true
    fi
  done
}

reload_apache() {
  as_root apache2ctl configtest
  if command -v systemctl >/dev/null 2>&1; then
    as_root systemctl reload apache2 || as_root systemctl restart apache2
  else
    as_root service apache2 reload || as_root service apache2 restart
  fi
}

write_apache_site() {
  local site="$1"
  local document_root="$2"
  local upload_dir="$3"
  local handler_block="$4"

  write_root_file "$APACHE_SITE_DIR/$site.conf" <<CONF
Listen $LAB_EXEC_HANDLER_PORT

<VirtualHost *:$LAB_EXEC_HANDLER_PORT>
    ServerName $LAB_DOMAIN
    DocumentRoot $document_root

    <Directory $document_root>
        Require all granted
        AllowOverride None
        Options -Indexes +FollowSymLinks
        DirectoryIndex index.php index.html
        FallbackResource /index.php
    </Directory>

    <Directory $upload_dir>
        Require all granted
$handler_block
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$site-error.log
    CustomLog \${APACHE_LOG_DIR}/$site-access.log combined
</VirtualHost>
CONF
}

configure_php() {
  need_apache
  disable_tomcat_exec_context
  disable_apache_exec_sites

  local document_root="$ROOT_DIR/servers/php-apache"
  local upload_dir="$document_root/uploads"
  local handler_block='        Options -Indexes +FollowSymLinks

        <FilesMatch "\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>'

  write_apache_site "webshell-lab-exec-php" "$document_root" "$upload_dir" "$handler_block"
  as_root a2ensite webshell-lab-exec-php.conf >/dev/null
  reload_apache

  printf 'PHP upload execution handler enabled at http://%s:%s/uploads/<file>.php\n' "$LAB_DOMAIN" "$LAB_EXEC_HANDLER_PORT"
}

configure_node() {
  need_apache
  disable_tomcat_exec_context
  disable_apache_exec_sites
  as_root a2enmod cgi >/dev/null

  local document_root="$ROOT_DIR/servers/node-express"
  local upload_dir="$document_root/uploads"
  local handler_block='        Options +ExecCGI -Indexes +FollowSymLinks
        AddHandler cgi-script .js .py'

  write_apache_site "webshell-lab-exec-node" "$document_root" "$upload_dir" "$handler_block"
  as_root a2ensite webshell-lab-exec-node.conf >/dev/null
  reload_apache

  printf 'Node/Python CGI upload execution handler enabled at http://%s:%s/uploads/<file>.js or .py\n' "$LAB_DOMAIN" "$LAB_EXEC_HANDLER_PORT"
}

configure_python() {
  need_apache
  disable_tomcat_exec_context
  disable_apache_exec_sites
  as_root a2enmod cgi >/dev/null

  local document_root="$ROOT_DIR/servers/node-express"
  local upload_dir="$document_root/uploads"
  local handler_block='        Options +ExecCGI -Indexes +FollowSymLinks
        AddHandler cgi-script .py'

  write_apache_site "webshell-lab-exec-python" "$document_root" "$upload_dir" "$handler_block"
  as_root a2ensite webshell-lab-exec-python.conf >/dev/null
  reload_apache

  printf 'Python CGI upload execution handler enabled at http://%s:%s/uploads/<file>.py\n' "$LAB_DOMAIN" "$LAB_EXEC_HANDLER_PORT"
}

find_tomcat_context_file() {
  if [ -n "$TOMCAT_CONTEXT_FILE" ]; then
    printf '%s\n' "$TOMCAT_CONTEXT_FILE"
    return
  fi

  for base in /etc/tomcat9 /etc/tomcat10 /var/lib/tomcat9/conf /var/lib/tomcat10/conf; do
    if [ -d "$base" ]; then
      printf '%s/Catalina/localhost/%s.xml\n' "$base" "$TOMCAT_CONTEXT_NAME"
      return
    fi
  done

  printf '/etc/tomcat9/Catalina/localhost/%s.xml\n' "$TOMCAT_CONTEXT_NAME"
}

find_tomcat_service() {
  if [ -n "$TOMCAT_SERVICE" ]; then
    printf '%s\n' "$TOMCAT_SERVICE"
    return
  fi

  for service in tomcat9 tomcat10 tomcat; do
    if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files "$service.service" >/dev/null 2>&1; then
      printf '%s\n' "$service"
      return
    fi
  done

  printf 'tomcat9\n'
}

disable_tomcat_exec_context() {
  local context_file
  context_file="$(find_tomcat_context_file)"
  if [ -e "$context_file" ]; then
    as_root rm -f "$context_file"
    if command -v systemctl >/dev/null 2>&1; then
      as_root systemctl reload "$(find_tomcat_service)" >/dev/null 2>&1 || true
    fi
  fi
}

reload_tomcat() {
  local service
  service="$(find_tomcat_service)"
  if command -v systemctl >/dev/null 2>&1; then
    as_root systemctl reload "$service" || as_root systemctl restart "$service"
  else
    as_root service "$service" reload || as_root service "$service" restart
  fi
}

configure_jsp() {
  disable_apache_exec_sites

  local upload_dir="$ROOT_DIR/servers/jsp-tomcat/uploads"
  local context_file
  context_file="$(find_tomcat_context_file)"

  if ! command -v systemctl >/dev/null 2>&1 && ! command -v service >/dev/null 2>&1; then
    printf 'No service manager was found for Tomcat reload/restart. Install and start Tomcat manually.\n' >&2
    exit 1
  fi

  write_root_file "$context_file" <<CONF
<Context docBase="$upload_dir" reloadable="true" />
CONF
  reload_tomcat

  printf 'JSP upload execution handler enabled at the Tomcat context /%s/<file>.jsp\n' "$TOMCAT_CONTEXT_NAME"
}

configure_aspnet() {
  disable_apache_exec_sites
  disable_tomcat_exec_context
  cat <<MSG
ASP.NET Core on Linux does not execute uploaded .cs, .cshtml, .asp, or .aspx files as scripts.
The Linux aspnet runtime remains available for upload storage and detection tests only.
Use a separate Windows IIS lab for classic ASP or ASP.NET WebForms upload execution.
MSG
}

if [ -z "$RUNTIME" ]; then
  usage
  exit 2
fi

if ! auto_exec_enabled; then
  printf 'Automatic upload execution handler setup is disabled. Set LAB_AUTO_EXEC_HANDLER=1 to enable it.\n'
  exit 0
fi

case "$RUNTIME" in
  php) configure_php ;;
  node) configure_node ;;
  python) configure_python ;;
  jsp) configure_jsp ;;
  aspnet) configure_aspnet ;;
  *) usage; exit 2 ;;
esac
