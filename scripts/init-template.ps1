[CmdletBinding()]
param(
    [string]$ModId,
    [string]$ModName,
    [string]$ModGroup,
    [string]$JavaPackage,
    [string]$MainClass,
    [string]$ModVersion,
    [string]$Author,
    [string]$License,
    [string]$Description,
    [ValidateSet('', 'blank', 'example')]
    [string]$Mode = '',
    [string[]]$Modules = @(),
    [switch]$NonInteractive,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$statePath = Join-Path $repoRoot '.mcmod-template-state.json'

function Stop-Initialization([string]$Message) {
    Write-Error $Message
    exit 1
}

if (Test-Path -LiteralPath $statePath) {
    Stop-Initialization '该项目已经完成模板初始化。请从新的模板副本创建另一个项目；现有源码不会被覆盖。'
}

$configPath = Join-Path $repoRoot 'template.config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    Stop-Initialization '缺少 template.config.json，当前目录不是可初始化的模板副本。'
}

$templateConfig = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$defaults = $templateConfig.defaults

function Read-Value([string]$Label, [string]$Current, [string]$Default) {
    if ($Current) { return $Current }
    if ($NonInteractive) { return '' }
    $answer = Read-Host "$Label [$Default]"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer.Trim()
}

$ModId = Read-Value 'Mod ID' $ModId $defaults.modId
$ModName = Read-Value '显示名称' $ModName $defaults.modName
$ModGroup = Read-Value 'Gradle group' $ModGroup $defaults.modGroup
$JavaPackage = Read-Value 'Java 包名' $JavaPackage $defaults.javaPackage
$MainClass = Read-Value '主类名' $MainClass $defaults.mainClass
$ModVersion = Read-Value 'Mod 版本' $ModVersion $defaults.modVersion
$Author = Read-Value '作者' $Author $defaults.author
$License = Read-Value '许可证' $License $defaults.license
$Description = Read-Value '描述' $Description $defaults.description
if (-not $Mode) {
    $Mode = if ($NonInteractive) { [string]$defaults.mode } else { Read-Value '初始化模式（blank/example）' '' $defaults.mode }
}
if (-not $NonInteractive -and $Modules.Count -eq 0) {
    $moduleInput = Read-Host '可选模块（mixin,config,network,gametest；留空表示无）'
    if ($moduleInput) { $Modules = $moduleInput -split ',' }
}
$Modules = @($Modules | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ } | Select-Object -Unique)

$requiredValues = [ordered]@{
    ModId = $ModId
    ModName = $ModName
    ModGroup = $ModGroup
    JavaPackage = $JavaPackage
    MainClass = $MainClass
    ModVersion = $ModVersion
    Author = $Author
    License = $License
    Description = $Description
}
foreach ($entry in $requiredValues.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace([string]$entry.Value)) {
        Stop-Initialization "缺少必填参数：$($entry.Key)。非交互模式必须显式提供全部项目身份参数。"
    }
    if ([string]$entry.Value -match "[`r`n]") {
        Stop-Initialization "参数 $($entry.Key) 不得包含换行。"
    }
}
if ($ModId -notmatch '^[a-z][a-z0-9_]{1,63}$') {
    Stop-Initialization 'Mod ID 必须为 2-64 位小写字母、数字或下划线，并以小写字母开头。'
}
$javaSegment = '[A-Za-z_$][A-Za-z0-9_$]*'
if ($ModGroup -notmatch "^$javaSegment(\.$javaSegment)*$") {
    Stop-Initialization 'Gradle group 必须是合法的点分 Java 标识符。'
}
if ($JavaPackage -notmatch "^$javaSegment(\.$javaSegment)+$") {
    Stop-Initialization 'Java 包名必须包含至少两个合法的点分 Java 标识符。'
}
if ($MainClass -notmatch '^[A-Z_$][A-Za-z0-9_$]*$') {
    Stop-Initialization '主类名必须是以大写字母、下划线或 $ 开头的合法 Java 标识符。'
}
if ($ModVersion -notmatch '^[0-9A-Za-z][0-9A-Za-z._+\-]*$') {
    Stop-Initialization 'Mod 版本包含不支持的字符。'
}
if ($Mode -notin @('blank', 'example')) {
    Stop-Initialization '初始化模式只能是 blank 或 example。'
}
$supportedModules = @($templateConfig.supportedModules)
$unknownModules = @($Modules | Where-Object { $_ -notin $supportedModules })
if ($unknownModules.Count -gt 0) {
    Stop-Initialization "不支持的模块：$($unknownModules -join ', ')。"
}

