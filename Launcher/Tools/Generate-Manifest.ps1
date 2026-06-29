param(
    [string]$Root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$Version = '0.1.0',
    [string]$RawBaseUrl = '',
    [string]$Output = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Output)) { $Output = Join-Path $Root 'manifest.json' }

$excludeRoots = @('UserData','Logs','Backup','Backups','Saves','.git','.github','.vs','.vscode','.idea')
$excludePatterns = @('.gitignore','.gitattributes','manifest.json','version.json','*.tmp','*.temp','*.log','*.bak*','*.backup','*.download','*.pdb','*.dmp','*.db','*.sqlite','*.sqlite3','*.sql','*.token','*.key','*.pem','crashdump/*','cache/*','Cache/*','tmp/*','temp/*')
$githubTextExtensions = @('.bat','.cmd','.css','.csv','.gitkeep','.html','.ini','.js','.json','.md','.php','.ps1','.sql','.txt','.xml','.yml','.yaml')

function Convert-ToRelativePath([string]$Base, [string]$Path) {
    $rel = $Path.Substring($Base.TrimEnd('\','/').Length).TrimStart('\','/')
    return ($rel -replace '\\','/')
}

function Test-Ignored([string]$Relative) {
    foreach ($rootName in $excludeRoots) {
        if ($Relative -ieq $rootName -or $Relative.StartsWith($rootName + '/', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    foreach ($pattern in $excludePatterns) {
        if ($Relative -like $pattern) { return $true }
    }
    return $false
}

function Get-FileUrl([string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($RawBaseUrl)) { return '' }
    $encoded = [System.Uri]::EscapeDataString($Relative).Replace('%2F','/')
    return $RawBaseUrl.TrimEnd('/') + '/' + $encoded
}

function Test-GitHubTextFile([string]$Relative) {
    $name = [System.IO.Path]::GetFileName($Relative)
    if ($name -in @('.gitkeep','.gitignore','.gitattributes')) { return $true }
    $extension = [System.IO.Path]::GetExtension($Relative).ToLowerInvariant()
    return $githubTextExtensions -contains $extension
}

function Get-GitHubRawBytes([string]$Path, [string]$Relative) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if (-not (Test-GitHubTextFile $Relative)) { Write-Output -NoEnumerate $bytes; return }

    $normalized = New-Object System.Collections.Generic.List[byte]
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 13) {
            if (($i + 1) -lt $bytes.Length -and $bytes[$i + 1] -eq 10) { $i++ }
            $normalized.Add(10)
        } else {
            $normalized.Add($bytes[$i])
        }
    }
    Write-Output -NoEnumerate $normalized.ToArray()
}

function Get-Sha256FromBytes([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
    } finally {
        $sha.Dispose()
    }
}
$files = @()
Get-ChildItem -Path $Root -File -Recurse | ForEach-Object {
    $rel = Convert-ToRelativePath -Base $Root -Path $_.FullName
    if (Test-Ignored $rel) { return }
    $rawBytes = Get-GitHubRawBytes -Path $_.FullName -Relative $rel
    $hash = Get-Sha256FromBytes -Bytes $rawBytes
    $overwrite = -not ($rel.StartsWith('Config/', [System.StringComparison]::OrdinalIgnoreCase))
    $category = ($rel.Split('/')[0])
    $files += [pscustomobject]@{
        path = $rel
        sha256 = $hash
        size = $rawBytes.Length
        url = Get-FileUrl $rel
        overwrite = $overwrite
        category = $category
    }
}

$manifest = [pscustomobject]@{
    version = $Version
    generatedAt = (Get-Date).ToString('s')
    files = @($files | Sort-Object path)
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $Output -Encoding UTF8
[pscustomobject]@{Output=$Output; Version=$Version; Files=$files.Count}





