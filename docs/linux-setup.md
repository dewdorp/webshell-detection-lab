# Linux Setup

This lab is designed for a Linux host without Docker.

## Baseline

```bash
cd webshell-detection-lab
chmod +x scripts/*.sh
./scripts/check-prereqs.sh
```

The default port is `8080`. Override it with:

```bash
LAB_PORT=9090 ./scripts/switch-server.sh node
```

The default host bind is `0.0.0.0`, which allows external access when firewall rules permit it. Override it with:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

For `secutrace.co.kr`, point the DNS A record to the server public IP and open the selected lab port only to trusted source IPs.

For HTTPS on `80` and `443`, put Nginx in front of the lab runtime:

```bash
sudo DOMAIN=secutrace.co.kr ADMIN_EMAIL=admin@secutrace.co.kr ./scripts/setup-nginx-ssl.sh
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

## Install Common Prerequisites

Ubuntu/Debian example:

```bash
sudo apt update
sudo apt install -y nodejs npm php-cli openjdk-17-jdk maven
```

Install .NET from Microsoft's Linux package feed for your distribution:

```text
https://learn.microsoft.com/dotnet/core/install/linux
```

## Agent Watch Path

After switching servers, the script prints the concrete upload path. If your Agent follows symlinks, you can monitor:

```text
webshell-detection-lab/runtime/current/uploads
```

If it does not, use the concrete runtime path.

## Reset

```bash
./scripts/reset-uploads.sh
```
