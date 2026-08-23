$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$localConfig = Join-Path $repoRoot 'config\network.local.properties'
$oldGradleHome = $env:GRADLE_USER_HOME
$oldEnabled = $env:MC_MOD_PROXY_ENABLED
$oldHost = $env:MC_MOD_PROXY_HOST
$oldPort = $env:MC_MOD_PROXY_PORT

function Assert-Output([string[]]$Output, [string]$Expected) {
    if (($Output -join "`n") -notmatch [regex]::Escape($Expected)) { throw "未找到代理配置：$Expected" }
}

function Read-NetworkConfiguration {
    Push-Location $repoRoot
    try {
        $output = & .\gradlew.bat -q --build-file network-probe.gradle printNetworkConfiguration --offline
        if ($LASTEXITCODE -ne 0) { throw '读取 Gradle 代理配置失败。' }
        return @($output)
    }
    finally { Pop-Location }
}

try {
    $env:GRADLE_USER_HOME = Join-Path $repoRoot '.gradle-user'
    Remove-Item -LiteralPath $localConfig -Force -ErrorAction SilentlyContinue
    Remove-Item Env:MC_MOD_PROXY_ENABLED -ErrorAction SilentlyContinue
    Remove-Item Env:MC_MOD_PROXY_HOST -ErrorAction SilentlyContinue
    Remove-Item Env:MC_MOD_PROXY_PORT -ErrorAction SilentlyContinue

    $defaultOutput = Read-NetworkConfiguration
    Assert-Output $defaultOutput 'proxy.enabled=true'
    Assert-Output $defaultOutput 'proxy.host=127.0.0.1'
    Assert-Output $defaultOutput 'proxy.port=7890'

    @(
        'proxy.enabled=true',
        'proxy.host=127.0.0.2',
        'proxy.port=18080'
    ) | Set-Content -LiteralPath $localConfig -Encoding UTF8
    $localOutput = Read-NetworkConfiguration
    Assert-Output $localOutput 'proxy.host=127.0.0.2'
    Assert-Output $localOutput 'proxy.port=18080'

    $env:MC_MOD_PROXY_ENABLED = 'false'
    $disabledOutput = Read-NetworkConfiguration
    Assert-Output $disabledOutput 'proxy.enabled=false'

    Write-Host '默认代理、本地覆盖和环境禁用三种模式验证通过。'
}
finally {
    if (Test-Path -LiteralPath $localConfig) { Remove-Item -LiteralPath $localConfig -Force }
    $env:GRADLE_USER_HOME = $oldGradleHome
    if ($null -eq $oldEnabled) { Remove-Item Env:MC_MOD_PROXY_ENABLED -ErrorAction SilentlyContinue } else { $env:MC_MOD_PROXY_ENABLED = $oldEnabled }
    if ($null -eq $oldHost) { Remove-Item Env:MC_MOD_PROXY_HOST -ErrorAction SilentlyContinue } else { $env:MC_MOD_PROXY_HOST = $oldHost }
    if ($null -eq $oldPort) { Remove-Item Env:MC_MOD_PROXY_PORT -ErrorAction SilentlyContinue } else { $env:MC_MOD_PROXY_PORT = $oldPort }
}
