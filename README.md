# Webshell Detection Lab

Linux-based vulnerable upload lab for validating a file-system monitoring webshell detection Agent.

This is a separate project and does not modify the original `dewdorp/Webserver` app.

## Safety Notice

This lab intentionally accepts weak file uploads so a defensive Agent can observe file creation and modification events. Use it only in a controlled environment.

The project does not include webshell samples, reverse shells, payload generators, or command execution handlers. Bring your own samples when validating your detection product.

## Quick Start

```bash
cd webshell-detection-lab
chmod +x scripts/*.sh
./scripts/check-prereqs.sh
./scripts/switch-server.sh node
```

Open:

```text
http://secutrace.co.kr:8080/
```

Switch runtimes:

```bash
./scripts/switch-server.sh node
./scripts/switch-server.sh php
./scripts/switch-server.sh jsp
./scripts/switch-server.sh aspnet
```

Stop the active lab server:

```bash
./scripts/stop-server.sh
```

Reset uploads and logs:

```bash
./scripts/reset-uploads.sh
```

## External Server Install

After this project is pushed to GitHub as `dewdorp/webshell-detection-lab`, an external Linux server can install it with:

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | bash
```

Detailed instructions are in `docs/external-server-install.md`.

## Network Exposure

The default bind host is `0.0.0.0` so the lab can be reached externally when firewall rules permit it. Use firewall or cloud security group rules to restrict access to trusted IP ranges.

For `secutrace.co.kr`, point the DNS A record to the Linux server public IP and start a runtime:

```bash
LAB_HOST=0.0.0.0 LAB_PORT=8080 ./scripts/switch-server.sh node
```

For HTTPS on ports `80` and `443`, use Nginx and Certbot:

```bash
sudo DOMAIN=secutrace.co.kr ADMIN_EMAIL=admin@secutrace.co.kr ./scripts/setup-nginx-ssl.sh
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

Then open:

```text
https://secutrace.co.kr/
```

## Routes

Each runtime exposes the same route contract:

- `GET /`
- `GET /health`
- `POST /upload`
- `GET /files`

Uploaded files are written to the active runtime's `uploads/` directory and upload events are written to `logs/upload-events.jsonl`.

## Agent Watch Paths

Concrete upload paths:

```text
servers/node-express/uploads
servers/php-apache/uploads
servers/jsp-tomcat/uploads
servers/aspnet-core/uploads
```

When supported by the host OS, `scripts/switch-server.sh` also updates:

```text
runtime/current -> servers/<active-runtime>
runtime/current/uploads
```

If your Agent does not follow symlinks, configure it with the concrete path printed by `switch-server.sh`.
