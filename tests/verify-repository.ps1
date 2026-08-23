$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Get-Content -LiteralPath (Join-Path $repoRoot '.vscode\settings.json') -Raw | ConvertFrom-Json | Out-Null
Get-Content -LiteralPath (Join-Path $repoRoot '.vscode\tasks.json') -Raw | ConvertFrom-Json | Out-Null
Get-Content -LiteralPath (Join-Path $repoRoot '.vscode\forge-mod.code-snippets') -Raw | ConvertFrom-Json | Out-Null

$deliveryRoots = @('src', 'template', 'scripts', '.vscode', 'skills\forge-mod-development', 'README.md', 'docs\开发指南.md')
$patterns = @('health_control', 'plane-speed-patch', 'plane_speed_patch', 'SimplePlanes', 'Immersive Aircraft', 'DeceasedCraft_Beta', 'C:\\Program Files\\Java\\latest\\jdk-21', 'E:\\Games\\MC')
$violations = New-Object System.Collections.Generic.List[string]
foreach ($relative in $deliveryRoots) {
    $path = Join-Path $repoRoot $relative
    $files = if ((Get-Item -LiteralPath $path).PSIsContainer) { Get-ChildItem -LiteralPath $path -Recurse -File } else { @(Get-Item -LiteralPath $path) }
    foreach ($file in $files) {
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        foreach ($pattern in $patterns) {
            if ($content -match $pattern) { $violations.Add("$($file.FullName): $pattern") }
        }
    }
}
if ($violations.Count -gt 0) { throw "模板交付内容包含旧标识或个人路径：`n$($violations -join "`n")" }

$mainSource = Get-Content -LiteralPath (Join-Path $repoRoot 'src\main\java\com\example\examplemod\ExampleMod.java') -Raw
if ($mainSource -match 'net\.minecraft\.client|org\.lwjgl') { throw '公共主类引用了客户端专属类。' }

Write-Host '仓库 JSON、旧标识、个人路径和公共入口端侧检查通过。'
