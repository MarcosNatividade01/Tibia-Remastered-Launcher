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

function Test-PackageProcessesRunning {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $root = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/') + '\'
    $running = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        try {
            -not [string]::IsNullOrWhiteSpace($_.Path) -and [System.IO.Path]::GetFullPath($_.Path).StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)
        } catch {
            $false
        }
    } | Select-Object -First 1
    return ($null -ne $running)
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

function Test-PlayablePackageRoot {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $launcher = Join-Path $Path 'Start Launcher.bat'
    $server = Join-Path $Path 'Server\crystalserver.exe'
    return ((Test-Path -LiteralPath $launcher) -and (Test-Path -LiteralPath $server))
}

function Get-InstalledVersion {
    param([string]$Path)
    $versionPath = Join-Path $Path 'version.json'
    if (-not (Test-Path -LiteralPath $versionPath)) { return '' }
    try {
        $version = (Get-Content -LiteralPath $versionPath -Raw | ConvertFrom-Json).version
        return [string]$version
    } catch {
        return ''
    }
}

function Get-AssetVersion {
    param([object]$Asset)
    if ([string]$Asset.name -match '-v?([0-9]+(?:\.[0-9]+)+)\.zip$') { return $Matches[1] }
    return ''
}

function Get-PackageMarkerPath {
    param([string]$Path)
    return (Join-Path $Path '.playable-package.json')
}

function Test-PlayablePackageCurrent {
    param([string]$Path, [object]$Asset)
    $markerPath = Get-PackageMarkerPath -Path $Path
    if (Test-Path -LiteralPath $markerPath) {
        try {
            $marker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
            if (([string]$marker.assetName -eq [string]$Asset.name) -and ([string]$marker.assetUpdatedAt -eq [string]$Asset.updated_at)) { return $true }
        } catch {
        }
    }

    $installedVersion = Get-InstalledVersion -Path $Path
    $assetVersion = Get-AssetVersion -Asset $Asset
    return ($installedVersion -ne '' -and $assetVersion -ne '' -and $installedVersion -eq $assetVersion)
}

function Save-PackageMarker {
    param([string]$Path, [object]$Asset)
    $marker = [pscustomobject]@{
        assetName = [string]$Asset.name
        assetUpdatedAt = [string]$Asset.updated_at
        savedAt = (Get-Date).ToString('s')
    }
    $json = $marker | ConvertTo-Json -Depth 4
    Set-Content -LiteralPath (Get-PackageMarkerPath -Path $Path) -Value $json -Encoding UTF8
}

