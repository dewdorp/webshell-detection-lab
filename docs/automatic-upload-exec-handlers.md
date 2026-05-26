# Automatic Upload Execution Handlers / 업로드 실행 핸들러 자동 전환

## English

`LAB_AUTO_EXEC_HANDLER=1` updates the external script execution handler when you switch runtimes. If the Nginx site config exists, it also refreshes an isolated lab upload UI proxy without replacing your original website root.

```text
https://<server>/                    -> your original website
https://<server>/upload.html         -> redirects to /lab-upload/upload.html
https://<server>/lab-upload/upload.html -> active lab upload UI
https://<server>/exec/<file>.php     -> http://127.0.0.1:18080/uploads/<file>.php
https://<server>/exec/<file>.js      -> http://127.0.0.1:18080/uploads/<file>.js
https://<server>/exec/<file>.py      -> http://127.0.0.1:18080/uploads/<file>.py
https://<server>/jsp-exec/<file>.jsp -> http://127.0.0.1:8080/webshell-lab-jsp/<file>.jsp
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

### Runtime Switching

PHP:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
```

Node.js and Python CGI:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
```

JSP:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

`LAB_PORT=8088` avoids a conflict when the system Tomcat service uses `8080`. The upload page is served by the embedded lab runtime on `8088`; uploaded JSP execution is served separately by the system Tomcat service on `8080` through:

```text
/var/lib/tomcat10/conf/Catalina/localhost/webshell-lab-jsp.xml
```

Tomcat 10 does not support `reload` as a systemd job type, so the setup script restarts Tomcat after creating or removing this context.

### Automatic Nginx Upload UI Proxy

When `LAB_AUTO_EXEC_HANDLER=1` is enabled, `switch-server.sh` also calls:

```bash
scripts/update-nginx-lab-upstream.sh
```

That script writes `/etc/nginx/snippets/webshell-lab-upload-ui.conf`, includes it in `/etc/nginx/sites-available/webshell-detection-lab`, validates with `nginx -t`, and reloads Nginx. It preserves the existing root `location /`, so your original website continues to load at `https://<server>/`.

The upload UI is exposed at:

```text
https://<server>/lab-upload/upload.html
```

For compatibility, `/upload.html` redirects to `/lab-upload/upload.html`.

If you need to run the upload server on `0.0.0.0`, the Nginx upstream is normalized to `127.0.0.1`. Override it explicitly with:

```bash
LAB_NGINX_UPSTREAM_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

Disable only the Nginx upload UI proxy update with:

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

`LAB_AUTO_EXEC_HANDLER=1`은 런타임을 전환할 때 외부 스크립트 실행 핸들러를 함께 갱신합니다. Nginx 사이트 설정이 있으면 기존 웹사이트 루트는 유지하고, 랩 업로드 UI만 별도 prefix로 프록시합니다.

```text
https://<server>/                    -> 기존 웹사이트
https://<server>/upload.html         -> /lab-upload/upload.html 로 리다이렉트
https://<server>/lab-upload/upload.html -> 현재 랩 업로드 UI
https://<server>/exec/<file>.php     -> http://127.0.0.1:18080/uploads/<file>.php
https://<server>/exec/<file>.js      -> http://127.0.0.1:18080/uploads/<file>.js
https://<server>/exec/<file>.py      -> http://127.0.0.1:18080/uploads/<file>.py
https://<server>/jsp-exec/<file>.jsp -> http://127.0.0.1:8080/webshell-lab-jsp/<file>.jsp
```

이 랩은 웹쉘 샘플, 명령 실행 핸들러, 공격 페이로드를 제공하지 않습니다. 인가된 테스트 네트워크에서 정상 동작 확인용 파일만 사용하세요.

### 런타임 전환

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
LAB_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

JSP는 Tomcat과 Java 21이 필요합니다.

```bash
sudo apt install -y tomcat10 openjdk-21-jdk
```

Java 버전 오류가 나면:

```bash
sudo mkdir -p /etc/systemd/system/tomcat10.service.d
printf '[Service]\nEnvironment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"\n' | sudo tee /etc/systemd/system/tomcat10.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart tomcat10
```

JSP 실행 컨텍스트는 보통 아래 파일로 시스템 Tomcat에 연결됩니다.

```text
/var/lib/tomcat10/conf/Catalina/localhost/webshell-lab-jsp.xml
```

### Nginx 업로드 UI 프록시 자동 전환

`switch-server.sh`는 아래 스크립트를 호출해 `/etc/nginx/snippets/webshell-lab-upload-ui.conf`를 갱신합니다.

```bash
scripts/update-nginx-lab-upstream.sh
```

이 방식은 `/etc/nginx/sites-available/webshell-detection-lab`의 기존 root `location /`를 바꾸지 않습니다. 따라서 `https://<server>/`에는 원래 웹사이트가 계속 뜨고, 업로드 UI는 아래 주소에서 사용합니다.

```text
https://<server>/lab-upload/upload.html
```

기존 편의를 위해 `/upload.html`은 `/lab-upload/upload.html`로 리다이렉트됩니다.

수동 변경:

```bash
sudo LAB_UPSTREAM_HOST=127.0.0.1 LAB_UPSTREAM_PORT=8088 ./scripts/update-nginx-lab-upstream.sh
```

### CGI 샘플 형식

Node.js CGI 정상 확인용 샘플:

```js
#!/usr/bin/env -S node --jitless
console.log("Content-Type: text/plain\n");
console.log("node cgi ok");
```

Python CGI 정상 확인용 샘플:

```python
#!/usr/bin/env python3
print("Content-Type: text/plain\n")
print("python cgi ok")
```

Apache 로그에 `env: $'node\r': No such file or directory`가 나오면 업로드한 파일이 Windows CRLF 줄바꿈입니다. LF로 변환하세요.

```bash
sudo sed -i 's/\r$//' /opt/webshell-detection-lab/servers/node-express/uploads/test.js
```
