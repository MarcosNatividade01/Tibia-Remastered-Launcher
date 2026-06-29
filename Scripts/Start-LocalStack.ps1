$ErrorActionPreference = 'Stop'

function Test-LocalPort {
    param([int]$Port)
    return $null -ne (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Start-IfPortClosed {
    param(
        [string]$Name,
        [string]$Exe,
        [string]$WorkingDirectory,
        [string]$Arguments,
        [int]$Port,
        [int]$TimeoutSeconds = 60
    )

    if (Test-LocalPort -Port $Port) {
        Write-Host "$Name ja esta ativo na porta $Port."
        return
    }

    if (-not (Test-Path $Exe)) {
        throw "$Name nao encontrado: $Exe"
    }

    Write-Host "Iniciando $Name..."
    if ([string]::IsNullOrWhiteSpace($Arguments)) {
        Start-Process -FilePath $Exe -WorkingDirectory $WorkingDirectory -WindowStyle Hidden | Out-Null
    } else {
        Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -WindowStyle Hidden | Out-Null
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-LocalPort -Port $Port) {
            Write-Host "$Name ativo na porta $Port."
            return
        }
        Start-Sleep -Seconds 1
    }

    throw "$Name nao abriu a porta $Port."
}

Start-IfPortClosed -Name 'MySQL' -Exe 'C:\xampp\mysql\bin\mysqld.exe' -WorkingDirectory 'C:\xampp\mysql\bin' -Arguments '--defaults-file=C:\xampp\mysql\bin\my.ini' -Port 3306
Start-IfPortClosed -Name 'Apache' -Exe 'C:\xampp\apache\bin\httpd.exe' -WorkingDirectory 'C:\xampp\apache\bin' -Arguments '' -Port 80
Start-IfPortClosed -Name 'Crystal Server' -Exe 'C:\otserv\crystalserver.exe' -WorkingDirectory 'C:\otserv' -Arguments '' -Port 7171 -TimeoutSeconds 300

Write-Host 'Stack local iniciada.'
