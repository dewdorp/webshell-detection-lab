# PHP Runtime

## Start With Built-In Server

```bash
cd webshell-detection-lab
./scripts/switch-server.sh php
```

The switch script runs `php -S 127.0.0.1:8080 index.php` inside `servers/php-apache`.

## Apache-Oriented Deployment

Point an Apache virtual host document root at `webshell-detection-lab/servers/php-apache` and make sure the web server user can write `uploads` and `logs`.

## Paths

- Uploads: `servers/php-apache/uploads`
- Logs: `servers/php-apache/logs/upload-events.jsonl`
