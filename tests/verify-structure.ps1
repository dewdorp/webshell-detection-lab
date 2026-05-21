$ErrorActionPreference = 'Stop'

$Root = Resolve-Path (Join-Path $PSScriptRoot '..')

function Assert-Exists {
    param([string]$Path)
    $FullPath = Join-Path $Root $Path
    if (-not (Test-Path -LiteralPath $FullPath)) {
        throw "Missing required path: $Path"
    }
    Write-Host "[ok] $Path"
}

function Assert-Contains {
    param([string]$Path, [string]$Pattern)
    $FullPath = Join-Path $Root $Path
    $Content = Get-Content -LiteralPath $FullPath -Raw
    if ($Content -notmatch [regex]::Escape($Pattern)) {
        throw "Expected '$Path' to contain '$Pattern'"
    }
    Write-Host "[ok] $Path contains $Pattern"
}

$requiredPaths = @(
    'README.md','install.sh','common/public/app.js','common/public/styles.css','common/templates/index.html',
    'scripts/check-prereqs.sh','scripts/stop-server.sh','scripts/switch-server.sh','scripts/reset-uploads.sh','scripts/setup-nginx-ssl.sh',
    'servers/node-express/package.json','servers/node-express/server.js','servers/node-express/uploads/.gitkeep','servers/node-express/logs/.gitkeep',
    'servers/php-apache/index.php','servers/php-apache/uploads/.gitkeep','servers/php-apache/logs/.gitkeep',
    'servers/jsp-tomcat/pom.xml','servers/jsp-tomcat/src/main/java/lab/EmbeddedTomcatServer.java','servers/jsp-tomcat/src/main/java/lab/UploadServlet.java','servers/jsp-tomcat/src/main/webapp/WEB-INF/web.xml','servers/jsp-tomcat/uploads/.gitkeep','servers/jsp-tomcat/logs/.gitkeep',
    'servers/aspnet-core/WebshellLab.AspNetCore.csproj','servers/aspnet-core/Program.cs','servers/aspnet-core/uploads/.gitkeep','servers/aspnet-core/logs/.gitkeep',
    'docs/linux-setup.md','docs/external-server-install.md','docs/technology-stack.md','docs/webshell-detection-poc.md','docs/setup-node.md','docs/setup-php-apache.md','docs/setup-jsp-tomcat.md','docs/setup-aspnet-core.md','docs/design.md'
)

foreach ($path in $requiredPaths) { Assert-Exists $path }
foreach ($runtime in @('node','php','jsp','aspnet')) { Assert-Contains 'scripts/switch-server.sh' "$runtime)" }
foreach ($route in @('/health','/upload','/files')) {
    Assert-Contains 'servers/node-express/server.js' $route
    Assert-Contains 'servers/php-apache/index.php' $route
    Assert-Contains 'servers/jsp-tomcat/src/main/java/lab/UploadServlet.java' $route
    Assert-Contains 'servers/aspnet-core/Program.cs' $route
}

foreach ($name in @('samples','payloads','reverse-shells','webshells')) {
    $matches = Get-ChildItem -LiteralPath $Root -Recurse -Force | Where-Object { $_.PSIsContainer -and $_.Name -ieq $name }
    if ($matches) { throw "Forbidden bundled sample/payload directory found: $($matches[0].FullName)" }
}

Write-Host 'Structure verification passed.'