$mainSource = Join-Path $repoRoot 'src\main\java\com\example\examplemod\ExampleMod.java'
$defaultAssets = Join-Path $repoRoot 'src\main\resources\assets\example_mod'
$templateRoot = Join-Path $repoRoot 'template'
foreach ($requiredPath in @($mainSource, $defaultAssets, $templateRoot, (Join-Path $repoRoot 'gradle.properties'))) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Stop-Initialization "模板预检失败，缺少：$requiredPath"
    }
}
$mainSourceText = Get-Content -LiteralPath $mainSource -Raw -Encoding UTF8
if ($mainSourceText -notmatch '__OPTIONAL_IMPORTS__' -or $mainSourceText -notmatch '__OPTIONAL_INIT__') {
    Stop-Initialization '主类缺少模板标记，拒绝覆盖可能已修改的源码。'
}

$tokenValues = [ordered]@{
    '__MOD_ID__' = $ModId
    '__MOD_NAME__' = $ModName
    '__MOD_GROUP__' = $ModGroup
    '__JAVA_PACKAGE__' = $JavaPackage
    '__MAIN_CLASS__' = $MainClass
    '__MOD_VERSION__' = $ModVersion
    '__MOD_AUTHOR__' = $Author
    '__MOD_LICENSE__' = $License
    '__MOD_DESCRIPTION__' = $Description
}
function Expand-TemplateText([string]$Text) {
    $result = $Text
    foreach ($token in $tokenValues.Keys) {
        $result = $result.Replace($token, [string]$tokenValues[$token])
    }
    return $result
}

$workRoot = Join-Path $repoRoot ('.template-work\' + [guid]::NewGuid().ToString('N'))
$backupRoot = Join-Path $workRoot 'backup'
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
foreach ($relative in @('src', 'template', 'template.config.json', 'gradle.properties', 'LICENSE.txt', 'docs/migration-inventory.md')) {
    $source = Join-Path $repoRoot $relative
    if (Test-Path -LiteralPath $source) {
        $destination = Join-Path $backupRoot $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
    }
}

function Restore-TemplateBackup {
    foreach ($relative in @('src', 'template', 'template.config.json', 'gradle.properties', 'LICENSE.txt', 'docs/migration-inventory.md')) {
        $current = Join-Path $repoRoot $relative
        $backup = Join-Path $backupRoot $relative
        if (Test-Path -LiteralPath $current) { Remove-Item -LiteralPath $current -Recurse -Force }
        if (Test-Path -LiteralPath $backup) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $current) -Force | Out-Null
            Copy-Item -LiteralPath $backup -Destination $current -Recurse -Force
        }
    }
    if (Test-Path -LiteralPath $statePath) { Remove-Item -LiteralPath $statePath -Force }
}

function Write-ExpandedTemplateTree([string]$SourceRoot, [string]$DestinationRoot) {
    if (-not (Test-Path -LiteralPath $SourceRoot)) { return }
    Get-ChildItem -LiteralPath $SourceRoot -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($SourceRoot.Length).TrimStart('\', '/')
        if ($relative.EndsWith('.template')) { $relative = $relative.Substring(0, $relative.Length - 9) }
        $relative = Expand-TemplateText $relative
        $destination = Join-Path $DestinationRoot $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        Set-Content -LiteralPath $destination -Value (Expand-TemplateText $content) -Encoding UTF8
    }
}

