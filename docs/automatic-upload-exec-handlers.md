# Automatic Upload Execution Handlers / 업로드 실행 핸들러 자동 전환

## English

`switch-server.sh` updates the Nginx root upstream to the active lab portal when `/etc/nginx/sites-available/webshell-detection-lab` exists. `LAB_AUTO_EXEC_HANDLER=1` additionally updates the external script execution handler.

```text
https://<server>/                    -> active lab portal
https://<server>/upload.html         -> active lab upload page
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

For JSP on current Ubuntu/Tomcat 10 systems:

```bash
sudo apt install -y tomcat10 openjdk-21-jdk
```

If Tomcat was already installed with an older Java runtime:

```bash
sudo mkdir -p /etc/systemd/system/tomcat10.service.d
printf '[Service]\nEnvironment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"\n' | sudo tee /etc/systemd/system/tomcat10.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart tomcat10
```

### Runtime Switching

Node/PHP use `8080` for the public lab portal:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh php
```

JSP uses `8088` for the public lab portal because system Tomcat commonly owns `8080` for uploaded JSP execution:

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

The JSP execution context is served by system Tomcat through:

```text
/var/lib/tomcat10/conf/Catalina/localhost/webshell-lab-jsp.xml
```

Tomcat 10 does not support `reload` as a systemd job type, so the setup script restarts Tomcat after creating or removing this context.

### Nginx Root Upstream Switching

`switch-server.sh` calls:

```bash
scripts/update-nginx-lab-upstream.sh
```

That script updates the root `location /` proxy in `/etc/nginx/sites-available/webshell-detection-lab` to the active `LAB_HOST:LAB_PORT`, removes the legacy `/lab-upload/` snippet if present, validates with `nginx -t`, and reloads Nginx.

Disable only the Nginx root upstream update with:

```bash
LAB_AUTO_NGINX_UPSTREAM=0 ./scripts/switch-server.sh node
```

Manual update:

```bash
sudo LAB_UPSTREAM_HOST=127.0.0.1 LAB_UPSTREAM_PORT=8080 ./scripts/update-nginx-lab-upstream.sh
sudo LAB_UPSTREAM_HOST=127.0.0.1 LAB_UPSTREAM_PORT=8088 ./scripts/update-nginx-lab-upstream.sh
```

### HTTPS Execution Proxy

Run once after Nginx/SSL is configured for your domain:

```bash
cd /opt/webshell-detection-lab
sudo DOMAIN=test.secutrace.co.kr ./scripts/setup-nginx-exec-proxy.sh
```

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
```

## 한국어

`switch-server.sh`는 `/etc/nginx/sites-available/webshell-detection-lab`가 있으면 Nginx 루트 upstream을 현재 선택한 랩 포탈로 바꿉니다. `LAB_AUTO_EXEC_HANDLER=1`은 여기에 더해 업로드 실행 핸들러도 함께 갱신합니다.

```text
https://<server>/                    -> 현재 랩 포탈
https://<server>/upload.html         -> 현재 랩 업로드 페이지
https://<server>/exec/<file>.php     -> http://127.0.0.1:18080/uploads/<file>.php
https://<server>/exec/<file>.js      -> http://127.0.0.1:18080/uploads/<file>.js
https://<server>/exec/<file>.py      -> http://127.0.0.1:18080/uploads/<file>.py
https://<server>/jsp-exec/<file>.jsp -> http://127.0.0.1:8080/webshell-lab-jsp/<file>.jsp
```

Node/PHP 포탈은 `8080`을 씁니다.

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh node
LAB_HOST=127.0.0.1 LAB_PORT=8080 ./scripts/switch-server.sh php
```

JSP는 시스템 Tomcat이 `8080`을 쓰므로 포탈은 `8088`로 띄웁니다.

```bash
LAB_HOST=127.0.0.1 LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

따라서 JSP 구조는 이렇게 나뉩니다.

```text
/             -> 127.0.0.1:8088, JSP 업로드 포탈
/jsp-exec/    -> 127.0.0.1:8080/webshell-lab-jsp/, 업로드된 JSP 실행
```

`update-nginx-lab-upstream.sh`는 이전 `/lab-upload/` snippet이 있으면 삭제하고, root `location /`의 `proxy_pass`를 현재 포트로 바꿉니다.

수동 변경:

```bash
sudo LAB_UPSTREAM_HOST=127.0.0.1 LAB_UPSTREAM_PORT=8080 ./scripts/update-nginx-lab-upstream.sh
sudo LAB_UPSTREAM_HOST=127.0.0.1 LAB_UPSTREAM_PORT=8088 ./scripts/update-nginx-lab-upstream.sh
```

Node CGI 정상 확인용 샘플:

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
