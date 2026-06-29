param(
    [string]$Repo = 'MarcosNatividade01/Tibia-Remastered-Launcher',
    [string]$InstallRoot = (Join-Path $env:USERPROFILE 'Downloads\TibiaRemastered-Friends')
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) {
    Write-Host "[Tibia Remastered] $Message"
}

function Get-LatestPlayableAsset {
    param([string]$Repository)
    $headers = @{ 'User-Agent' = 'TibiaRemasteredLauncher'; 'Cache-Control' = 'no-cache'; Pragma = 'no-cache' }
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest" -Headers $headers -TimeoutSec 30
    $asset = @($release.assets | Where-Object { $_.name -like 'TibiaRemastered-Friends-*.zip' } | Select-Object -First 1)
    if (-not $asset) { throw "Nenhum pacote TibiaRemastered-Friends-*.zip encontrado na Release mais recente." }
    return $asset
}

function Expand-PlayablePackage {
    param([string]$ZipPath, [string]$Destination)
    if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $Destination -Force

    $directLauncher = Join-Path $Destination 'Start Launcher.bat'
    if (Test-Path -LiteralPath $directLauncher) { return $Destination }

    $nestedLauncher = Get-ChildItem -LiteralPath $Destination -Filter 'Start Launcher.bat' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $nestedLauncher) { throw 'Pacote extraido, mas Start Launcher.bat nao foi encontrado.' }
    return (Split-Path -Parent $nestedLauncher.FullName)
}

$localPlayable = Join-Path (Split-Path -Parent $PSScriptRoot) 'Server\crystalserver.exe'
if (Test-Path -LiteralPath $localPlayable) {
    $launcher = Join-Path (Split-Path -Parent $PSScriptRoot) 'Launcher\Launcher.ps1'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $launcher
    exit $LASTEXITCODE
}

Write-Step 'Este ZIP contem apenas o codigo. Baixando o pacote jogavel completo da Release...'
$asset = Get-LatestPlayableAsset -Repository $Repo
$downloadDir = Join-Path $env:TEMP 'TibiaRemasteredLauncher'
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
$zipPath = Join-Path $downloadDir $asset.name

Write-Step "Baixando $($asset.name)"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing -TimeoutSec 1800

Write-Step "Extraindo em $InstallRoot"
$playRoot = Expand-PlayablePackage -ZipPath $zipPath -Destination $InstallRoot

Write-Step 'Abrindo launcher jogavel...'
Start-Process -FilePath (Join-Path $playRoot 'Start Launcher.bat') -WorkingDirectory $playRoot