try {
    $packagePath = $JavaPackage.Replace('.', '\')
    $targetJavaRoot = Join-Path $repoRoot ('src\main\java\' + $packagePath)
    if ($targetJavaRoot -ne (Split-Path -Parent $mainSource)) {
        if (Test-Path -LiteralPath $targetJavaRoot) { throw "目标 Java 包目录已存在：$targetJavaRoot" }
        New-Item -ItemType Directory -Path (Split-Path -Parent $targetJavaRoot) -Force | Out-Null
        Move-Item -LiteralPath (Split-Path -Parent $mainSource) -Destination $targetJavaRoot
    }
    $targetMainSource = Join-Path $targetJavaRoot ($MainClass + '.java')
    $currentMainSource = Join-Path $targetJavaRoot 'ExampleMod.java'
    if ($currentMainSource -ne $targetMainSource) {
        Move-Item -LiteralPath $currentMainSource -Destination $targetMainSource
    }

    $imports = New-Object System.Collections.Generic.List[string]
    $initializers = New-Object System.Collections.Generic.List[string]
    foreach ($module in $Modules) {
        $moduleRoot = Join-Path $templateRoot ('modules\' + $module)
        $javaRoot = Join-Path $moduleRoot 'java'
        $resourceRoot = Join-Path $moduleRoot 'resources'
        Write-ExpandedTemplateTree $javaRoot $targetJavaRoot
        Write-ExpandedTemplateTree $resourceRoot (Join-Path $repoRoot 'src\main\resources')
        $importsFile = Join-Path $moduleRoot 'main-imports.txt'
        $initFile = Join-Path $moduleRoot 'main-init.txt'
        if (Test-Path -LiteralPath $importsFile) {
            (Expand-TemplateText (Get-Content -LiteralPath $importsFile -Raw -Encoding UTF8)).Trim() -split "`r?`n" | ForEach-Object { if ($_) { $imports.Add($_) } }
        }
        if (Test-Path -LiteralPath $initFile) {
            (Expand-TemplateText (Get-Content -LiteralPath $initFile -Raw -Encoding UTF8)).Trim() -split "`r?`n" | ForEach-Object { if ($_) { $initializers.Add('        ' + $_) } }
        }
    }
    if ($Mode -eq 'example') {
        Write-ExpandedTemplateTree (Join-Path $templateRoot 'modes\example\java') $targetJavaRoot
    }

    $mainText = Get-Content -LiteralPath $targetMainSource -Raw -Encoding UTF8
    $mainText = $mainText.Replace('package com.example.examplemod;', "package $JavaPackage;")
    $mainText = $mainText.Replace('ExampleMod', $MainClass)
    $mainText = $mainText.Replace('"example_mod"', '"' + $ModId + '"')
    $mainText = $mainText.Replace('// __OPTIONAL_IMPORTS__', ($imports -join "`n"))
    $mainText = $mainText.Replace('        // __OPTIONAL_INIT__', ($initializers -join "`n"))
    Set-Content -LiteralPath $targetMainSource -Value $mainText.TrimEnd() -Encoding UTF8

    if ($env:MC_MOD_TEMPLATE_TEST_FAIL_AFTER_WRITE -eq '1') {
        throw '测试注入：写入后故障。'
    }

    $targetAssets = Join-Path $repoRoot ('src\main\resources\assets\' + $ModId)
    if ($defaultAssets -ne $targetAssets) {
        if (Test-Path -LiteralPath $targetAssets) { throw "目标资源命名空间已存在：$targetAssets" }
        Move-Item -LiteralPath $defaultAssets -Destination $targetAssets
    }

    $language = [ordered]@{}
    if ($Mode -eq 'example') {
        $language["key.categories.$ModId"] = $ModName
        $language["key.$ModId.example"] = '显示本地示例消息'
        $language["message.$ModId.example"] = "$ModName 客户端示例已触发"
    }
    if ('network' -in $Modules) {
        $language["key.categories.$ModId"] = $ModName
        $language["key.$ModId.send_example"] = '发送示例网络消息'
        $language["message.$ModId.server_received"] = '服务端已安全处理示例消息'
    }
    $languagePath = Join-Path $targetAssets 'lang\en_us.json'
    New-Item -ItemType Directory -Path (Split-Path -Parent $languagePath) -Force | Out-Null
    Set-Content -LiteralPath $languagePath -Value ($language | ConvertTo-Json) -Encoding UTF8

    $propertiesPath = Join-Path $repoRoot 'gradle.properties'
    $propertiesText = Get-Content -LiteralPath $propertiesPath -Raw -Encoding UTF8
    $propertyUpdates = [ordered]@{
        mod_id = $ModId
        mod_name = $ModName
        mod_group = $ModGroup
        mod_version = $ModVersion
        mod_authors = $Author
        mod_license = $License
        mod_description = $Description
        enable_mixin = ('mixin' -in $Modules).ToString().ToLowerInvariant()
        enable_config = ('config' -in $Modules).ToString().ToLowerInvariant()
        enable_network = ('network' -in $Modules).ToString().ToLowerInvariant()
        enable_gametest = ('gametest' -in $Modules).ToString().ToLowerInvariant()
    }
    foreach ($key in $propertyUpdates.Keys) {
        $escaped = [regex]::Escape($key)
        $propertiesText = [regex]::Replace($propertiesText, "(?m)^$escaped=.*$", "$key=$($propertyUpdates[$key])")
    }
    Set-Content -LiteralPath $propertiesPath -Value $propertiesText.TrimEnd() -Encoding UTF8

    $licensePath = Join-Path $repoRoot 'LICENSE.txt'
    if ($License -eq 'MIT') {
        $licenseText = Get-Content -LiteralPath $licensePath -Raw -Encoding UTF8
        $licenseText = $licenseText.Replace('Copyright (c) 2026 Example Author', "Copyright (c) $((Get-Date).Year) $Author")
        Set-Content -LiteralPath $licensePath -Value $licenseText.TrimEnd() -Encoding UTF8
    }
    else {
        $licenseNotice = "License: $License`n`nCopyright (c) $((Get-Date).Year) $Author`n`n分发前请用所选许可证的完整条款替换本文件。"
        Set-Content -LiteralPath $licensePath -Value $licenseNotice -Encoding UTF8
    }

    $legacyPattern = @(
        ('health' + '_control'),
        ('plane-speed' + '-patch'),
        ('DeceasedCraft' + '_Beta')
    ) -join '|'
    $scanRoots = @((Join-Path $repoRoot 'src'), $propertiesPath)
    foreach ($scanRoot in $scanRoots) {
        $scanFiles = if ((Get-Item -LiteralPath $scanRoot).PSIsContainer) { Get-ChildItem -LiteralPath $scanRoot -Recurse -File } else { @(Get-Item -LiteralPath $scanRoot) }
        foreach ($scanFile in $scanFiles) {
            $scanText = Get-Content -LiteralPath $scanFile.FullName -Raw -Encoding UTF8
            if ($scanText -match '__[A-Z][A-Z0-9_]+__' -or $scanText -match $legacyPattern) {
                throw "初始化自检发现未替换标识：$($scanFile.FullName)"
            }
        }
    }

    $state = [ordered]@{
        templateVersion = $templateConfig.templateVersion
        initializedAt = (Get-Date).ToString('o')
        modId = $ModId
        javaPackage = $JavaPackage
        mainClass = $MainClass
        mode = $Mode
        modules = $Modules
    }
    Set-Content -LiteralPath $statePath -Value ($state | ConvertTo-Json -Depth 4) -Encoding UTF8
    Remove-Item -LiteralPath $templateRoot -Recurse -Force
    Remove-Item -LiteralPath $configPath -Force
    $migrationInventory = Join-Path $repoRoot 'docs\migration-inventory.md'
    if (Test-Path -LiteralPath $migrationInventory) {
        Remove-Item -LiteralPath $migrationInventory -Force
    }
    Remove-Item -LiteralPath $workRoot -Recurse -Force

    Write-Host "初始化完成：$ModName ($ModId)"
    Write-Host '下一步：'
    Write-Host '  powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1'
    Write-Host '  powershell -ExecutionPolicy Bypass -File .\scripts\build-local.ps1'
}
catch {
    try { Restore-TemplateBackup } catch { Write-Warning "自动恢复失败：$($_.Exception.Message)" }
    Write-Error "初始化失败，已尝试恢复模板状态：$($_.Exception.Message)"
    exit 1
}
