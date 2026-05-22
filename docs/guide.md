# Webshell Detection Lab Guide / 웹쉘 탐지 랩 통합 가이드

## English

### 1. Purpose

`webshell-detection-lab` is a Linux-oriented test lab for demonstrating and validating a file-system monitoring webshell detection Agent.

The lab keeps the SecuTrace-style web pages as the main service and provides the upload test page separately:

- Main site: `/`, `/index.html`, `/login.html`, `/signup.html`, `/dashboard.html`
- Upload test page: `/upload.html`

The upload page intentionally uses weak upload controls so the Agent can observe file creation and modification events across different web runtimes.

This project does not include webshell samples, command execution handlers, reverse shells, payload generators, or bypass payload collections. Test samples must be prepared separately and used only in an authorized, controlled environment.

### 2. Architecture

The same web flow is implemented across four interchangeable runtimes:

| Runtime | Start Command | Upload Directory |
| --- | --- | --- |
| Node.js / Express | `./scripts/switch-server.sh node` | `servers/node-express/uploads` |
| PHP | `./scripts/switch-server.sh php` | `servers/php-apache/uploads` |
| JSP / Tomcat | `./scripts/switch-server.sh jsp` | `servers/jsp-tomcat/uploads` |
| ASP.NET Core | `./scripts/switch-server.sh aspnet` | `servers/aspnet-core/uploads` |

Shared pages and browser assets are stored under:

```text
common/templates
common/public
```

Each runtime writes uploaded files to its own `uploads` directory and writes upload metadata to:

```text
servers/<runtime>/logs/upload-events.jsonl
```

Each upload event records the runtime, original filename, stored filename, stored path, size, MIME type, SHA-256 hash, upload timestamp, and remote address when available.

### 3. External Linux Install

Install the lab on a Linux server:

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | bash
```

Default install path:

```text
/opt/webshell-detection-lab
```

If dependencies are already installed:

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | SKIP_PACKAGES=1 bash
```

Check prerequisites:

```bash
cd /opt/webshell-detection-lab
./scripts/check-prereqs.sh
```

### 4. Runtime Switching

Start one runtime at a time:

```bash
cd /opt/webshell-detection-lab
./scripts/switch-server.sh node
```

Switch runtime:

```bash
./scripts/switch-server.sh php
./scripts/switch-server.sh jsp
./scripts/switch-server.sh aspnet
```

Stop the active runtime:

```bash
./scripts/stop-server.sh
```

Reset uploaded files and logs:

```bash
./scripts/reset-uploads.sh
```

The direct runtime listener defaults to:

```text
LAB_HOST=0.0.0.0
LAB_PORT=8080
```

Direct access URL:

```text
http://secutrace.co.kr:8080/
http://secutrace.co.kr:8080/upload.html
```

Use firewall, cloud security groups, VPN rules, or a reverse proxy to restrict access to trusted testers.

### 5. Domain And HTTPS

Point DNS to the Linux server:

```text
secutrace.co.kr    A    <linux-server-public-ip>
```

Recommended HTTPS layout:

```text
Tester -> https://secutrace.co.kr:443 -> Nginx -> http://127.0.0.1:8080 -> active runtime
```

Open TCP `80` for Let's Encrypt HTTP validation and redirect. Open TCP `443` only to trusted tester IP ranges if the lab is not public. Keep TCP `8080` closed externally when using Nginx.

Configure Nginx and Let's Encrypt:

```bash
cd /opt/webshell-detection-lab
sudo DOMAIN=secutrace.co.kr ADMIN_EMAIL=admin@secutrace.co.kr ./scripts/setup-nginx-ssl.sh
```

Start the active runtime behind Nginx:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

Open:

```text
https://secutrace.co.kr/
https://secutrace.co.kr/upload.html
```

Runtime switching keeps the same external HTTPS URL.

If `secutrace.co.kr` already has another SSL service, use a dedicated subdomain such as `lab.secutrace.co.kr` and run the SSL setup with that domain:

```bash
sudo DOMAIN=lab.secutrace.co.kr ADMIN_EMAIL=admin@secutrace.co.kr ./scripts/setup-nginx-ssl.sh
```

### 6. Agent Configuration

If the Agent follows symlinks, monitor:

```text
/opt/webshell-detection-lab/runtime/current/uploads
```

If the Agent does not follow symlinks, monitor the concrete runtime paths:

```text
/opt/webshell-detection-lab/servers/node-express/uploads
/opt/webshell-detection-lab/servers/php-apache/uploads
/opt/webshell-detection-lab/servers/jsp-tomcat/uploads
/opt/webshell-detection-lab/servers/aspnet-core/uploads
```

The active runtime and watch path can be checked with:

```bash
cat /opt/webshell-detection-lab/runtime/active-server.json
```

### 7. PoC Workflow

Use one runtime at a time.

1. Reset previous state.

```bash
cd /opt/webshell-detection-lab
./scripts/reset-uploads.sh
```

2. Start the target runtime.

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

3. Confirm the runtime.

