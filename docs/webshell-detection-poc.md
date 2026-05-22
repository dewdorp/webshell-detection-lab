# Webshell Detection PoC Guide / 웹쉘 탐지 PoC 가이드

## English

### Objective

This guide explains how to validate a file-system monitoring webshell detection Agent with the separate SecuTrace upload page in `webshell-detection-lab`.

The lab is designed to answer these questions:

- Does the Agent detect suspicious files when they are uploaded through different web runtimes?
- Does detection behavior differ across Node.js, PHP, JSP/Tomcat, and ASP.NET Core upload paths?
- Can detection events be correlated with server-side upload logs?
- Does the Agent preserve enough metadata, such as path, timestamp, hash, and file name, for investigation?

### Safety Scope

The lab provides vulnerable upload behavior only. It does not provide webshell samples, command execution endpoints, reverse shells, or payload generators.

Use your own controlled test samples and follow your organization's authorization process.

### Recommended Test Environment

Use a dedicated Linux host or VM:

```text
secutrace.co.kr -> Nginx TLS reverse proxy -> 127.0.0.1:8080 active lab runtime
```

Recommended firewall policy:

- Allow TCP `80` for Let's Encrypt HTTP validation and redirect.
- Allow TCP `443` only from trusted tester IP ranges when the lab is not public.
- Block TCP `8080` externally.
- Allow SSH only from admin IP ranges.

### Preparation

1. Install the lab:

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | bash
```

2. Configure HTTPS:

```bash
cd /opt/webshell-detection-lab
sudo DOMAIN=secutrace.co.kr ADMIN_EMAIL=admin@secutrace.co.kr ./scripts/setup-nginx-ssl.sh
```

3. Install and start the webshell detection Agent.

4. Configure the Agent to monitor either the stable symlink:

```text
/opt/webshell-detection-lab/runtime/current/uploads
```

or each concrete runtime path:

```text
/opt/webshell-detection-lab/servers/node-express/uploads
/opt/webshell-detection-lab/servers/php-apache/uploads
/opt/webshell-detection-lab/servers/jsp-tomcat/uploads
/opt/webshell-detection-lab/servers/aspnet-core/uploads
```

If the Agent does not follow symlinks, use the concrete runtime path printed by `switch-server.sh`.

### PoC Workflow

Run one runtime at a time.

1. Reset previous state:

```bash
cd /opt/webshell-detection-lab
./scripts/reset-uploads.sh
```

2. Start the target runtime behind Nginx:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

3. Confirm the runtime:

```bash
curl -k https://secutrace.co.kr/health
```

4. Open the preserved SecuTrace site and the separate upload test page:

```text
https://secutrace.co.kr/
https://secutrace.co.kr/upload.html
```

5. Upload your controlled test sample through the upload UI.

6. Record the server-side upload log:

```bash
tail -n 5 /opt/webshell-detection-lab/runtime/current/logs/upload-events.jsonl
```

7. Record the Agent detection result.

8. Repeat for each runtime:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh php
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh jsp
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh aspnet
```

### Evidence To Capture

For each upload test, capture runtime name, sample file name, stored path, SHA-256 hash, upload timestamp, Agent detection timestamp, Agent rule or signature name, Agent severity, detection status, and relevant Agent log excerpt.

### Result Matrix

| Runtime | Sample | Stored Path | SHA-256 | Agent Result | Detection Time | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Node.js | user-provided | `servers/node-express/uploads/...` | `...` | Detected / Missed | `...` | `...` |
| PHP | user-provided | `servers/php-apache/uploads/...` | `...` | Detected / Missed | `...` | `...` |
| JSP/Tomcat | user-provided | `servers/jsp-tomcat/uploads/...` | `...` | Detected / Missed | `...` | `...` |
| ASP.NET Core | user-provided | `servers/aspnet-core/uploads/...` | `...` | Detected / Missed | `...` | `...` |

### Success Criteria

The PoC is successful when:

- The Agent observes file creation in every selected runtime upload directory.
- The Agent produces a detection or expected non-detection for each controlled sample.
- Agent timestamps can be correlated with `upload-events.jsonl`.
- The detection result includes enough context for an operator to locate the uploaded file.
- Runtime switching does not require changing the external HTTPS URL.

### Troubleshooting

```bash
cat /opt/webshell-detection-lab/runtime/active-server.json
cat /opt/webshell-detection-lab/runtime/current/logs/server.err.log
sudo nginx -t
sudo systemctl status nginx
sudo certbot renew --dry-run
```

## 한국어

### 목적

이 문서는 `webshell-detection-lab`의 별도 SecuTrace 업로드 페이지를 사용해 파일 시스템 감시 방식의 웹쉘 탐지 Agent를 검증하는 절차를 설명합니다.

이 랩은 다음 질문에 답하기 위해 설계되었습니다:

