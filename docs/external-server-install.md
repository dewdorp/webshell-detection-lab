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

The installer attempts to install common packages on `apt`, `dnf`, or `yum` systems: `git`, `curl`, `nodejs`, `npm`, `php-cli`, Java 17, and `maven`.

.NET SDK installation varies by Linux distribution. Install it from Microsoft's Linux documentation.

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
http://secutrace.co.kr:8080/
```

Use another port:

```bash
LAB_PORT=9090 ./scripts/switch-server.sh php
```

Bind to a specific interface:

```bash
LAB_HOST=0.0.0.0 LAB_PORT=8080 ./scripts/switch-server.sh node
```

The default `LAB_HOST` is `0.0.0.0`, so the lab server listens on all interfaces. Restrict access with your server firewall, cloud security group, VPN, or reverse proxy rules.

## Domain Setup For secutrace.co.kr

Create or update DNS:

```text
secutrace.co.kr    A    <your-linux-server-public-ip>
```

Open only the lab port from trusted source IPs. Ubuntu UFW example:

```bash
sudo ufw allow from <trusted-public-ip>/32 to any port 8080 proto tcp
sudo ufw deny 8080/tcp
sudo ufw status numbered
```

Cloud firewall/security group example:

```text
Inbound TCP 8080: allow only your office/VPN/tester public IP ranges
Inbound TCP 22: allow only admin IP ranges
```

Then start the active runtime:

```bash
cd /opt/webshell-detection-lab
LAB_HOST=0.0.0.0 LAB_PORT=8080 ./scripts/switch-server.sh node
```

Open:

```text
http://secutrace.co.kr:8080/
```

Optional Nginx reverse proxy for standard HTTP port:

```nginx
server {
    listen 80;
    server_name secutrace.co.kr;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

With this Nginx option, keep the lab process bound to localhost:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

Then use firewall rules on ports `80` or `443`.

## Configure The Agent

Concrete upload paths:

```text
/opt/webshell-detection-lab/servers/node-express/uploads
/opt/webshell-detection-lab/servers/php-apache/uploads
/opt/webshell-detection-lab/servers/jsp-tomcat/uploads
/opt/webshell-detection-lab/servers/aspnet-core/uploads
```

The switch script also updates `/opt/webshell-detection-lab/runtime/current/uploads`.

If your Agent follows symlinks, monitor `runtime/current/uploads`. If it does not, monitor the concrete path printed by `switch-server.sh`.

## Upload And Correlate

1. Start a runtime.
2. Open `http://secutrace.co.kr:8080/`.
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
