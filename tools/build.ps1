param([string]$Godot = $(if (Get-Command godot_console -ErrorAction SilentlyContinue) { 'godot_console' } else { 'godot' }), [switch]$SkipTests)
$ErrorActionPreference = 'Stop'
$projectDir = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$outputDir = Join-Path $projectDir 'build\web'
$resolvedOutputDir = [IO.Path]::GetFullPath($outputDir)
$expectedBuildRoot = [IO.Path]::GetFullPath((Join-Path $projectDir 'build')) + [IO.Path]::DirectorySeparatorChar
if (-not $resolvedOutputDir.StartsWith($expectedBuildRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to clear an output directory outside the build folder: $resolvedOutputDir"
}
if (Test-Path $resolvedOutputDir) {
    Get-ChildItem -LiteralPath $resolvedOutputDir -Force | Remove-Item -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
& $Godot --headless --path $projectDir --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
if (-not $SkipTests) {
    & $Godot --headless --path $projectDir -- --smoke-test
    if ($LASTEXITCODE -ne 0) { throw 'Physics verification failed' }
    & $Godot --headless --path $projectDir --script res://tests/robot_physics.gd
    if ($LASTEXITCODE -ne 0) { throw 'Robot damage and falling verification failed' }
    & node --test (Join-Path $projectDir 'tests\bridge.test.cjs')
    if ($LASTEXITCODE -ne 0) { throw 'SDK bridge verification failed' }
}
& $Godot --headless --path $projectDir --export-release 'Yandex Web' (Join-Path $outputDir 'index.html')
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
Copy-Item -LiteralPath (Join-Path $projectDir 'web\bridge.js') -Destination (Join-Path $outputDir 'bridge.js') -Force
$files = Get-ChildItem -LiteralPath $outputDir -File
$total = ($files | Measure-Object -Property Length -Sum).Sum
if ($total -gt 100000000) { throw 'The unpacked build exceeds the Yandex Games size limit' }
$archive = Join-Path $projectDir 'build\kinetic-lab-yandex.zip'
Compress-Archive -LiteralPath $files.FullName -DestinationPath $archive -Force
Write-Output "Yandex archive: $archive ($([Math]::Round($total / 1MB, 2)) MiB unpacked)"
