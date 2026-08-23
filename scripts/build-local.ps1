[CmdletBinding()]
param(
    [switch]$SkipDoctor,
    [switch]$SkipQuality
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$previousGradleOpts = $env:GRADLE_OPTS

function Get-NetworkSettings {
    $network = @{}
    foreach ($relative in @('config\network.properties', 'config\network.local.properties')) {
        $path = Join-Path $repoRoot $relative
        if (Test-Path -LiteralPath $path) {
            Get-Content -LiteralPath $path -Encoding UTF8 | ForEach-Object {
                if ($_ -match '^\s*([^#][^=]*)=(.*)$') { $network[$matches[1].Trim()] = $matches[2].Trim() }
            }
        }
    }
    return $network
}

$network = Get-NetworkSettings
$proxyEnabledText = if ($env:MC_MOD_PROXY_ENABLED) { $env:MC_MOD_PROXY_ENABLED } elseif ($network['proxy.enabled']) { $network['proxy.enabled'] } else { 'false' }
if ([bool]::Parse($proxyEnabledText) -and $env:GRADLE_OPTS -notmatch '-Dhttp\.proxyHost=') {
    $proxyHost = if ($env:MC_MOD_PROXY_HOST) { $env:MC_MOD_PROXY_HOST } elseif ($network['proxy.host']) { $network['proxy.host'] } else { '127.0.0.1' }
    $proxyPort = if ($env:MC_MOD_PROXY_PORT) { $env:MC_MOD_PROXY_PORT } elseif ($network['proxy.port']) { $network['proxy.port'] } else { '7890' }
    $proxyOptions = "-Dhttp.proxyHost=$proxyHost -Dhttp.proxyPort=$proxyPort -Dhttps.proxyHost=$proxyHost -Dhttps.proxyPort=$proxyPort"
    $env:GRADLE_OPTS = (($env:GRADLE_OPTS, $proxyOptions) | Where-Object { $_ }) -join ' '
}

Push-Location $repoRoot
try {
    if (-not $SkipDoctor) {
        & (Join-Path $PSScriptRoot 'doctor.ps1')
        if ($LASTEXITCODE -ne 0) { throw '环境诊断失败。' }
    }

    $gradle = if ($IsWindows -or $env:OS -eq 'Windows_NT') { '.\gradlew.bat' } else { './gradlew' }
    $taskOutput = & $gradle tasks --all
    if ($LASTEXITCODE -ne 0) { throw '无法读取 Gradle 任务。' }

    if (-not $SkipQuality) {
        foreach ($qualityTask in @('spotlessCheck', 'checkstyleMain', 'lint')) {
            if ($taskOutput -match "(?m)^$qualityTask\s") {
                & $gradle $qualityTask
                if ($LASTEXITCODE -ne 0) { throw "质量检查失败：$qualityTask" }
            }
        }
    }
    if ($taskOutput -match '(?m)^test\s') {
        & $gradle test
        if ($LASTEXITCODE -ne 0) { throw '测试失败。' }
    }

    & $gradle build
    if ($LASTEXITCODE -ne 0) { throw 'Gradle 构建失败。' }

    $artifact = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'build\libs') -Filter '*.jar' -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $artifact) { throw '构建完成但没有找到 JAR 产物。' }
    Write-Host "构建成功：$($artifact.FullName)"
}
finally {
    Pop-Location
    $env:GRADLE_OPTS = $previousGradleOpts
}
