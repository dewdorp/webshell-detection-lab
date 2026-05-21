# Technology Stack / 기술 스택

## English

### Purpose

`webshell-detection-lab` is a Linux-based vulnerable upload lab for validating a file-system monitoring webshell detection Agent. It provides the same upload workflow across multiple language runtimes so detection behavior can be compared by server stack.

### Runtime Stack

| Runtime | Purpose | Default Start Path | Upload Path |
| --- | --- | --- | --- |
| Node.js / Express | JavaScript server implementation with multipart upload handling | `servers/node-express` | `servers/node-express/uploads` |
| PHP | PHP upload handler runnable with PHP built-in server or Apache-oriented deployment | `servers/php-apache` | `servers/php-apache/uploads` |
| JSP / Tomcat | Java servlet implementation with embedded Tomcat launcher and WAR packaging support | `servers/jsp-tomcat` | `servers/jsp-tomcat/uploads` |
| ASP.NET Core | .NET minimal API implementation | `servers/aspnet-core` | `servers/aspnet-core/uploads` |

### Shared Components

- `common/templates/index.html`: shared upload UI.
- `common/public/app.js`: shared browser-side upload and file-list logic.
- `common/public/styles.css`: shared UI styles.
- `scripts/switch-server.sh`: switches active runtime.
- `scripts/stop-server.sh`: stops the active runtime.
- `scripts/reset-uploads.sh`: clears uploads, logs, and runtime state.
- `scripts/setup-nginx-ssl.sh`: configures Nginx and Let's Encrypt TLS for `secutrace.co.kr`.

### Network Layout

Direct lab access:

```text
Client -> http://secutrace.co.kr:8080 -> active runtime
```

Recommended HTTPS layout:

```text
Client -> https://secutrace.co.kr:443 -> Nginx -> http://127.0.0.1:8080 -> active runtime
```

In the HTTPS layout, the active runtime should be started with:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

Nginx owns ports `80` and `443`; the lab runtime remains private on localhost.

### Data And Logs

Each runtime writes uploaded files to its own `uploads` directory and writes JSON Lines events to:

```text
servers/<runtime>/logs/upload-events.jsonl
```

Each upload event includes runtime name, original filename, stored filename, stored file path, file size, client-reported MIME type, SHA-256 hash, upload timestamp, and remote address when available.

### Security Boundary

This project intentionally provides weak upload controls for defensive testing. It does not include webshell samples, reverse shells, command execution handlers, payload generators, or bypass payload collections.

## 한국어

### 목적

`webshell-detection-lab`는 파일 시스템을 지속 감시하는 웹쉘 탐지 Agent를 검증하기 위한 Linux 기반 취약 업로드 랩입니다. 여러 언어 런타임에서 동일한 업로드 흐름을 제공하여 웹서버 스택별 탐지 결과를 비교할 수 있게 합니다.

### 런타임 스택

| 런타임 | 목적 | 기본 실행 경로 | 업로드 경로 |
| --- | --- | --- | --- |
| Node.js / Express | multipart 업로드를 처리하는 JavaScript 서버 구현 | `servers/node-express` | `servers/node-express/uploads` |
| PHP | PHP 내장 서버 또는 Apache 배포를 고려한 업로드 핸들러 | `servers/php-apache` | `servers/php-apache/uploads` |
| JSP / Tomcat | embedded Tomcat 실행과 WAR 패키징을 지원하는 Java servlet 구현 | `servers/jsp-tomcat` | `servers/jsp-tomcat/uploads` |
| ASP.NET Core | .NET minimal API 기반 구현 | `servers/aspnet-core` | `servers/aspnet-core/uploads` |

### 공통 구성 요소

- `common/templates/index.html`: 공통 업로드 UI.
- `common/public/app.js`: 브라우저 업로드 및 파일 목록 로직.
- `common/public/styles.css`: 공통 UI 스타일.
- `scripts/switch-server.sh`: 활성 런타임 교체.
- `scripts/stop-server.sh`: 활성 런타임 종료.
- `scripts/reset-uploads.sh`: 업로드 파일, 로그, 런타임 상태 초기화.
- `scripts/setup-nginx-ssl.sh`: `secutrace.co.kr`용 Nginx 및 Let's Encrypt TLS 설정.

### 네트워크 구성

직접 접근:

```text
Client -> http://secutrace.co.kr:8080 -> active runtime
```

권장 HTTPS 구성:

```text
Client -> https://secutrace.co.kr:443 -> Nginx -> http://127.0.0.1:8080 -> active runtime
```

HTTPS 구성에서는 활성 런타임을 다음처럼 실행합니다:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

Nginx가 `80`, `443` 포트를 담당하고, 실제 랩 런타임은 localhost에서만 동작합니다.

### 데이터와 로그

각 런타임은 업로드 파일을 자체 `uploads` 디렉터리에 저장하고 JSON Lines 이벤트를 다음 경로에 기록합니다:

```text
servers/<runtime>/logs/upload-events.jsonl
```

업로드 이벤트에는 런타임 이름, 원본 파일명, 저장된 파일명, 저장 경로, 파일 크기, 클라이언트가 보고한 MIME type, SHA-256 해시, 업로드 시각, 가능한 경우 원격 주소가 포함됩니다.

### 보안 경계

이 프로젝트는 방어 목적 테스트를 위해 의도적으로 약한 업로드 통제를 제공합니다. 웹쉘 샘플, 리버스 쉘, 명령 실행 핸들러, 페이로드 생성기, 우회 페이로드 모음은 포함하지 않습니다.
