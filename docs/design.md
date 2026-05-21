# Webshell Detection Lab Design

## Purpose

Build a separate Linux-based vulnerable upload lab for validating a file-system monitoring webshell detection Agent.

This project is independent from the existing `dewdorp/Webserver` application. The original web server project should remain unchanged.

The lab provides intentionally weak file upload behavior and observable file-system events across multiple language runtimes. It does not include webshell samples, reverse shells, payload generators, or command-execution webshell code.

## Confirmed Requirements

- Run on Linux.
- Do not use Docker.
- Support runtime switching between Node.js, PHP, JSP/Tomcat, and ASP.NET Core.
- Keep `/`, `/upload`, `/files`, and `/health` consistent for every runtime.
- Store uploaded files on the real file system.
- Keep per-runtime upload directories separate.
- Provide Linux shell scripts for switching the active runtime.
- Let the user provide their own test samples.

## Agent Watch Paths

Each runtime writes uploads to its own directory:

```text
servers/node-express/uploads
servers/php-apache/uploads
servers/jsp-tomcat/uploads
servers/aspnet-core/uploads
```

Optional stable watch path:

```text
runtime/current/uploads
```

## Safety Boundaries

The project does not include webshell samples, reverse shells, remote command execution handlers, payload generators, bypass payload collections, or code that invokes OS commands from uploaded files.
