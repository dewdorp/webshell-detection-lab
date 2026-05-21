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

Default direct URL:

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

## HTTPS On Ports 80 And 443

Recommended layout:

```text
Internet -> https://secutrace.co.kr:443 -> Nginx -> http://127.0.0.1:8080 -> active lab runtime
```

This keeps the language runtime switchable while Nginx owns ports `80` and `443`.

1. Confirm DNS points to the server:

```bash
dig +short secutrace.co.kr
```

2. Open firewall ports:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 8080/tcp
sudo ufw status numbered
```

If the lab must only be reachable from trusted testers, restrict `443` to trusted IPs:

```bash
sudo ufw allow 80/tcp
sudo ufw allow from <trusted-public-ip>/32 to any port 443 proto tcp
sudo ufw deny 443/tcp
sudo ufw deny 8080/tcp
```

Port `80` must be reachable during Let's Encrypt HTTP-01 validation and can remain open for HTTP-to-HTTPS redirects.

3. Configure Nginx and issue the certificate:

```bash
cd /opt/webshell-detection-lab
sudo DOMAIN=secutrace.co.kr ADMIN_EMAIL=admin@secutrace.co.kr ./scripts/setup-nginx-ssl.sh
```

If you do not want to provide an email:

```bash
sudo DOMAIN=secutrace.co.kr ./scripts/setup-nginx-ssl.sh
```

4. Start the active runtime behind Nginx:

```bash
cd /opt/webshell-detection-lab
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

5. Open:

```text
https://secutrace.co.kr/
```

Switching runtimes keeps the same HTTPS URL:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh php
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh jsp
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh aspnet
```

Certificate renewal is handled by Certbot's system timer on most Linux distributions. Check it with:

```bash
systemctl list-timers | grep certbot
sudo certbot renew --dry-run
```

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
2. Open `https://secutrace.co.kr/`.
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
