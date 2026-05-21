# ASP.NET Core Runtime

## Start

```bash
cd webshell-detection-lab
./scripts/switch-server.sh aspnet
```

The switch script runs:

```bash
dotnet run --urls http://0.0.0.0:8080
```

inside `servers/aspnet-core`.

## Direct Run

```bash
cd webshell-detection-lab/servers/aspnet-core
dotnet run --urls http://0.0.0.0:8080
```

## Paths

- Uploads: `servers/aspnet-core/uploads`
- Logs: `servers/aspnet-core/logs/upload-events.jsonl`
