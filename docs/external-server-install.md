# External Linux Server Install Guide

This guide installs `webshell-detection-lab` on a Linux server so a file-system monitoring Agent can watch uploaded files.

## One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | bash
```

Default install directory:

```text
/opt/webshell-detection-lab
```

Custom install directory:

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | INSTALL_DIR="$HOME/webshell-detection-lab" bash
```

Skip package installation:

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | SKIP_PACKAGES=1 bash
```

## Required Runtime Packages

The installer attempts to install common packages on `apt`, `dnf`, or `yum` systems:

- `git`
- `curl`
- `nodejs`
- `npm`
- `php-cli`
- `openjdk-17-jdk` or `java-17-openjdk-devel`
- `maven`

.NET SDK installation varies by Linux distribution. Install it from Microsoft documentation:

```text
https://learn.microsoft.com/dotnet/core/install/linux
```

## Start A Runtime

```bash
cd /opt/webshell-detection-lab
./scripts/switch-server.sh node
./scripts/switch-server.sh php
./scripts/switch-server.sh jsp
./scripts/switch-server.sh aspnet
```

Default URL:

```text
http://localhost:8080/
```

Use another port:

```bash
LAB_PORT=9090 ./scripts/switch-server.sh php
```

## Configure The Agent

Concrete upload paths:

```text
/opt/webshell-detection-lab/servers/node-express/uploads
/opt/webshell-detection-lab/servers/php-apache/uploads
/opt/webshell-detection-lab/servers/jsp-tomcat/uploads
/opt/webshell-detection-lab/servers/aspnet-core/uploads
```

The switch script also updates:

```text
/opt/webshell-detection-lab/runtime/current/uploads
```

If your Agent follows symlinks, monitor `runtime/current/uploads`. If it does not, monitor the concrete path printed by `switch-server.sh`.

## Upload And Correlate

1. Start a runtime.
2. Open `http://localhost:8080/`.
3. Upload your own test sample.
4. Check Agent detection output.
5. Compare with the lab upload log:

```bash
tail -f /opt/webshell-detection-lab/runtime/current/logs/upload-events.jsonl
```

## Stop Or Reset

```bash
cd /opt/webshell-detection-lab
./scripts/stop-server.sh
./scripts/reset-uploads.sh
```

## Troubleshooting

```bash
./scripts/check-prereqs.sh
cat servers/node-express/logs/server.err.log
cat servers/php-apache/logs/server.err.log
cat servers/jsp-tomcat/logs/server.err.log
cat servers/aspnet-core/logs/server.err.log
```

If port `8080` is already in use:

```bash
LAB_PORT=9090 ./scripts/switch-server.sh node
```
