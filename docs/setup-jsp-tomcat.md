# JSP / Tomcat Runtime

## Start Embedded Tomcat

```bash
cd webshell-detection-lab
./scripts/switch-server.sh jsp
```

The switch script runs Maven with an embedded Tomcat launcher:

```bash
mvn -q compile exec:java -Dexec.mainClass=lab.EmbeddedTomcatServer -Dlab.port=8080
```

## Build WAR For External Tomcat

```bash
cd webshell-detection-lab/servers/jsp-tomcat
mvn package
```

The WAR is written to `servers/jsp-tomcat/target/webshell-lab.war`.

## Paths

- Uploads: `servers/jsp-tomcat/uploads`
- Logs: `servers/jsp-tomcat/logs/upload-events.jsonl`
