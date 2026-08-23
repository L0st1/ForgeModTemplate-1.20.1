[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+(\.\d+)?$')]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$ForgeVersion,

    [Parameter(Mandatory = $true)]
    [string]$ForgeLoaderRange,

    [Parameter(Mandatory = $true)]
    [string]$MinecraftRange,

    [ValidateSet(8, 17, 21)]
    [int]$JavaVersion = 17,

    [string]$BaseBranch = 'main'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot
try {
    $status = git status --porcelain
    if ($status) {
        throw '工作区不是干净的。请先提交或暂存当前修改，再创建版本分支。'
    }

    $branch = "mc-$Version"
    git show-ref --verify --quiet "refs/heads/$branch"
    if ($LASTEXITCODE -eq 0) {
        throw "本地分支已存在：$branch"
    }

    git switch $BaseBranch
    git switch -c $branch

    $propertiesPath = Join-Path $repoRoot 'gradle.properties'
    $properties = Get-Content -LiteralPath $propertiesPath -Raw -Encoding UTF8
    $updates = [ordered]@{
        minecraft_version = $Version
        forge_version = $ForgeVersion
        forge_loader_version_range = $ForgeLoaderRange
        forge_dependency_version_range = $ForgeLoaderRange
        minecraft_version_range = $MinecraftRange
        mapping_version = $Version
        java_version = $JavaVersion
    }
    foreach ($key in $updates.Keys) {
        $escapedKey = [regex]::Escape($key)
        $value = [string]$updates[$key]
        $properties = [regex]::Replace($properties, "(?m)^$escapedKey=.*$", "$key=$value")
    }
    Set-Content -LiteralPath $propertiesPath -Value $properties.TrimEnd() -Encoding UTF8

    git add gradle.properties
    git commit -m "配置 Minecraft $Version 版本分支"
    Write-Host "已创建并配置分支：$branch"
    Write-Host '请检查 Forge MDK 对应的源码、资源格式和 Gradle Wrapper，然后运行：'
    Write-Host '  .\gradlew.bat build'
    Write-Host "  git push -u origin $branch"
}
finally {
    Pop-Location
}
