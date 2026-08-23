[CmdletBinding()]
param(
    [switch]$SkipProxyConnection
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$errors = New-Object System.Collections.Generic.List[string]

function Add-Check([bool]$Passed, [string]$Success, [string]$Failure) {
    if ($Passed) {
        Write-Host "[通过] $Success"
    }
    else {
        Write-Host "[失败] $Failure" -ForegroundColor Red
        $errors.Add($Failure)
    }
}

$javaCommand = Get-Command java -ErrorAction SilentlyContinue
if ($javaCommand) {
    $javaOutput = (& java -version 2>&1 | Out-String)
    $versionMatch = [regex]::Match($javaOutput, 'version\s+"(?<major>\d+)')
    $javaMajor = if ($versionMatch.Success) { [int]$versionMatch.Groups['major'].Value } else { 0 }
    Add-Check ($javaMajor -eq 17) "Java 17（$($javaCommand.Source)）" "需要 Java 17，当前检测到：$javaMajor。请配置 JAVA_HOME 和 PATH。"
}
else {
    Add-Check $false '' '未找到 java。请安装 Java 17 并配置 JAVA_HOME 和 PATH。'
}

$wrapperPath = Join-Path $repoRoot $(if ($IsWindows -or $env:OS -eq 'Windows_NT') { 'gradlew.bat' } else { 'gradlew' })
Add-Check (Test-Path -LiteralPath $wrapperPath) 'Gradle Wrapper 存在' "缺少 Gradle Wrapper：$wrapperPath"

foreach ($relative in @('build.gradle', 'settings.gradle', 'gradle.properties', 'src\main\resources\META-INF\mods.toml')) {
    Add-Check (Test-Path -LiteralPath (Join-Path $repoRoot $relative)) "关键文件存在：$relative" "缺少关键文件：$relative"
}

$network = @{}
foreach ($relative in @('config\network.properties', 'config\network.local.properties')) {
    $path = Join-Path $repoRoot $relative
    if (Test-Path -LiteralPath $path) {
        Get-Content -LiteralPath $path -Encoding UTF8 | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
                $networkKey = $matches[1].Trim()
                $networkValue = $matches[2].Trim()
                $network[$networkKey] = $networkValue
            }
        }
    }
}
$proxyEnabledText = if ($env:MC_MOD_PROXY_ENABLED) { $env:MC_MOD_PROXY_ENABLED } elseif ($network['proxy.enabled']) { $network['proxy.enabled'] } else { 'false' }
$proxyEnabled = [bool]::Parse($proxyEnabledText)
$proxyHost = if ($env:MC_MOD_PROXY_HOST) { $env:MC_MOD_PROXY_HOST } elseif ($network['proxy.host']) { $network['proxy.host'] } else { '127.0.0.1' }
$proxyPortText = if ($env:MC_MOD_PROXY_PORT) { $env:MC_MOD_PROXY_PORT } elseif ($network['proxy.port']) { $network['proxy.port'] } else { '7890' }
$proxyPort = [int]$proxyPortText

if ($proxyEnabled) {
    Write-Host "[信息] 代理模式：启用（$proxyHost`:$proxyPort）"
    if (-not $SkipProxyConnection) {
        $client = [System.Net.Sockets.TcpClient]::new()
        try {
            $async = $client.BeginConnect($proxyHost, $proxyPort, $null, $null)
            $connected = $async.AsyncWaitHandle.WaitOne(1500) -and $client.Connected
            Add-Check $connected '代理端口可访问' '代理不可访问。请启动本机代理，或在 config/network.local.properties 中设置 proxy.enabled=false。'
        }
        catch {
            Add-Check $false '' '代理连接检查失败。请修改或禁用 config/network.local.properties 中的代理。'
        }
        finally {
            $client.Dispose()
        }
    }
}
else {
    Write-Host '[信息] 代理模式：禁用，Gradle 将直接访问依赖仓库。'
}

if ($errors.Count -gt 0) {
    Write-Host "环境诊断失败，共 $($errors.Count) 项。" -ForegroundColor Red
    exit 1
}
Write-Host '环境诊断通过。'
