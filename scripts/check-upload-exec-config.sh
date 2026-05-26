#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

fail() {
  printf '[fail] %s\n' "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  local file="$1"
  if [ ! -f "$ROOT_DIR/$file" ]; then
    fail "$file is missing"
  fi
}

require_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! grep -Fq "$pattern" "$ROOT_DIR/$file" 2>/dev/null; then
    fail "$file does not include $label"
  fi
}

require_file "scripts/upload-permissions.sh"
require_contains "scripts/upload-permissions.sh" "LAB_UPLOAD_EXECUTABLE" "the executable upload toggle"
require_contains "scripts/upload-permissions.sh" "chmod 0775" "0775 permission application"

require_file "scripts/setup-upload-exec-handler.sh"
require_contains "scripts/setup-upload-exec-handler.sh" "LAB_AUTO_EXEC_HANDLER" "the automatic handler toggle"
require_contains "scripts/setup-upload-exec-handler.sh" "LAB_EXEC_HANDLER_HOST" "loopback execution handler bind host"
require_contains "scripts/setup-upload-exec-handler.sh" "configure_php" "PHP handler setup"
require_contains "scripts/setup-upload-exec-handler.sh" "configure_node" "Node CGI handler setup"
require_contains "scripts/setup-upload-exec-handler.sh" "configure_jsp" "JSP Tomcat handler setup"
require_contains "scripts/setup-upload-exec-handler.sh" "FallbackResource /index.php" "PHP fallback support"
require_contains "scripts/setup-upload-exec-handler.sh" 'write_apache_site "webshell-lab-exec-node" "$document_root" "$upload_dir" "$handler_block" ""' "Node CGI fallback disabled"
require_contains "scripts/setup-upload-exec-handler.sh" 'write_apache_site "webshell-lab-exec-python" "$document_root" "$upload_dir" "$handler_block" ""' "Python CGI fallback disabled"
require_contains "scripts/setup-upload-exec-handler.sh" "restart_tomcat" "Tomcat restart helper"
require_contains "scripts/setup-upload-exec-handler.sh" 'systemctl restart "$service"' "Tomcat restart instead of unsupported reload"
require_contains "scripts/setup-upload-exec-handler.sh" "/var/lib/tomcat10/conf" "Tomcat 10 context path support"

require_file "scripts/update-nginx-lab-upstream.sh"
require_contains "scripts/update-nginx-lab-upstream.sh" "LAB_UPSTREAM_HOST" "Nginx root upstream host"
require_contains "scripts/update-nginx-lab-upstream.sh" "LAB_UPSTREAM_PORT" "Nginx root upstream port"
require_contains "scripts/update-nginx-lab-upstream.sh" "root location proxy_pass" "root location update diagnostic"
require_contains "scripts/update-nginx-lab-upstream.sh" 'proxy_pass http://$LAB_UPSTREAM_HOST:$LAB_UPSTREAM_PORT;' "root upstream target"
require_contains "scripts/update-nginx-lab-upstream.sh" "rm -f \"$OLD_UPLOAD_UI_SNIPPET\"" "legacy upload UI snippet cleanup"
require_contains "scripts/update-nginx-lab-upstream.sh" "Nginx root upstream updated" "root upstream status"
require_contains "scripts/update-nginx-lab-upstream.sh" "nginx -t" "Nginx validation before reload"
require_contains "scripts/update-nginx-lab-upstream.sh" "systemctl reload nginx" "Nginx reload after upstream update"

require_file "scripts/setup-nginx-exec-proxy.sh"
require_contains "scripts/setup-nginx-exec-proxy.sh" "LAB_EXEC_PROXY_PREFIX" "HTTPS exec proxy prefix"
require_contains "scripts/setup-nginx-exec-proxy.sh" "LAB_JSP_EXEC_PROXY_PREFIX" "HTTPS JSP proxy prefix"
require_contains "scripts/setup-nginx-exec-proxy.sh" 'proxy_pass http://127.0.0.1:$LAB_EXEC_HANDLER_PORT/uploads/' "Apache exec proxy upstream"
require_contains "scripts/setup-nginx-exec-proxy.sh" 'proxy_pass http://$LAB_TOMCAT_UPSTREAM_HOST:$LAB_TOMCAT_UPSTREAM_PORT/$LAB_TOMCAT_CONTEXT_NAME/' "Tomcat JSP proxy upstream"
require_contains "scripts/setup-nginx-ssl.sh" "webshell-lab-exec-proxy*.conf" "optional Nginx exec proxy include"