```bash
curl -k https://secutrace.co.kr/health
```

4. Open the site and upload page.

```text
https://secutrace.co.kr/
https://secutrace.co.kr/upload.html
```

5. Upload your controlled test sample.

6. Compare the Agent result with the server upload log.

```bash
tail -n 5 /opt/webshell-detection-lab/runtime/current/logs/upload-events.jsonl
```

7. Repeat the same steps for `php`, `jsp`, and `aspnet`.

Record this evidence for each test:

| Field | Value |
| --- | --- |
| Runtime | Node.js, PHP, JSP/Tomcat, or ASP.NET Core |
| Sample name | User-provided sample filename |
| Stored path | Runtime upload path |
| SHA-256 | Hash from `upload-events.jsonl` |
| Upload time | Server-side timestamp |
| Agent result | Detected, missed, or expected non-detection |
| Detection time | Agent event timestamp |
| Rule/signature | Agent rule or signature name |
| Notes | Any useful operational context |

The PoC is successful when the Agent observes file creation in each selected runtime upload directory and its detection output can be correlated with `upload-events.jsonl`.

### 8. Troubleshooting

Check active runtime:

```bash
cat /opt/webshell-detection-lab/runtime/active-server.json
```

Check runtime logs:

```bash
cat /opt/webshell-detection-lab/runtime/current/logs/server.out.log
cat /opt/webshell-detection-lab/runtime/current/logs/server.err.log
```

Check Nginx:

```bash
sudo nginx -t
sudo systemctl status nginx
```

Check certificate renewal:

```bash
sudo certbot renew --dry-run
```

If port `8080` is already in use:

```bash
LAB_PORT=9090 ./scripts/switch-server.sh node
```

## 한국어

### 1. 목적

`webshell-detection-lab`는 파일 시스템 감시 방식의 웹쉘 탐지 Agent를 시연하고 검증하기 위한 Linux 기반 테스트 랩입니다.

이 랩은 SecuTrace 스타일 웹 페이지를 기본 서비스로 유지하고, 업로드 테스트 페이지를 별도로 제공합니다:

- 기본 사이트: `/`, `/index.html`, `/login.html`, `/signup.html`, `/dashboard.html`
- 업로드 테스트 페이지: `/upload.html`

업로드 페이지는 Agent가 다양한 웹 런타임에서 발생하는 파일 생성과 변경 이벤트를 관찰할 수 있도록 의도적으로 약한 업로드 통제를 사용합니다.

이 프로젝트에는 웹쉘 샘플, 명령 실행 핸들러, 리버스 쉘, 페이로드 생성기, 우회 페이로드 모음이 포함되지 않습니다. 테스트 샘플은 별도로 준비하고 승인된 통제 환경에서만 사용해야 합니다.

### 2. 구조

동일한 웹 흐름을 네 가지 교체 가능한 런타임으로 제공합니다:

| 런타임 | 실행 명령 | 업로드 디렉터리 |
| --- | --- | --- |
| Node.js / Express | `./scripts/switch-server.sh node` | `servers/node-express/uploads` |
| PHP | `./scripts/switch-server.sh php` | `servers/php-apache/uploads` |
| JSP / Tomcat | `./scripts/switch-server.sh jsp` | `servers/jsp-tomcat/uploads` |
| ASP.NET Core | `./scripts/switch-server.sh aspnet` | `servers/aspnet-core/uploads` |

공통 페이지와 브라우저 리소스는 다음 경로에 있습니다:

```text
common/templates
common/public
```

각 런타임은 업로드 파일을 자체 `uploads` 디렉터리에 저장하고 업로드 메타데이터를 다음 파일에 기록합니다:

```text
servers/<runtime>/logs/upload-events.jsonl
```

업로드 이벤트에는 런타임, 원본 파일명, 저장 파일명, 저장 경로, 크기, MIME type, SHA-256 해시, 업로드 시각, 가능한 경우 원격 주소가 기록됩니다.

### 3. 외부 Linux 서버 설치

