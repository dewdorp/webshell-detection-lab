# Executable Upload Permissions / 업로드 실행 권한

## English

`LAB_UPLOAD_EXECUTABLE=1` is an explicit lab-only mode for environments where you want uploaded test samples to have executable file-system permissions.

```bash
cd /opt/webshell-detection-lab
LAB_UPLOAD_EXECUTABLE=1 ./scripts/switch-server.sh php
```

When enabled, the lab applies `0775` to:

- the active runtime upload directory
- each file saved through the upload endpoint
- upload directories recreated by `scripts/reset-uploads.sh`

Example reset command:

```bash
LAB_UPLOAD_EXECUTABLE=1 ./scripts/reset-uploads.sh
```

This setting does not make uploaded files execute by itself. Your web server or runtime must still have the matching script handler enabled for the upload path, such as Apache/PHP-FPM, Tomcat/JSP, Node.js, Python, or another handler appropriate for your controlled test. Keep the lab restricted to trusted testers by firewall, VPN, reverse proxy policy, or cloud security group rules.

The lab still does not include webshell samples, reverse shells, payload generators, command execution handlers, or automatic script-execution routing for uploaded files.

## 한국어

`LAB_UPLOAD_EXECUTABLE=1`은 업로드된 테스트 샘플에 파일 시스템 실행 권한을 부여해야 하는 통제된 랩 환경에서만 켜는 명시적 옵션입니다.

```bash
cd /opt/webshell-detection-lab
LAB_UPLOAD_EXECUTABLE=1 ./scripts/switch-server.sh php
```

활성화하면 랩은 다음 경로에 `0775` 권한을 적용합니다.

- 활성 런타임의 업로드 디렉터리
- 업로드 엔드포인트를 통해 저장된 각 파일
- `scripts/reset-uploads.sh`로 다시 생성된 업로드 디렉터리

초기화 예시는 다음과 같습니다.

```bash
LAB_UPLOAD_EXECUTABLE=1 ./scripts/reset-uploads.sh
```

이 설정은 파일 시스템 권한만 변경합니다. 업로드 경로에서 스크립트를 실제로 실행하려면 Apache/PHP-FPM, Tomcat/JSP, Node.js, Python 등 테스트 목적에 맞는 서버 측 스크립트 핸들러가 별도로 활성화되어 있어야 합니다. 랩 접근은 방화벽, VPN, 리버스 프록시 정책, 클라우드 보안 그룹 등을 사용해 신뢰된 테스트 사용자에게만 제한하세요.

이 랩은 웹쉘 샘플, 리버스 셸, 페이로드 생성기, 명령 실행 핸들러, 업로드 파일 자동 실행 라우팅을 포함하지 않습니다.
