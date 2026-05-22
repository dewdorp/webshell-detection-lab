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

## Safety Boundary

The lab intentionally provides weak upload behavior for defensive Agent validation. It does not include webshell samples, reverse shells, payload generators, or command execution handlers.
