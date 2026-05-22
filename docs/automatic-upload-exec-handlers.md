# Automatic Upload Execution Handlers / 업로드 실행 핸들러 자동 전환

## English

`LAB_AUTO_EXEC_HANDLER=1` is an explicit lab-only mode that updates the external script execution handler when you switch runtimes.

The normal lab runtime still serves the main site and upload page on `LAB_PORT`, which defaults to `8080`. The execution handler is exposed separately on `LAB_EXEC_HANDLER_PORT`, which defaults to `18080`, for Apache-backed handlers.

```bash
cd /opt/webshell-detection-lab
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
```

When `LAB_AUTO_EXEC_HANDLER=1` is set, `switch-server.sh` also enables executable upload permissions by setting `LAB_UPLOAD_EXECUTABLE=1` if you did not set it yourself.

### Prerequisites

For PHP, Node.js CGI, and Python CGI handlers:

```bash
sudo apt update
sudo apt install -y apache2 libapache2-mod-php nodejs python3
sudo a2enmod cgi
```

For JSP handlers:

```bash
sudo apt update
sudo apt install -y tomcat9
```

Keep the handler ports restricted to trusted tester IP ranges with firewall, VPN, reverse proxy policy, or cloud security group rules.

### PHP

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
```

Upload through the lab page:

```text
http://<server>:8080/upload.html
```

The Apache PHP execution endpoint is:

```text
http://<server>:18080/uploads/<file>.php
```

The script creates and enables `/etc/apache2/sites-available/webshell-lab-exec-php.conf`, disables the other lab execution sites, runs `apache2ctl configtest`, and reloads Apache.

### Node.js and Python CGI

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
```

Upload through the lab page:

```text
http://<server>:8080/upload.html
```

The Apache CGI execution endpoint is:

```text
http://<server>:18080/uploads/<file>.js
http://<server>:18080/uploads/<file>.py
```

Node.js CGI test samples need a Node shebang. Python CGI test samples need a Python shebang. The lab does not provide sample payloads.

The script creates and enables `/etc/apache2/sites-available/webshell-lab-exec-node.conf`, enables Apache `cgi`, disables the other lab execution sites, runs `apache2ctl configtest`, and reloads Apache.

### JSP

```bash
LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

Using `LAB_PORT=8088` avoids a conflict when the system Tomcat service is already listening on `8080`.

Upload through the embedded JSP lab runtime:

```text
http://<server>:8088/upload.html
```

The system Tomcat JSP execution endpoint is usually:

```text
http://<server>:8080/webshell-lab-jsp/<file>.jsp
```

The script writes a Tomcat context named `webshell-lab-jsp` that points at `servers/jsp-tomcat/uploads`, disables the Apache lab execution sites, and reloads or restarts Tomcat.

If your Tomcat service name or context path differs, override it:

```bash
LAB_TOMCAT_SERVICE=tomcat10 LAB_TOMCAT_CONTEXT_NAME=webshell-lab-jsp LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

### ASP.NET Core

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh aspnet
```

Linux ASP.NET Core does not execute uploaded `.cs`, `.cshtml`, `.asp`, or `.aspx` files as scripts. In this mode, the script disables the Apache/Tomcat lab execution handlers and prints a note. Use a separate Windows IIS lab for classic ASP or ASP.NET WebForms upload execution.

### Custom Port

Use a different Apache handler port when `18080` is not suitable:

```bash
LAB_EXEC_HANDLER_PORT=19080 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
```

Then use:

```text
http://<server>:19080/uploads/<file>.php
```

## 한국어

`LAB_AUTO_EXEC_HANDLER=1`은 런타임을 전환할 때 외부 스크립트 실행 핸들러를 함께 갱신하는 랩 전용 명시적 옵션입니다.

기본 랩 런타임은 기존처럼 `LAB_PORT`에서 메인 사이트와 업로드 페이지를 제공합니다. 기본값은 `8080`입니다. Apache 기반 실행 핸들러는 별도 포트인 `LAB_EXEC_HANDLER_PORT`에서 열리며 기본값은 `18080`입니다.

```bash
cd /opt/webshell-detection-lab
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
```

`LAB_AUTO_EXEC_HANDLER=1`을 사용하면 `switch-server.sh`는 사용자가 직접 `LAB_UPLOAD_EXECUTABLE`을 지정하지 않은 경우 자동으로 `LAB_UPLOAD_EXECUTABLE=1`을 설정합니다.

### 사전 준비

PHP, Node.js CGI, Python CGI 핸들러:

```bash
sudo apt update
sudo apt install -y apache2 libapache2-mod-php nodejs python3
sudo a2enmod cgi
```

JSP 핸들러:

```bash
sudo apt update
sudo apt install -y tomcat9
```

핸들러 포트는 방화벽, VPN, 리버스 프록시 정책, 클라우드 보안 그룹 등으로 신뢰된 테스트 IP에만 허용하세요.

### PHP

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
```

업로드 페이지:

```text
http://<server>:8080/upload.html
```

Apache PHP 실행 엔드포인트:

```text
http://<server>:18080/uploads/<file>.php
```

스크립트는 `/etc/apache2/sites-available/webshell-lab-exec-php.conf`를 생성/활성화하고, 다른 랩 실행 사이트를 비활성화한 뒤 `apache2ctl configtest`를 실행하고 Apache를 reload합니다.

### Node.js와 Python CGI

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh node
```

업로드 페이지:

```text
http://<server>:8080/upload.html
```

Apache CGI 실행 엔드포인트:

```text
http://<server>:18080/uploads/<file>.js
http://<server>:18080/uploads/<file>.py
```

Node.js CGI 테스트 샘플에는 Node shebang이 필요합니다. Python CGI 테스트 샘플에는 Python shebang이 필요합니다. 이 랩은 샘플 페이로드를 제공하지 않습니다.

### JSP

```bash
LAB_PORT=8088 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh jsp
```

시스템 Tomcat 서비스가 이미 `8080`을 사용 중인 경우 충돌을 피하기 위해 `LAB_PORT=8088`을 권장합니다.

업로드 페이지:

```text
http://<server>:8088/upload.html
```

시스템 Tomcat JSP 실행 엔드포인트는 보통 다음과 같습니다.

```text
http://<server>:8080/webshell-lab-jsp/<file>.jsp
```

스크립트는 `servers/jsp-tomcat/uploads`를 가리키는 `webshell-lab-jsp` Tomcat context를 생성하고, Apache 랩 실행 사이트를 비활성화한 뒤 Tomcat을 reload 또는 restart합니다.

### ASP.NET Core

```bash
LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh aspnet
```

Linux ASP.NET Core는 업로드된 `.cs`, `.cshtml`, `.asp`, `.aspx` 파일을 스크립트처럼 실행하지 않습니다. 이 모드에서는 Apache/Tomcat 랩 실행 핸들러를 비활성화하고 안내 메시지만 출력합니다. classic ASP 또는 ASP.NET WebForms 업로드 실행은 별도의 Windows IIS 랩에서 테스트하세요.

### 포트 변경

`18080` 대신 다른 Apache 핸들러 포트를 사용하려면 다음처럼 지정합니다.

```bash
LAB_EXEC_HANDLER_PORT=19080 LAB_AUTO_EXEC_HANDLER=1 ./scripts/switch-server.sh php
```
