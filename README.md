# Webshell Detection Lab

SecuTrace-style multi-runtime web application with a vulnerable upload page for validating a file-system monitoring webshell detection Agent.

This is a separate project and does not modify the original `dewdorp/Webserver` app.

## Official Guide

Use the integrated Korean and English guide:

```text
docs/guide.md
```

Additional lab execution guides:

```text
docs/executable-upload-permissions.md
docs/automatic-upload-exec-handlers.md
```

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | bash
cd /opt/webshell-detection-lab
./scripts/check-prereqs.sh
./scripts/switch-server.sh node
```

Open:

```text
http://secutrace.co.kr:8080/
http://secutrace.co.kr:8080/upload.html
```

Switch runtimes:

```bash
./scripts/switch-server.sh node
./scripts/switch-server.sh php
./scripts/switch-server.sh jsp
./scripts/switch-server.sh aspnet
```

## Executable Upload Permission Mode

By default, uploaded files are stored without forcing executable file permissions. For a controlled detection lab where the web server is already configured to execute scripts from the upload path, enable executable upload permissions explicitly:

```bash
LAB_UPLOAD_EXECUTABLE=1 ./scripts/switch-server.sh php
```

This sets runtime upload directories and newly uploaded files to `0775`. The option only changes file-system permissions. Script execution still requires the matching server-side handler, such as Apache/PHP-FPM, Tomcat/JSP, Node, Python, or another runtime configured for the upload path.

## Runtime Switching Behind Nginx

When `/etc/nginx/sites-available/webshell-detection-lab` exists, `switch-server.sh` updates the Nginx root upstream to the active lab portal by default:

```text
https://<domain>/            -> active lab portal
https://<domain>/upload.html -> active lab upload page
```

Use the same public portal URL while switching runtimes:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh php
LAB_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

JSP uses `8088` for the lab portal because the system Tomcat service commonly owns `8080` for uploaded JSP execution. Disable only the Nginx root upstream update with `LAB_AUTO_NGINX_UPSTREAM=0`.

## Automatic Upload Execution Handlers

For a controlled lab where each runtime switch should also update the matching external execution handler, enable the explicit automatic handler mode:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
LAB_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

`LAB_AUTO_EXEC_HANDLER=1` also enables executable upload permissions if `LAB_UPLOAD_EXECUTABLE` is not already set. Apache-backed handlers bind to `127.0.0.1:18080` by default.

For HTTPS-only execution testing through Nginx, configure the execution proxy once:

```bash
sudo DOMAIN=test.secutrace.co.kr ./scripts/setup-nginx-exec-proxy.sh
```

Then use:

```text
https://test.secutrace.co.kr/exec/<file>.php
https://test.secutrace.co.kr/exec/<file>.js
https://test.secutrace.co.kr/exec/<file>.py
https://test.secutrace.co.kr/jsp-exec/<file>.jsp
```

See:

```text
docs/automatic-upload-exec-handlers.md
```

## Safety Boundary

The lab intentionally provides weak upload behavior for defensive Agent validation. It does not include webshell samples, reverse shells, payload generators, command execution handlers, or sample exploit payloads.
