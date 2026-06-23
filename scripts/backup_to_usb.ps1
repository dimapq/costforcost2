param(
    [string]$ConfigPath = "C:\Users\user\Desktop\costforcost2\config.ini",
    [string]$BackupRoot = "D:\costforcost2_backups"
)

$ErrorActionPreference = "Stop"

function Get-IniValue {
    param(
        [string[]]$Lines,
        [string]$Section,
        [string]$Key
    )

    $inSection = $false
    foreach ($line in $Lines) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith(";") -or $trimmed.StartsWith("#")) {
            continue
        }

        if ($trimmed -match '^\[(.+)\]$') {
            $inSection = ($matches[1] -eq $Section)
            continue
        }

        if ($inSection -and $trimmed -match '^(.*?)\s*=\s*(.*)$') {
            if ($matches[1].Trim() -eq $Key) {
                return $matches[2].Trim()
            }
        }
    }

    return ""
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Invoke-PgDump {
    param(
        [string]$PgDumpPath,
        [string]$DbHost,
        [string]$DbPort,
        [string]$DbName,
        [string]$DbUser,
        [string]$DbPassword,
        [string]$OutputFile,
        [string]$SslMode
    )

    $env:PGPASSWORD = $DbPassword
    if ($SslMode) {
        $env:PGSSLMODE = $SslMode
    }
    try {
        $args = @(
            "-h", $DbHost,
            "-p", $DbPort,
            "-U", $DbUser,
            "-d", $DbName,
            "-f", $OutputFile,
            "--no-password"
        )

        & $PgDumpPath @args
        if ($LASTEXITCODE -ne 0) {
            throw "pg_dump завершился с кодом $LASTEXITCODE"
        }
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
        Remove-Item Env:PGSSLMODE -ErrorAction SilentlyContinue
    }
}

$pgDumpPath = "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe"
if (-not (Test-Path -LiteralPath $pgDumpPath)) {
    throw "Не найден pg_dump: $pgDumpPath"
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Не найден config.ini: $ConfigPath"
}

$configLines = Get-Content -LiteralPath $ConfigPath -Encoding UTF8

$selectedMode = Get-IniValue -Lines $configLines -Section "app" -Key "selected_connection_mode"
if (-not $selectedMode) {
    $selectedMode = "online"
}

$section = if ($selectedMode -eq "local") { "database_local" } else { "database_online" }

$dbHost = Get-IniValue -Lines $configLines -Section $section -Key "host"
$dbPort = Get-IniValue -Lines $configLines -Section $section -Key "port"
$dbName = Get-IniValue -Lines $configLines -Section $section -Key "name"
$dbUser = Get-IniValue -Lines $configLines -Section $section -Key "user"
$dbPassword = Get-IniValue -Lines $configLines -Section $section -Key "password"
$dbSslMode = Get-IniValue -Lines $configLines -Section $section -Key "sslmode"

if (-not $dbHost -or -not $dbPort -or -not $dbName -or -not $dbUser) {
    throw "Не удалось прочитать параметры подключения из секции [$section]"
}

Ensure-Directory -Path $BackupRoot

$dailyDir = Join-Path $BackupRoot "daily"
$weeklyDir = Join-Path $BackupRoot "weekly"
$monthlyDir = Join-Path $BackupRoot "monthly"
$logsDir = Join-Path $BackupRoot "logs"

Ensure-Directory -Path $dailyDir
Ensure-Directory -Path $weeklyDir
Ensure-Directory -Path $monthlyDir
Ensure-Directory -Path $logsDir

$now = Get-Date
$weekdayName = $now.ToString("dddd", [System.Globalization.CultureInfo]::InvariantCulture).ToLowerInvariant()
$monthStamp = $now.ToString("yyyy-MM")
$timestamp = $now.ToString("yyyy-MM-dd HH:mm:ss")

$dailyFile = Join-Path $dailyDir "${dbName}_daily.sql"
$weeklyFile = Join-Path $weeklyDir "${dbName}_weekly_${weekdayName}.sql"
$monthlyFile = Join-Path $monthlyDir "${dbName}_monthly_${monthStamp}.sql"
$logFile = Join-Path $logsDir "backup_log.txt"

Invoke-PgDump -PgDumpPath $pgDumpPath -DbHost $dbHost -DbPort $dbPort -DbName $dbName -DbUser $dbUser -DbPassword $dbPassword -OutputFile $dailyFile -SslMode $dbSslMode
Invoke-PgDump -PgDumpPath $pgDumpPath -DbHost $dbHost -DbPort $dbPort -DbName $dbName -DbUser $dbUser -DbPassword $dbPassword -OutputFile $weeklyFile -SslMode $dbSslMode

if ($now.Day -eq 1 -or -not (Test-Path -LiteralPath $monthlyFile)) {
    Invoke-PgDump -PgDumpPath $pgDumpPath -DbHost $dbHost -DbPort $dbPort -DbName $dbName -DbUser $dbUser -DbPassword $dbPassword -OutputFile $monthlyFile -SslMode $dbSslMode
}

$logEntry = "{0} | mode={1} | host={2} | db={3} | daily={4} | weekly={5}" -f $timestamp, $selectedMode, $dbHost, $dbName, $dailyFile, $weeklyFile
if (Test-Path -LiteralPath $monthlyFile) {
    $logEntry += " | monthly=$monthlyFile"
}

Add-Content -LiteralPath $logFile -Value $logEntry -Encoding UTF8
Write-Output $logEntry
