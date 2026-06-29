param(
    [string]$ClientPath = "$env:USERPROFILE\Tibiafriends",
    [string]$ServerPath = "C:\otserv",
    [string]$WebPath = "C:\xampp\htdocs",
    [string]$XamppPath = "C:\xampp",
    [string]$OutputRoot = "C:\tmp\TibiaRemastered-Packages",
    [switch]$IncludeClient
)

$ErrorActionPreference = "Stop"

function Copy-Filtered {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [string[]]$ExcludeDirs = @(),
        [string[]]$ExcludeFiles = @()
    )

    if (-not (Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null

    $args = @($Source, $Destination, "/E", "/R:1", "/W:1", "/NFL", "/NDL", "/NP", "/NJH", "/NJS")
    if ($ExcludeDirs.Count -gt 0) { $args += "/XD"; $args += $ExcludeDirs }
    if ($ExcludeFiles.Count -gt 0) { $args += "/XF"; $args += $ExcludeFiles }

    & robocopy @args | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "Robocopy failed from $Source to $Destination with exit code $LASTEXITCODE" }
}

function Write-TextFile {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$packageName = "TibiaRemastered-Friends-$stamp"
$stage = Join-Path $OutputRoot $packageName
$zip = Join-Path $OutputRoot "$packageName.zip"

if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

$commonExcludeDirs = @(".git", ".github", ".agents", ".codex", "Logs", "logs", "log", "Backup", "Backups", "backup", "backups", "cache", "Cache", "tmp", "temp", "crashdump", "screenshots", "Saves", "saves", "UserData", "userdata", "characterdata", "minimap")
$commonExcludeFiles = @("*.log", "*.bak", "*.tmp", "*.cache", "*.dump", "*.db", "*.sqlite", "*.sqlite3", "*.pem", "*.key", "*.token", "*.secret", ".env", "*password*", "*secret*", "*token*", "crystalserver.pdb")

Write-Host "Building friend package at $stage"
Copy-Filtered -Source $ServerPath -Destination (Join-Path $stage "Server") -ExcludeDirs $commonExcludeDirs -ExcludeFiles ($commonExcludeFiles + @("otserv.sql", "schema.sql"))
$runtimeRoot = Join-Path $stage "Runtime\xampp"
Copy-Filtered -Source (Join-Path $XamppPath "apache") -Destination (Join-Path $runtimeRoot "apache") -ExcludeDirs ($commonExcludeDirs + @("logs")) -ExcludeFiles $commonExcludeFiles
Copy-Filtered -Source (Join-Path $XamppPath "php") -Destination (Join-Path $runtimeRoot "php") -ExcludeDirs $commonExcludeDirs -ExcludeFiles $commonExcludeFiles
Copy-Filtered -Source (Join-Path $XamppPath "mysql") -Destination (Join-Path $runtimeRoot "mysql") -ExcludeDirs ($commonExcludeDirs + @("data")) -ExcludeFiles ($commonExcludeFiles + @("*.err", "*.pid"))
if (Test-Path -LiteralPath (Join-Path $XamppPath "mysql\backup")) {
    Copy-Filtered -Source (Join-Path $XamppPath "mysql\backup") -Destination (Join-Path $runtimeRoot "mysql\data") -ExcludeDirs $commonExcludeDirs -ExcludeFiles $commonExcludeFiles
}
Copy-Filtered -Source $WebPath -Destination (Join-Path $runtimeRoot "htdocs") -ExcludeDirs ($commonExcludeDirs + @("install")) -ExcludeFiles ($commonExcludeFiles + @("config.local.php"))
Copy-Filtered -Source $WebPath -Destination (Join-Path $stage "Web\htdocs") -ExcludeDirs ($commonExcludeDirs + @("install")) -ExcludeFiles ($commonExcludeFiles + @("config.local.php"))
Copy-Filtered -Source (Split-Path -Parent $PSScriptRoot) -Destination $stage -ExcludeDirs ($commonExcludeDirs + @("Tools", "Client", "Server", "Web", "Runtime", "DatabaseTemplate", "Database_Template", "Data", "UserData", "Logs", "Backup", "Backups")) -ExcludeFiles $commonExcludeFiles
$portableConfig = [pscustomobject]@{
    remoteVersionUrl = ""
    remoteManifestUrl = ""
    serverExe = "{ROOT}\Server\crystalserver.exe"
    serverWorkingDirectory = "{ROOT}\Server"
    serverPorts = @(7171, 7172)
    serverStartupTimeoutSeconds = 300
    clientExe = "{ROOT}\Client\bin\client-local.exe"
    clientWorkingDirectory = "{ROOT}\Client"
    databaseExe = "{ROOT}\Runtime\xampp\mysql\bin\mysqld.exe"
    databaseArguments = "--defaults-file=`"{ROOT}\Runtime\xampp\mysql\bin\my.ini`""
    databaseWorkingDirectory = "{ROOT}\Runtime\xampp\mysql\bin"
    databasePort = 3306
    databaseStartupTimeoutSeconds = 60
    webServerExe = "{ROOT}\Runtime\xampp\apache\bin\httpd.exe"
    webServerArguments = ""
    webServerWorkingDirectory = "{ROOT}\Runtime\xampp\apache\bin"
    webServerPort = 80
    webServerStartupTimeoutSeconds = 30
    preserve = @("UserData/**", "Logs/**", "Backup/**")
}
New-Item -ItemType Directory -Force -Path (Join-Path $stage "Config") | Out-Null
$portableConfig | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $stage "Config\launcher-config.json") -Encoding UTF8

if ($IncludeClient) {
    Copy-Filtered -Source $ClientPath -Destination (Join-Path $stage "Client") -ExcludeDirs $commonExcludeDirs -ExcludeFiles $commonExcludeFiles
} else {
    Write-TextFile -Path (Join-Path $stage "Client\COLOQUE-O-CLIENT-AQUI.txt") -Content "Coloque aqui os arquivos do client Tibia Remastered antes de rodar Scripts\Install-FriendPackage.ps1."
}

$dbDir = Join-Path $stage "DatabaseTemplate"
New-Item -ItemType Directory -Force -Path $dbDir | Out-Null
$schemaDump = Join-Path $dbDir "otserv-schema-clean.sql"
$mysqlDump = "C:\xampp\mysql\bin\mysqldump.exe"
if (Test-Path -LiteralPath $mysqlDump) {
    & $mysqlDump -uroot --no-data --routines --events --triggers otserv | Set-Content -Path $schemaDump -Encoding UTF8
} elseif (Test-Path -LiteralPath (Join-Path $ServerPath "schema.sql")) {
    Copy-Item -LiteralPath (Join-Path $ServerPath "schema.sql") -Destination $schemaDump -Force
} else {
    Write-TextFile -Path $schemaDump -Content "-- Database schema template was not generated. Install XAMPP/MySQL and import your clean schema manually."
}

$installScript = @"
param(
    [string]`$InstallRoot = "C:\",
    [switch]`$SkipDatabase
)

`$ErrorActionPreference = "Stop"
`$packageRoot = Split-Path -Parent `$PSScriptRoot

function Copy-Dir(`$Source, `$Destination) {
    if (-not (Test-Path -LiteralPath `$Source)) { return }
    New-Item -ItemType Directory -Force -Path `$Destination | Out-Null
    robocopy `$Source `$Destination /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS | Out-Null
    if (`$LASTEXITCODE -gt 7) { throw "Failed copying `$Source to `$Destination" }
}

Copy-Dir (Join-Path `$packageRoot "Server") "C:\otserv"
Copy-Dir (Join-Path `$packageRoot "Web\htdocs") "C:\xampp\htdocs"

`$clientSource = Join-Path `$packageRoot "Client"
if (Test-Path -LiteralPath (Join-Path `$clientSource "bin\client-local.exe")) {
    Copy-Dir `$clientSource "`$env:USERPROFILE\Tibiafriends"
} else {
    Write-Host "Client was not included in this package. Put the client at `$env:USERPROFILE\Tibiafriends."
}

if (-not `$SkipDatabase) {
    `$mysql = "C:\xampp\mysql\bin\mysql.exe"
    `$schema = Join-Path `$packageRoot "DatabaseTemplate\otserv-schema-clean.sql"
    if ((Test-Path -LiteralPath `$mysql) -and (Test-Path -LiteralPath `$schema)) {
        & `$mysql -uroot -e "CREATE DATABASE IF NOT EXISTS otserv CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        Get-Content -LiteralPath `$schema | & `$mysql -uroot otserv
    } else {
        Write-Host "Database import skipped because mysql.exe or schema file was not found."
    }
}

Write-Host "Installation finished. Open Launcher\Start Launcher.bat and click Jogar."
"@
Write-TextFile -Path (Join-Path $stage "Scripts\Install-FriendPackage.ps1") -Content $installScript

$readme = @"
Tibia Remastered - pacote portatil para amigos

Como jogar:
1. Extraia este ZIP em uma pasta simples, por exemplo C:\TibiaRemastered-Friends.
2. Abra Start Launcher.bat.
3. Clique em Jogar.

O launcher inicia automaticamente:
- MySQL portatil em Runtime\xampp\mysql
- Apache/PHP portatil em Runtime\xampp\apache
- Servidor em Server\crystalserver.exe
- Client em Client\bin\client-local.exe

Na primeira execucao, o launcher cria/importa o banco local limpo a partir de DatabaseTemplate\otserv-schema-clean.sql.

Este pacote nao inclui contas reais, personagens reais, senhas, tokens, logs, backups ou banco real.
"@
Write-TextFile -Path (Join-Path $stage "LEIA-ME-PRIMEIRO.txt") -Content $readme

if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
$tar = Get-Command tar.exe -ErrorAction SilentlyContinue
if ($tar) {
    Push-Location $stage
    try { & $tar.Source -a -cf $zip . } finally { Pop-Location }
} else {
    Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -Force
}
Write-Host "Package folder: $stage"
Write-Host "Package zip: $zip"