function Repair-ClientLoginEndpoint {
    param([string]$Path)

    $loginFiles = @(
        (Join-Path $Path 'Runtime\xampp\htdocs\login.php'),
        (Join-Path $Path 'Web\htdocs\login.php')
    )

    foreach ($loginPath in $loginFiles) {
        if (-not (Test-Path -LiteralPath $loginPath)) { continue }
        try {
            $loginText = Get-Content -LiteralPath $loginPath -Raw
            $loginText = $loginText.TrimStart([char]0xFEFF)
            if ($loginText -notmatch 'function extractLoginCredentials') {
                $oldLogin = @"
        case 'login':
            `$email = strtolower(trim((string)(`$payload['email'] ?? `$payload['accountname'] ?? '')));
            `$password = (string)(`$payload['password'] ?? '');
            login(`$db, `$email, `$password);

        default:
"@
                $newLogin = @"
        case 'login':
            `$credentials = extractLoginCredentials(`$payload);
            login(`$db, `$credentials['email'], `$credentials['password']);

        case 'logout':
            reply([
                'success' => true,
            ]);

        default:
"@
                if ($loginText.Contains($oldLogin)) {
                    $loginText = $loginText.Replace($oldLogin, $newLogin)
                }

                $oldFunction = @"
function login(PDO `$db, string `$email, string `$password): void
{
"@
                $newFunction = @"
function extractLoginCredentials(array `$payload): array
{
    `$email = strtolower(trim((string)(`$payload['email'] ?? `$payload['accountname'] ?? '')));
    `$password = (string)(`$payload['password'] ?? '');

    if ((`$email === '' || `$password === '') && isset(`$payload['sessionkey'])) {
        `$sessionKey = str_replace(["\r\n", "\r"], "\n", (string)`$payload['sessionkey']);
        `$parts = explode("\n", `$sessionKey, 2);
        if (count(`$parts) === 2) {
            `$email = strtolower(trim(`$parts[0]));
            `$password = `$parts[1];
        }
    }

    return [
        'email' => `$email,
        'password' => `$password,
    ];
}

function login(PDO `$db, string `$email, string `$password): void
{
"@
                if ($loginText.Contains($oldFunction)) {
                    $loginText = $loginText.Replace($oldFunction, $newFunction)
                }
            }
            [System.IO.File]::WriteAllText($loginPath, $loginText, [System.Text.UTF8Encoding]::new($false))
        } catch {
            Write-Step "Aviso: nao foi possivel ajustar login.php em ${loginPath}: $($_.Exception.Message)"
        }
    }
}
function Start-PlayableLauncher {
    param([string]$Path, [string]$Message)
    Repair-ClientLoginEndpoint -Path $Path
    Write-Step $Message
    Start-Process -FilePath (Join-Path $Path 'Start Launcher.bat') -WorkingDirectory $Path
}

$localPlayable = Join-Path (Split-Path -Parent $PSScriptRoot) 'Server\crystalserver.exe'
if (Test-Path -LiteralPath $localPlayable) {
    $launcher = Join-Path (Split-Path -Parent $PSScriptRoot) 'Launcher\Launcher.ps1'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $launcher
    exit $LASTEXITCODE
}

$hasInstalledPackage = Test-PlayablePackageRoot -Path $InstallRoot
$asset = $null

if ($hasInstalledPackage) {
    try {
        Write-Step 'Pacote jogavel ja instalado. Verificando atualizacao da Release...'
        $asset = Get-LatestPlayableAsset -Repository $Repo
        if (Test-PlayablePackageCurrent -Path $InstallRoot -Asset $asset) {
            Save-PackageMarker -Path $InstallRoot -Asset $asset
            Start-PlayableLauncher -Path $InstallRoot -Message 'Pacote jogavel ja esta atualizado. Abrindo launcher...'
            exit 0
        }
        Write-Step "Atualizacao encontrada: $($asset.name)"
        if (Test-PackageProcessesRunning -Path $InstallRoot) {
            Write-Step 'Pacote esta em uso. Feche o jogo/servidor para atualizar; abrindo a instalacao atual por enquanto.'
            Start-PlayableLauncher -Path $InstallRoot -Message 'Abrindo pacote jogavel existente...'
            exit 0
        }
    } catch {
        Write-Step "Nao foi possivel verificar atualizacao agora: $($_.Exception.Message)"
        Start-PlayableLauncher -Path $InstallRoot -Message 'Abrindo pacote jogavel existente...'
        exit 0
    }
} else {
    Write-Step 'Este ZIP contem apenas o codigo. Baixando o pacote jogavel completo da Release...'
    $asset = Get-LatestPlayableAsset -Repository $Repo
}

$downloadDir = Join-Path $env:TEMP 'TibiaRemasteredLauncher'
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
$zipPath = Join-Path $downloadDir $asset.name

Write-Step "Baixando $($asset.name)"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing -TimeoutSec 1800

Write-Step "Extraindo em $InstallRoot"
$playRoot = Expand-PlayablePackage -ZipPath $zipPath -Destination $InstallRoot
Save-PackageMarker -Path $playRoot -Asset $asset

Start-PlayableLauncher -Path $playRoot -Message 'Abrindo launcher jogavel...'