- 서로 다른 웹 런타임을 통해 업로드된 의심 파일을 Agent가 탐지하는가?
- Node.js, PHP, JSP/Tomcat, ASP.NET Core 업로드 경로별 탐지 차이가 있는가?
- Agent 탐지 이벤트와 서버 업로드 로그를 상관분석할 수 있는가?
- 경로, 시각, 해시, 파일명 등 조사에 필요한 메타데이터가 충분히 남는가?

### 안전 범위

이 랩은 취약 업로드 동작만 제공합니다. 웹쉘 샘플, 명령 실행 엔드포인트, 리버스 쉘, 페이로드 생성기는 제공하지 않습니다.

테스트 샘플은 사용자가 통제된 환경에서 직접 준비하고, 조직의 승인 절차에 따라 사용해야 합니다.

### 권장 테스트 환경

전용 Linux 호스트 또는 VM을 사용하세요:

```text
secutrace.co.kr -> Nginx TLS reverse proxy -> 127.0.0.1:8080 active lab runtime
```

권장 방화벽 정책:

- Let's Encrypt HTTP 검증과 리다이렉트를 위해 TCP `80` 허용.
- 랩이 공개 서비스가 아니라면 TCP `443`은 신뢰된 테스터 IP 대역만 허용.
- TCP `8080`은 외부에서 차단.
- SSH는 관리자 IP 대역만 허용.

### 준비

1. 랩 설치:

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | bash
```

2. HTTPS 설정:

```bash
cd /opt/webshell-detection-lab
sudo DOMAIN=secutrace.co.kr ADMIN_EMAIL=admin@secutrace.co.kr ./scripts/setup-nginx-ssl.sh
```

3. 웹쉘 탐지 Agent를 설치하고 실행합니다.

4. Agent 감시 경로를 설정합니다. symlink를 지원하면 다음 경로를 사용할 수 있습니다:

```text
/opt/webshell-detection-lab/runtime/current/uploads
```

또는 런타임별 실제 경로를 사용합니다:

```text
/opt/webshell-detection-lab/servers/node-express/uploads
/opt/webshell-detection-lab/servers/php-apache/uploads
/opt/webshell-detection-lab/servers/jsp-tomcat/uploads
/opt/webshell-detection-lab/servers/aspnet-core/uploads
```

Agent가 symlink를 따라가지 못한다면 `switch-server.sh`가 출력하는 실제 업로드 경로를 사용하세요.

### PoC 수행 절차

런타임은 한 번에 하나씩 실행합니다.

1. 이전 상태 초기화:

```bash
cd /opt/webshell-detection-lab
./scripts/reset-uploads.sh
```

2. Nginx 뒤에서 대상 런타임 실행:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

3. 런타임 확인:

```bash
curl -k https://secutrace.co.kr/health
```

4. 보존된 SecuTrace 사이트와 별도 업로드 테스트 페이지 접속:

```text
https://secutrace.co.kr/
https://secutrace.co.kr/upload.html
```

5. 사용자가 준비한 통제된 테스트 샘플을 업로드 UI에서 업로드합니다.

6. 서버 업로드 로그 확인:

```bash
tail -n 5 /opt/webshell-detection-lab/runtime/current/logs/upload-events.jsonl
```

7. Agent 탐지 결과를 기록합니다.

8. 각 런타임에 대해 반복합니다:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh php
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh jsp
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh aspnet
```

### 수집할 증적

각 업로드 테스트마다 런타임 이름, 샘플 파일명, 저장 경로, SHA-256 해시, 업로드 시각, Agent 탐지 시각, Agent 룰 또는 시그니처 이름, Agent 심각도, 탐지 상태, 관련 Agent 로그 일부를 수집합니다.

### 결과 매트릭스

| Runtime | Sample | Stored Path | SHA-256 | Agent Result | Detection Time | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Node.js | 사용자 제공 | `servers/node-express/uploads/...` | `...` | Detected / Missed | `...` | `...` |
| PHP | 사용자 제공 | `servers/php-apache/uploads/...` | `...` | Detected / Missed | `...` | `...` |
| JSP/Tomcat | 사용자 제공 | `servers/jsp-tomcat/uploads/...` | `...` | Detected / Missed | `...` | `...` |
| ASP.NET Core | 사용자 제공 | `servers/aspnet-core/uploads/...` | `...` | Detected / Missed | `...` | `...` |

### 성공 기준

PoC 성공 기준은 다음과 같습니다:

- 선택한 모든 런타임 업로드 경로에서 Agent가 파일 생성을 관찰한다.
- 각 통제 샘플에 대해 탐지 또는 기대한 미탐 결과가 발생한다.
- Agent 탐지 시각과 `upload-events.jsonl` 로그를 상관분석할 수 있다.
- 탐지 결과에 운영자가 업로드 파일을 찾을 수 있는 충분한 컨텍스트가 포함된다.
- 런타임을 교체해도 외부 HTTPS URL을 바꾸지 않아도 된다.

### 문제 해결

```bash
cat /opt/webshell-detection-lab/runtime/active-server.json
cat /opt/webshell-detection-lab/runtime/current/logs/server.err.log
sudo nginx -t
sudo systemctl status nginx
sudo certbot renew --dry-run
```
