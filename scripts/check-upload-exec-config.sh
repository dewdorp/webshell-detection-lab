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
require_contains "scripts/setup-upload-exec-handler.sh" "configure_php" "PHP handler setup"
require_contains "scripts/setup-upload-exec-handler.sh" "configure_node" "Node CGI handler setup"
require_contains "scripts/setup-upload-exec-handler.sh" "configure_jsp" "JSP Tomcat handler setup"
require_contains "scripts/setup-upload-exec-handler.sh" "disable_apache_exec_sites" "previous Apache handler cleanup"
require_contains "scripts/setup-upload-exec-handler.sh" "disable_tomcat_exec_context" "previous Tomcat handler cleanup"
require_contains "scripts/setup-upload-exec-handler.sh" "LAB_EXEC_HANDLER_PORT" "separate handler port support"

require_contains "scripts/switch-server.sh" "LAB_AUTO_EXEC_HANDLER" "the automatic handler toggle"
require_contains "scripts/switch-server.sh" "LAB_UPLOAD_EXECUTABLE=1" "automatic executable permission enablement"
require_contains "scripts/switch-server.sh" "setup-upload-exec-handler.sh" "automatic handler setup script"
require_contains "scripts/switch-server.sh" "prepare-dir" "upload directory preparation"
require_contains "scripts/reset-uploads.sh" "prepare-dir" "upload directory preparation after reset"

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
require_contains "README.md" "LAB_AUTO_EXEC_HANDLER=1" "README automatic handler usage"

if [ "$failures" -gt 0 ]; then
  printf '\nUpload executable config check failed with %s issue(s).\n' "$failures" >&2
  exit 1
fi

printf 'Upload executable config check passed.\n'