require_contains "scripts/switch-server.sh" "LAB_AUTO_EXEC_HANDLER" "the automatic handler toggle"
require_contains "scripts/switch-server.sh" "LAB_UPLOAD_EXECUTABLE=1" "automatic executable permission enablement"
require_contains "scripts/switch-server.sh" "setup-upload-exec-handler.sh" "automatic handler setup script"
require_contains "scripts/switch-server.sh" "LAB_AUTO_NGINX_UPSTREAM" "automatic Nginx root upstream toggle"
require_contains "scripts/switch-server.sh" "update-nginx-lab-upstream.sh" "automatic Nginx root upstream script"
require_contains "scripts/switch-server.sh" "maybe_update_nginx_upstream" "Nginx root upstream update hook"
require_contains "scripts/switch-server.sh" "Automatic Nginx root upstream" "clear Nginx root upstream status"
require_contains "scripts/switch-server.sh" "prepare-dir" "upload directory preparation"
require_contains "scripts/reset-uploads.sh" "prepare-dir" "upload directory preparation after reset"

require_contains "common/templates/upload.html" 'href="styles.css"' "upload page stylesheet"
require_contains "common/templates/upload.html" 'src="upload.js"' "upload page script"
require_contains "common/public/upload.js" "basePath" "upload UI base path detection"
require_contains "common/public/upload.js" "labUrl('/upload')" "upload endpoint"

require_contains "servers/node-express/server.js" "LAB_UPLOAD_EXECUTABLE" "the executable upload toggle"
require_contains "servers/node-express/server.js" "chmodSync(filePath, 0o775)" "uploaded file chmod"
require_contains "servers/php-apache/index.php" "LAB_UPLOAD_EXECUTABLE" "the executable upload toggle"
require_contains "servers/php-apache/index.php" "chmod($path, 0775)" "uploaded file chmod"
require_contains "servers/jsp-tomcat/src/main/java/lab/EmbeddedTomcatServer.java" "UploadPermissions.prepareDirectory(uploadDir);" "upload directory preparation"
require_contains "servers/jsp-tomcat/src/main/java/lab/UploadServlet.java" "UploadPermissions.prepareFile(storedFile);" "uploaded file chmod"
require_file "servers/jsp-tomcat/src/main/java/lab/UploadPermissions.java"
require_contains "servers/jsp-tomcat/src/main/java/lab/UploadPermissions.java" "LAB_UPLOAD_EXECUTABLE" "the executable upload toggle"
require_contains "servers/aspnet-core/Program.cs" "LAB_UPLOAD_EXECUTABLE" "the executable upload toggle"
require_contains "servers/aspnet-core/Program.cs" "File.SetUnixFileMode(path" "uploaded file chmod"

require_file "docs/automatic-upload-exec-handlers.md"
require_contains "docs/automatic-upload-exec-handlers.md" "LAB_AUTO_EXEC_HANDLER=1" "automatic handler guide"
require_contains "docs/automatic-upload-exec-handlers.md" "setup-nginx-exec-proxy.sh" "HTTPS proxy guide"
require_contains "docs/automatic-upload-exec-handlers.md" "update-nginx-lab-upstream.sh" "automatic root upstream guide"
require_contains "docs/automatic-upload-exec-handlers.md" "https://<server>/exec/<file>.js" "HTTPS Node execution URL"
require_contains "docs/automatic-upload-exec-handlers.md" "https://<server>/jsp-exec/<file>.jsp" "HTTPS JSP execution URL"
require_contains "docs/automatic-upload-exec-handlers.md" "#!/usr/bin/env -S node --jitless" "Node CGI jitless sample"
require_contains "docs/automatic-upload-exec-handlers.md" "openjdk-21-jdk" "Tomcat Java 21 prerequisite"
require_contains "README.md" "LAB_AUTO_EXEC_HANDLER=1" "README automatic handler usage"
require_contains "README.md" "setup-nginx-exec-proxy.sh" "README HTTPS proxy usage"
require_contains "README.md" "LAB_AUTO_NGINX_UPSTREAM" "README automatic Nginx root upstream usage"

if [ "$failures" -gt 0 ]; then
  printf '\nUpload executable config check failed with %s issue(s).\n' "$failures" >&2
  exit 1
fi

printf 'Upload executable config check passed.\n'
