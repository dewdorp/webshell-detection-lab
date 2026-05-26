# Automatic Upload Execution Handlers / 업로드 실행 핸들러 자동 전환

## English

`LAB_AUTO_EXEC_HANDLER=1` updates the external script execution handler when you switch runtimes. If the Nginx site config exists, it also updates the main upload-page upstream so `https://<server>/upload.html` follows the active runtime.

For HTTPS-only testing, keep the execution handlers on loopback and expose them through Nginx:

```text
https://<server>/upload.html          -> active lab runtime, for example http://127.0.0.1:8088/upload.html
https://<server>/exec/<file>.php      -> http://127.0.0.1:18080/uploads/<file>.php
https://<server>/exec/<file>.js       -> http://127.0.0.1:18080/uploads/<file>.js
https://<server>/exec/<file>.py       -> http://127.0.0.1:18080/uploads/<file>.py
https://<server>/jsp-exec/<file>.jsp  -> http://127.0.0.1:8080/webshell-lab-jsp/<file>.jsp
```

The lab does not provide webshell samples, command execution handlers, or exploit payloads. Use only benign test files in an authorized lab network.

### Prerequisites

```bash
sudo apt update
sudo apt install -y apache2 libapache2-mod-php nodejs python3 nginx certbot python3-certbot-nginx
sudo a2enmod cgi
```

For JSP on current Ubuntu/Tomcat 10 systems, install Tomcat and Java 21:

```bash
sudo apt install -y tomcat10 openjdk-21-jdk
```

If Tomcat was already installed with an older Java runtime, set Java 21 for the service:

```bash
sudo mkdir -p /etc/systemd/system/tomcat10.service.d
printf '[Service]\nEnvironment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"\n' | sudo tee /etc/systemd/system/tomcat10.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart tomcat10
```

### One-Time HTTPS Proxy Setup

Run this after Nginx/SSL is configured for your domain:

```bash
cd /opt/webshell-detection-lab
sudo DOMAIN=test.secutrace.co.kr ./scripts/setup-nginx-exec-proxy.sh
```

The script writes `/etc/nginx/snippets/webshell-lab-exec-proxy.conf`, adds an include to `/etc/nginx/sites-available/webshell-detection-lab`, validates Nginx, and reloads it.

### Runtime Switching

PHP:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
```

```text
https://<server>/upload.html
https://<server>/exec/<file>.php
```

Node.js and Python CGI:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
```

```text
https://<server>/upload.html
https://<server>/exec/<file>.js
https://<server>/exec/<file>.py
```

JSP:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

```text
https://<server>/upload.html
https://<server>/jsp-exec/<file>.jsp
```

`LAB_PORT=8088` avoids a conflict when the system Tomcat service uses `8080`. The upload page is served by the embedded lab runtime on `8088`; uploaded JSP execution is served separately by the system Tomcat service on `8080` through:

```text
/var/lib/tomcat10/conf/Catalina/localhost/webshell-lab-jsp.xml
```

Tomcat 10 does not support `reload` as a systemd job type, so the setup script restarts Tomcat after creating or removing this context.

### Automatic Nginx Upload Page Upstream

When `LAB_AUTO_EXEC_HANDLER=1` is enabled, `switch-server.sh` also calls:

```bash
scripts/update-nginx-lab-upstream.sh
```

That script updates the root `location /` proxy in `/etc/nginx/sites-available/webshell-detection-lab` to the current `LAB_HOST:LAB_PORT`, validates with `nginx -t`, and reloads Nginx. This is what keeps `https://<server>/upload.html` pointing at the newly selected upload UI after every switch.

If you need to run the upload server on `0.0.0.0`, the Nginx upstream is normalized to `127.0.0.1`. Override it explicitly with:

