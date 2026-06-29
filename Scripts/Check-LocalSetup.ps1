$ErrorActionPreference = 'Continue'

$checks = @(
    @{ Name = 'MySQL'; Path = 'C:\xampp\mysql\bin\mysqld.exe'; Port = 3306 },
    @{ Name = 'Apache'; Path = 'C:\xampp\apache\bin\httpd.exe'; Port = 80 },
    @{ Name = 'Crystal Server'; Path = 'C:\otserv\crystalserver.exe'; Port = 7171 },
    @{ Name = 'Tibia Client'; Path = (Join-Path $env:USERPROFILE 'Tibiafriends\bin\client-local.exe'); Port = $null }
)

foreach ($check in $checks) {
    $exists = Test-Path $check.Path
    $listening = $false
    if ($null -ne $check.Port) {
        $listening = $null -ne (Get-NetTCPConnection -LocalPort $check.Port -State Listen -ErrorAction SilentlyContinue)
    }
    [pscustomobject]@{
        Name = $check.Name
        Path = $check.Path
        Exists = $exists
        Port = $check.Port
        Listening = $listening
    }
}