Linux 서버에서 랩을 설치합니다:

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | bash
```

기본 설치 경로:

```text
/opt/webshell-detection-lab
```

의존성이 이미 설치되어 있다면:

```bash
curl -fsSL https://raw.githubusercontent.com/dewdorp/webshell-detection-lab/test/install.sh | SKIP_PACKAGES=1 bash
```

필수 구성 확인:

```bash
cd /opt/webshell-detection-lab
./scripts/check-prereqs.sh
```

### 4. 런타임 교체

런타임은 한 번에 하나만 실행합니다:

```bash
cd /opt/webshell-detection-lab
./scripts/switch-server.sh node
```

런타임 교체:

```bash
./scripts/switch-server.sh php
./scripts/switch-server.sh jsp
./scripts/switch-server.sh aspnet
```

활성 런타임 종료:

```bash
./scripts/stop-server.sh
```

업로드 파일과 로그 초기화:

```bash
./scripts/reset-uploads.sh
```

직접 실행 시 기본 바인딩은 다음과 같습니다:

```text
LAB_HOST=0.0.0.0
LAB_PORT=8080
```

직접 접속 URL:

```text
http://secutrace.co.kr:8080/
http://secutrace.co.kr:8080/upload.html
```

접근 제어는 방화벽, 클라우드 보안 그룹, VPN, 리버스 프록시 정책으로 신뢰된 테스트 사용자에게만 허용하세요.

### 5. 도메인과 HTTPS

DNS를 Linux 서버로 지정합니다:

```text
secutrace.co.kr    A    <linux-server-public-ip>
```

권장 HTTPS 구성:

```text
Tester -> https://secutrace.co.kr:443 -> Nginx -> http://127.0.0.1:8080 -> active runtime
```

Let's Encrypt HTTP 검증과 리다이렉트를 위해 TCP `80`을 허용합니다. 랩이 공개 서비스가 아니라면 TCP `443`은 신뢰된 테스트 IP 대역만 허용합니다. Nginx를 사용할 때 TCP `8080`은 외부에서 차단합니다.

Nginx와 Let's Encrypt를 설정합니다:

```bash
cd /opt/webshell-detection-lab
sudo DOMAIN=secutrace.co.kr ADMIN_EMAIL=admin@secutrace.co.kr ./scripts/setup-nginx-ssl.sh
```

Nginx 뒤에서 활성 런타임을 실행합니다:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

접속 URL:

```text
https://secutrace.co.kr/
https://secutrace.co.kr/upload.html
```

런타임을 교체해도 외부 HTTPS URL은 유지됩니다.

`secutrace.co.kr`에서 이미 다른 SSL 서비스를 사용 중이라면 `lab.secutrace.co.kr` 같은 전용 서브도메인을 사용하고 해당 도메인으로 SSL 설정을 실행하세요:

```bash
sudo DOMAIN=lab.secutrace.co.kr ADMIN_EMAIL=admin@secutrace.co.kr ./scripts/setup-nginx-ssl.sh
```

### 6. Agent 감시 경로

Agent가 symlink를 따라갈 수 있다면 다음 경로를 감시합니다:

```text
/opt/webshell-detection-lab/runtime/current/uploads
```

Agent가 symlink를 따라가지 못한다면 런타임별 실제 경로를 감시합니다:

```text
/opt/webshell-detection-lab/servers/node-express/uploads
/opt/webshell-detection-lab/servers/php-apache/uploads
/opt/webshell-detection-lab/servers/jsp-tomcat/uploads
/opt/webshell-detection-lab/servers/aspnet-core/uploads
```

활성 런타임과 감시 경로는 다음 명령으로 확인합니다:

```bash
cat /opt/webshell-detection-lab/runtime/active-server.json
```

### 7. PoC 절차

런타임은 한 번에 하나씩 테스트합니다.

1. 이전 상태 초기화.

```bash
cd /opt/webshell-detection-lab
./scripts/reset-uploads.sh
```

2. 대상 런타임 실행.

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
```

3. 런타임 확인.

```bash
curl -k https://secutrace.co.kr/health
```

4. 사이트와 업로드 페이지 접속.

```text
https://secutrace.co.kr/
https://secutrace.co.kr/upload.html
```

5. 통제된 테스트 샘플 업로드.

6. Agent 결과와 서버 업로드 로그 비교.

```bash
tail -n 5 /opt/webshell-detection-lab/runtime/current/logs/upload-events.jsonl
```

7. `php`, `jsp`, `aspnet` 런타임에서도 같은 절차를 반복합니다.

각 테스트마다 다음 증적을 기록합니다:

| 항목 | 값 |
| --- | --- |
| 런타임 | Node.js, PHP, JSP/Tomcat, ASP.NET Core |
| 샘플 이름 | 사용자 제공 샘플 파일명 |
| 저장 경로 | 런타임 업로드 경로 |
| SHA-256 | `upload-events.jsonl`의 해시 |
| 업로드 시각 | 서버 기록 시각 |
| Agent 결과 | 탐지, 미탐, 또는 기대한 미탐 |
| 탐지 시각 | Agent 이벤트 시각 |
| 룰/시그니처 | Agent 룰 또는 시그니처 이름 |
| 비고 | 운영상 참고할 내용 |

선택한 각 런타임 업로드 디렉터리에서 Agent가 파일 생성을 관찰하고, 탐지 결과를 `upload-events.jsonl`과 상관분석할 수 있으면 PoC 성공으로 봅니다.

### 8. 문제 해결

활성 런타임 확인:

```bash
cat /opt/webshell-detection-lab/runtime/active-server.json
```

런타임 로그 확인:

```bash
cat /opt/webshell-detection-lab/runtime/current/logs/server.out.log
cat /opt/webshell-detection-lab/runtime/current/logs/server.err.log
```

Nginx 확인:

```bash
sudo nginx -t
sudo systemctl status nginx
```

인증서 갱신 확인:

```bash
sudo certbot renew --dry-run
```

`8080` 포트가 이미 사용 중이면:

```bash
LAB_PORT=9090 ./scripts/switch-server.sh node
```
