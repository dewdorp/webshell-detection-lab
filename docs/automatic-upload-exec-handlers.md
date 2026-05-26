# Automatic Upload Execution Handlers / 업로드 실행 핸들러 자동 전환

## English

`LAB_AUTO_EXEC_HANDLER=1` updates the external script execution handler when you switch runtimes. For HTTPS-only testing, keep the execution handlers on loopback and expose them through Nginx:

```text
https://<server>/exec/<file>.php  -> http://127.0.0.1:18080/uploads/<file>.php
https://<server>/exec/<file>.js   -> http://127.0.0.1:18080/uploads/<file>.js
https://<server>/exec/<file>.py   -> http://127.0.0.1:18080/uploads/<file>.py
https://<server>/jsp-exec/<file>.jsp -> http://127.0.0.1:8080/webshell-lab-jsp/<file>.jsp
```

### Prerequisites

```bash
sudo apt update
sudo apt install -y apache2 libapache2-mod-php nodejs python3 nginx certbot python3-certbot-nginx
sudo a2enmod cgi
```

For JSP:

```bash
sudo apt install -y tomcat9
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
https://<server>/exec/<file>.php
```

Node.js and Python CGI:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
```

```text
https://<server>/exec/<file>.js
https://<server>/exec/<file>.py
```

JSP:

```bash
LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

```text
https://<server>/jsp-exec/<file>.jsp
```

`LAB_PORT=8088` avoids a conflict when the system Tomcat service uses `8080`.

### Apache Binding

Apache-backed execution handlers bind to loopback by default:

```text
LAB_EXEC_HANDLER_HOST=127.0.0.1
LAB_EXEC_HANDLER_PORT=18080
```

That means direct external HTTP access to `:18080` is not required. Open only HTTPS `443` to trusted tester IP ranges.

### CGI Sample Format

Node.js CGI files need a Node shebang and an HTTP header:

```js
#!/usr/bin/env node
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

The lab does not provide webshell samples, command execution handlers, or exploit payloads.

### ASP.NET Core

Linux ASP.NET Core does not execute uploaded `.cs`, `.cshtml`, `.asp`, or `.aspx` files as scripts. In this mode, the script disables the Apache/Tomcat lab execution handlers and prints a note. Use a separate Windows IIS lab for classic ASP or ASP.NET WebForms upload execution.

## 한국어

`LAB_AUTO_EXEC_HANDLER=1`은 런타임을 전환할 때 외부 스크립트 실행 핸들러를 함께 갱신합니다. HTTPS만 사용하려면 실행 핸들러는 loopback에만 열고 Nginx가 HTTPS로 프록시하게 구성합니다.

```text
https://<server>/exec/<file>.php  -> http://127.0.0.1:18080/uploads/<file>.php
https://<server>/exec/<file>.js   -> http://127.0.0.1:18080/uploads/<file>.js
https://<server>/exec/<file>.py   -> http://127.0.0.1:18080/uploads/<file>.py
https://<server>/jsp-exec/<file>.jsp -> http://127.0.0.1:8080/webshell-lab-jsp/<file>.jsp
```

### 사전 준비

```bash
sudo apt update
sudo apt install -y apache2 libapache2-mod-php nodejs python3 nginx certbot python3-certbot-nginx
sudo a2enmod cgi
```

JSP는 Tomcat이 필요합니다.

```bash
sudo apt install -y tomcat9
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
https://<server>/exec/<file>.php
```

Node.js와 Python CGI:

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
```

```text
https://<server>/exec/<file>.js
https://<server>/exec/<file>.py
```

JSP:

```bash
LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

```text
https://<server>/jsp-exec/<file>.jsp
```

시스템 Tomcat이 `8080`을 쓰는 경우 embedded JSP 랩 서버는 `LAB_PORT=8088`로 피해서 실행하세요.

### 방화벽

Apache 실행 핸들러는 기본적으로 내부에만 바인딩됩니다.

```text
LAB_EXEC_HANDLER_HOST=127.0.0.1
LAB_EXEC_HANDLER_PORT=18080
```

따라서 외부에는 `18080`을 열 필요가 없습니다. 테스트 IP에 대해 HTTPS `443`만 허용하는 구성을 권장합니다.

### CGI 500 오류 확인

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
