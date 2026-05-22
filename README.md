# Webshell Detection Lab

SecuTrace-style multi-runtime web application with a separate vulnerable upload page for validating a file-system monitoring webshell detection Agent.

This is a separate project and does not modify the original `dewdorp/Webserver` app.

## Official Guide

Use the integrated Korean and English guide:

```text
docs/guide.md
```

GitHub URL:

```text
https://github.com/dewdorp/webshell-detection-lab/blob/test/docs/guide.md
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

Reset uploads while preserving the same executable permission mode:

```bash
LAB_UPLOAD_EXECUTABLE=1 ./scripts/reset-uploads.sh
```

## Automatic Upload Execution Handlers

For a controlled lab where each runtime switch should also update the matching external execution handler, enable the explicit automatic handler mode:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

`LAB_AUTO_EXEC_HANDLER=1` also enables executable upload permissions if `LAB_UPLOAD_EXECUTABLE` is not already set. Apache-backed handlers use `LAB_EXEC_HANDLER_PORT`, defaulting to `18080`.

See:

```text
docs/automatic-upload-exec-handlers.md
```

## Safety Boundary

The lab intentionally provides weak upload behavior for defensive Agent validation. It does not include webshell samples, reverse shells, payload generators, command execution handlers, or sample exploit payloads.
