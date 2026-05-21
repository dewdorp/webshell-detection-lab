# Node.js / Express Runtime

## Start

```bash
cd webshell-detection-lab
./scripts/switch-server.sh node
```

The switch script runs `npm install` inside `servers/node-express` if `node_modules` is missing.

## Direct Run

```bash
cd webshell-detection-lab/servers/node-express
npm install
LAB_PORT=8080 node server.js
```

## Paths

- Uploads: `servers/node-express/uploads`
- Logs: `servers/node-express/logs/upload-events.jsonl`
- Server stdout: `servers/node-express/logs/server.out.log`
- Server stderr: `servers/node-express/logs/server.err.log`