```bash
LAB_NGINX_UPSTREAM_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

Disable only the Nginx upload-page upstream update with:

```bash
LAB_AUTO_NGINX_UPSTREAM=0 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
```

Manual update:

```bash
sudo LAB_UPSTREAM_HOST=127.0.0.1 LAB_UPSTREAM_PORT=8088 ./scripts/update-nginx-lab-upstream.sh
```

### Apache Binding

Apache-backed execution handlers bind to loopback by default:

```text
LAB_EXEC_HANDLER_HOST=127.0.0.1
LAB_EXEC_HANDLER_PORT=18080
```

That means direct external HTTP access to `:18080` is not required. Open only HTTPS `443` to trusted tester IP ranges.

If Apache fails with `Address already in use` for `:80`, another service such as Nginx is already using the public HTTP port. The execution handler should stay on `127.0.0.1:18080`; do not add a public Apache `Listen 80` for the handler.

### CGI Sample Format

Node.js CGI files need a Node shebang and an HTTP header. On some Apache CGI environments, Node/V8 can fail while allocating executable memory. Use `--jitless` for a stable benign CGI smoke test:

```js
#!/usr/bin/env -S node --jitless
console.log("Content-Type: text/plain\n");
console.log("node cgi ok");
```

Python CGI files need a Python shebang and an HTTP header:

```python
#!/usr/bin/env python3
print("Content-Type: text/plain\n")
print("python cgi ok")
```

If Apache returns `500` and the log contains `env: $'node\r': No such file or directory`, the uploaded file has Windows CRLF line endings. Convert it to LF:

```bash
sudo sed -i 's/\r$//' /opt/webshell-detection-lab/servers/node-express/uploads/test.js
curl -v http://127.0.0.1:18080/uploads/test.js
```

Check the CGI error log:

```bash
sudo tail -n 80 /var/log/apache2/webshell-lab-exec-node-error.log
sudo tail -n 80 /var/log/apache2/error.log
```

### ASP.NET Core

Linux ASP.NET Core does not execute uploaded `.cs`, `.cshtml`, `.asp`, or `.aspx` files as scripts. In this mode, the script disables the Apache/Tomcat lab execution handlers and prints a note. Use a separate Windows IIS lab for classic ASP or ASP.NET WebForms upload execution.

## 한국어

`LAB_AUTO_EXEC_HANDLER=1`은 런타임을 전환할 때 외부 스크립트 실행 핸들러를 함께 갱신합니다. Nginx 사이트 설정이 있으면 메인 업로드 페이지 upstream도 함께 바꿔서 `https://<server>/upload.html`이 현재 선택된 런타임을 바라보게 합니다.

HTTPS만 사용하려면 실행 핸들러는 loopback에만 열고 Nginx가 HTTPS로 프록시하게 구성합니다.

```text
https://<server>/upload.html          -> 현재 랩 런타임, 예: http://127.0.0.1:8088/upload.html
https://<server>/exec/<file>.php      -> http://127.0.0.1:18080/uploads/<file>.php
https://<server>/exec/<file>.js       -> http://127.0.0.1:18080/uploads/<file>.js
https://<server>/exec/<file>.py       -> http://127.0.0.1:18080/uploads/<file>.py
https://<server>/jsp-exec/<file>.jsp  -> http://127.0.0.1:8080/webshell-lab-jsp/<file>.jsp
```

이 랩은 웹쉘 샘플, 명령 실행 핸들러, 공격 페이로드를 제공하지 않습니다. 인가된 테스트 네트워크에서 정상 동작 확인용 파일만 사용하세요.

### 사전 준비

```bash
sudo apt update
sudo apt install -y apache2 libapache2-mod-php nodejs python3 nginx certbot python3-certbot-nginx
sudo a2enmod cgi
```

JSP는 Tomcat과 Java 21이 필요합니다.

```bash
sudo apt install -y tomcat10 openjdk-21-jdk
```

기존 Tomcat이 Java 17 등으로 실행 중이면 서비스에 Java 21을 지정하세요.

```bash
sudo mkdir -p /etc/systemd/system/tomcat10.service.d
printf '[Service]\nEnvironment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"\n' | sudo tee /etc/systemd/system/tomcat10.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart tomcat10
```

### HTTPS 프록시 1회 설정

도메인 SSL 설정 후 한 번 실행합니다.

```bash
cd /opt/webshell-detection-lab
sudo DOMAIN=test.secutrace.co.kr ./scripts/setup-nginx-exec-proxy.sh
```

### 런타임 전환

