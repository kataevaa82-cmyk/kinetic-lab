param([string]$Godot = $(if (Get-Command godot_console -ErrorAction SilentlyContinue) { 'godot_console' } else { 'godot' }), [switch]$SkipTests, [switch]$Unsigned)
$ErrorActionPreference = 'Stop'
$projectDir = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$outputDir = Join-Path $projectDir 'build\rustore'
$resolvedOutputDir = [IO.Path]::GetFullPath($outputDir)
$expectedBuildRoot = [IO.Path]::GetFullPath((Join-Path $projectDir 'build')) + [IO.Path]::DirectorySeparatorChar
if (-not $resolvedOutputDir.StartsWith($expectedBuildRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to clear an output directory outside the build folder: $resolvedOutputDir"
}
# The release keystore never lives in the repository. Godot reads these three variables,
# so the password is passed through the environment and not through a command line.
if (-not $Unsigned) {
    $missing = @('GODOT_ANDROID_KEYSTORE_RELEASE_PATH', 'GODOT_ANDROID_KEYSTORE_RELEASE_USER', 'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD') |
        Where-Object { -not (Test-Path "env:$_") }
    if ($missing) {
        throw "RuStore accepts signed packages only. Set $($missing -join ', '), or pass -Unsigned to build a test package. See docs/rustore-release.md."
    }
    $keystore = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH
    if (-not (Test-Path -LiteralPath $keystore)) { throw "Keystore not found: $keystore" }
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
    & node --test (Join-Path $projectDir 'tests\rustore.test.cjs')
    if ($LASTEXITCODE -ne 0) { throw 'RuStore package verification failed' }
}
$package = Join-Path $outputDir 'KineticLab.apk'
& $Godot --headless --path $projectDir --export-release 'RuStore Android' $package
if ($LASTEXITCODE -ne 0) { throw 'Android export failed' }
if (-not (Test-Path -LiteralPath $package)) { throw 'Android export produced no package' }
$size = (Get-Item -LiteralPath $package).Length
$preset = Select-String -LiteralPath (Join-Path $projectDir 'export_presets.cfg') -Pattern '^version/(code|name)=' | ForEach-Object { $_.Line }
Write-Output "RuStore package: $package ($([Math]::Round($size / 1MB, 2)) MiB)"
Write-Output ($preset -join '  ')
if ($Unsigned) { Write-Warning 'Unsigned package: for local testing only, RuStore will reject it.' }
