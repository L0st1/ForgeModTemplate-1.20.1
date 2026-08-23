[CmdletBinding()]
param(
    [switch]$KeepProjects
)

$ErrorActionPreference = 'Stop'
$templateRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pwsh = (Get-Process -Id $PID).Path
$verificationRoot = Join-Path ([IO.Path]::GetTempPath()) ('mc-mod-generated-builds-' + [guid]::NewGuid().ToString('N'))
$sharedGradleHome = Join-Path $templateRoot '.gradle-user'
New-Item -ItemType Directory -Path $verificationRoot | Out-Null

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "断言失败：$Message" }
}

function Copy-Template([string]$Name) {
    $destination = Join-Path $verificationRoot $Name
    New-Item -ItemType Directory -Path $destination | Out-Null
    Get-ChildItem -LiteralPath $templateRoot -Force | Where-Object {
        $_.Name -notin @('build', 'bin', '.gradle', '.gradle-user', '.code-review-graph', '.migration-backup', '.agents')
    } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $destination $_.Name) -Recurse -Force
    }
    return $destination
}

function Initialize-Project([string]$Root, [string]$ModId, [string]$Mode, [string]$Modules) {
    $args = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Root 'scripts\init-template.ps1'),
        '-NonInteractive', '-ModId', $ModId, '-ModName', "$ModId Verification",
        '-ModGroup', 'org.verification', '-JavaPackage', "org.verification.$($ModId.Replace('_', ''))",
        '-MainClass', (($ModId -split '_' | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }) -join ''),
        '-ModVersion', '9.8.7', '-Author', 'Template Verification', '-License', 'MIT',
        '-Description', 'Generated project build verification.', '-Mode', $Mode
    )
    if ($Modules) { $args += @('-Modules', $Modules) }
    & $pwsh @args
    if ($LASTEXITCODE -ne 0) { throw "初始化失败：$Root" }
}

function Build-Project([string]$Root) {
    $oldGradleHome = $env:GRADLE_USER_HOME
    $oldProxyEnabled = $env:MC_MOD_PROXY_ENABLED
    try {
        $env:GRADLE_USER_HOME = $sharedGradleHome
        $env:MC_MOD_PROXY_ENABLED = 'true'
        Push-Location $Root
        try {
            & .\gradlew.bat clean build --no-daemon
            if ($LASTEXITCODE -ne 0) { throw "生成项目构建失败：$Root" }
        }
        finally { Pop-Location }
    }
    finally {
        $env:GRADLE_USER_HOME = $oldGradleHome
        $env:MC_MOD_PROXY_ENABLED = $oldProxyEnabled
    }
}

function Read-ZipEntry([string]$JarPath, [string]$EntryName) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($JarPath)
    try {
        $entry = $archive.GetEntry($EntryName)
        if (-not $entry) { throw "JAR 缺少条目：$EntryName" }
        $reader = [IO.StreamReader]::new($entry.Open())
        try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
    }
    finally { $archive.Dispose() }
}

try {
    $minimal = Copy-Template 'minimal'
    Initialize-Project $minimal 'minimal_mod' 'blank' ''
    Build-Project $minimal
    $minimalJar = Join-Path $minimal 'build\libs\minimal_mod-9.8.7.jar'
    Assert-True (Test-Path -LiteralPath $minimalJar) '最小项目 JAR 名称不正确'
    $minimalMetadata = Read-ZipEntry $minimalJar 'META-INF/mods.toml'
    Assert-True ($minimalMetadata -match 'modId="minimal_mod"') '最小项目 JAR 元数据缺少 Mod ID'
    Assert-True ($minimalMetadata -match 'version="9.8.7"') '最小项目 JAR 元数据缺少版本'
    Assert-True ($minimalMetadata -notmatch '\$\{') '最小项目 JAR 元数据仍有占位符'

    $full = Copy-Template 'full'
    Initialize-Project $full 'full_mod' 'example' 'mixin,config,network,gametest'
    Build-Project $full
    $fullJar = Join-Path $full 'build\libs\full_mod-9.8.7.jar'
    Assert-True (Test-Path -LiteralPath $fullJar) '全模块项目 JAR 名称不正确'
    $fullManifest = Read-ZipEntry $fullJar 'META-INF/MANIFEST.MF'
    Assert-True ($fullManifest -match 'MixinConfigs: full_mod.mixins.json') '全模块 JAR manifest 缺少 MixinConfigs'
    $fullMetadata = Read-ZipEntry $fullJar 'META-INF/mods.toml'
    Assert-True ($fullMetadata -notmatch '\$\{') '全模块 JAR 元数据仍有占位符'

    Write-Host '最小项目与全模块项目均已完成干净构建和 JAR 元数据验证。'
    if ($KeepProjects) { Write-Output "VERIFICATION_ROOT=$verificationRoot" }
}
finally {
    if (-not $KeepProjects -and (Test-Path -LiteralPath $verificationRoot)) {
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        $resolved = [IO.Path]::GetFullPath($verificationRoot)
        if ($resolved.StartsWith($tempRoot) -and [IO.Path]::GetFileName($resolved) -like 'mc-mod-generated-builds-*') {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
}