PHP:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
```

```text
https://<server>/upload.html
https://<server>/exec/<file>.php
```

Node.js와 Python CGI:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
```

```text
https://<server>/upload.html
https://<server>/exec/<file>.js
https://<server>/exec/<file>.py
```

JSP:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

```text
https://<server>/upload.html
https://<server>/jsp-exec/<file>.jsp
```

시스템 Tomcat이 `8080`을 쓰는 경우 embedded JSP 랩 서버는 `LAB_PORT=8088`로 피해서 실행하세요. 업로드 페이지는 `8088`의 랩 런타임이 제공하고, 업로드된 JSP 실행은 시스템 Tomcat `8080`이 아래 컨텍스트로 제공합니다.

```text
/var/lib/tomcat10/conf/Catalina/localhost/webshell-lab-jsp.xml
```

Tomcat 10은 systemd `reload` 작업을 지원하지 않으므로, 설정 스크립트는 컨텍스트 생성/삭제 후 Tomcat을 재시작합니다.

### Nginx 업로드 페이지 upstream 자동 전환

`LAB_AUTO_EXEC_HANDLER=1`이 켜져 있으면 `switch-server.sh`가 아래 스크립트도 함께 호출합니다.

```bash
scripts/update-nginx-lab-upstream.sh
```

이 스크립트는 `/etc/nginx/sites-available/webshell-detection-lab`의 root `location /` 프록시를 현재 `LAB_HOST:LAB_PORT`로 바꾸고, `nginx -t` 검증 후 Nginx를 reload합니다. 그래서 런타임을 바꿀 때마다 `https://<server>/upload.html`이 새 업로드 UI를 바라보게 됩니다.

업로드 서버를 `0.0.0.0`으로 실행해도 Nginx upstream은 `127.0.0.1`로 정규화됩니다. 명시적으로 바꾸려면 이렇게 실행하세요.

```bash
LAB_NGINX_UPSTREAM_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

Nginx 업로드 페이지 upstream 자동 변경만 끄려면:

```bash
LAB_AUTO_NGINX_UPSTREAM=0 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
```

수동 변경:

```bash
sudo LAB_UPSTREAM_HOST=127.0.0.1 LAB_UPSTREAM_PORT=8088 ./scripts/update-nginx-lab-upstream.sh
```

### 방화벽

Apache 실행 핸들러는 기본적으로 내부에만 바인딩됩니다.

```text
LAB_EXEC_HANDLER_HOST=127.0.0.1
LAB_EXEC_HANDLER_PORT=18080
```

따라서 외부에 `18080`을 열 필요가 없습니다. 테스트 IP에 대해 HTTPS `443`만 허용하는 구성을 권장합니다.

Apache 로그에 `Address already in use`와 `:80` 바인딩 오류가 나오면 Nginx 같은 기존 웹 서버가 이미 공인 HTTP 포트를 사용 중인 상태입니다. 실행 핸들러는 `127.0.0.1:18080`에만 두고, 공인 `Listen 80`을 추가하지 마세요.

### CGI 샘플 형식

Node.js CGI 파일은 Node shebang과 HTTP 헤더가 필요합니다. 일부 Apache CGI 환경에서는 Node/V8의 실행 메모리 할당 때문에 500 오류가 날 수 있으므로, 정상 동작 확인용 benign 샘플은 `--jitless`를 사용하세요.

```js
#!/usr/bin/env -S node --jitless
console.log("Content-Type: text/plain\n");
console.log("node cgi ok");
```

Python CGI 파일은 Python shebang과 HTTP 헤더가 필요합니다.

```python
#!/usr/bin/env python3
print("Content-Type: text/plain\n")
print("python cgi ok")
```

Apache 로그에 `env: $'node\r': No such file or directory`가 나오면 업로드한 파일이 Windows CRLF 줄바꿈입니다. LF로 변환하세요.

```bash
sudo sed -i 's/\r$//' /opt/webshell-detection-lab/servers/node-express/uploads/test.js
curl -v http://127.0.0.1:18080/uploads/test.js
```

오류 로그 확인:

```bash
sudo tail -n 80 /var/log/apache2/webshell-lab-exec-node-error.log
sudo tail -n 80 /var/log/apache2/error.log
```
