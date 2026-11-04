<#
.SYNOPSIS
    KhetChacha Automated Release Preparation Script
.DESCRIPTION
    1. Checks Flutter, Dart, and Python environments.
    2. Formats Dart code (`dart format`).
    3. Runs Flutter static analysis (`flutter analyze lib/ test/`).
    4. Runs Flutter unit & widget tests (`flutter test`).
    5. Runs Python backend tests (`pytest ai_engine/tests/ -v`).
    6. Stops release if any test or check fails.
    7. Builds release APK only after 100% successful test validation.
    8. Copies APK, computes SHA-256 checksum, and generates release metadata.
#>

[CmdletBinding()]
param(
    [switch]$SkipFormat = $false
)

$ErrorActionPreference = "Stop"
$swTotal = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       KHETCHACHA AUTOMATED RELEASE PREPARATION           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$rootDir = "D:\KhetChaCha"
Set-Location $rootDir

# Ensure release output directories exist
$releaseDir = Join-Path $rootDir "release"
$reportsDir = Join-Path $releaseDir "reports"
if (!(Test-Path $releaseDir)) { New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null }
if (!(Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null }

# ---------------------------------------------------------
# STEP 1: Environment & Tooling Verification
# ---------------------------------------------------------
Write-Host "`n[STEP 1/6] Verifying toolchain environment..." -ForegroundColor Yellow

# Flutter check
try {
    $flutterVer = flutter --version | Select-Object -First 1
    Write-Host "  [OK] $flutterVer" -ForegroundColor Green
} catch {
    Write-Error "[FAIL] Flutter SDK is not installed or not in PATH."
    exit 1
}

# Dart check
try {
    $dartVer = dart --version
    Write-Host "  [OK] $dartVer" -ForegroundColor Green
} catch {
    Write-Error "[FAIL] Dart SDK is not installed or not in PATH."
    exit 1
}

# Python check
try {
    $pythonVer = python --version
    Write-Host "  [OK] $pythonVer" -ForegroundColor Green
} catch {
    Write-Error "[FAIL] Python is not installed or not in PATH."
    exit 1
}

# Read Version from pubspec.yaml
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match "version:\s*([^\r\n]+)") {
    $appVersion = $matches[1].Trim()
    Write-Host "  [OK] Target App Version: $appVersion" -ForegroundColor Green
} else {
    Write-Error "[FAIL] Could not parse version from pubspec.yaml."
    exit 1
}

# ---------------------------------------------------------
# STEP 2: Dart Code Formatting
# ---------------------------------------------------------
if (-not $SkipFormat) {
    Write-Host "`n[STEP 2/6] Running Dart code formatter..." -ForegroundColor Yellow
    dart format lib/ test/
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[FAIL] dart format encountered errors."
        exit 1
    }
    Write-Host "  [OK] Dart formatting complete." -ForegroundColor Green
} else {
    Write-Host "`n[STEP 2/6] Dart code formatting skipped by parameter." -ForegroundColor Gray
}

# ---------------------------------------------------------
# STEP 3: Flutter Static Analysis
# ---------------------------------------------------------
Write-Host "`n[STEP 3/6] Running Flutter static analysis (flutter analyze lib/ test/)..." -ForegroundColor Yellow
$analysisLog = Join-Path $reportsDir "flutter_analyze_report.txt"
flutter analyze lib/ test/ | Tee-Object -FilePath $analysisLog
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] Flutter analysis found issues! Release build aborted."
    exit 1
}
Write-Host "  [OK] Static analysis: ZERO issues found." -ForegroundColor Green

# ---------------------------------------------------------
# STEP 4: Flutter Automated Test Suite
# ---------------------------------------------------------
Write-Host "`n[STEP 4/6] Running Flutter unit & widget tests (flutter test)..." -ForegroundColor Yellow
$flutterTestLog = Join-Path $reportsDir "flutter_test_report.txt"
flutter test | Tee-Object -FilePath $flutterTestLog
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] One or more Flutter tests failed! Release build aborted."
    exit 1
}
Write-Host "  [OK] All Flutter tests passed successfully." -ForegroundColor Green

# ---------------------------------------------------------
# STEP 5: Python Backend AI Engine Test Suite
# ---------------------------------------------------------
Write-Host "`n[STEP 5/6] Running Python AI Engine test suite (pytest ai_engine/tests/ -v)..." -ForegroundColor Yellow
$pythonTestLog = Join-Path $reportsDir "python_test_report.txt"
$env:PYTHONIOENCODING = "utf-8"
python -m pytest ai_engine/tests/ -v | Tee-Object -FilePath $pythonTestLog
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] One or more Python AI Engine tests failed! Release build aborted."
    exit 1
}
Write-Host "  [OK] All Python AI Engine tests passed successfully." -ForegroundColor Green

# ---------------------------------------------------------
# STEP 6: Release APK Build & Packaging
# ---------------------------------------------------------
Write-Host "`n[STEP 6/6] Building Flutter Release APK (flutter build apk --release)..." -ForegroundColor Yellow
$buildLog = Join-Path $reportsDir "apk_build_log.txt"
flutter build apk --release | Tee-Object -FilePath $buildLog
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAIL] Release APK build failed!"
    exit 1
}

$sourceApk = "build\app\outputs\flutter-apk\app-release.apk"
if (!(Test-Path $sourceApk)) {
    # Fallback path if standard structure differs
    $sourceApk = "build\app\outputs\apk\release\app-release.apk"
}

if (!(Test-Path $sourceApk)) {
    Write-Error "[FAIL] Built APK not found at expected build output paths."
    exit 1
}

$apkItem = Get-Item $sourceApk
if ($apkItem.Length -le 0) {
    Write-Error "[FAIL] Generated APK file is empty (0 bytes)."
    exit 1
}

$destApk = Join-Path $releaseDir "khetchacha-release-$($appVersion -replace '\+', '_').apk"
Copy-Item $sourceApk -Destination $destApk -Force

# Calculate SHA-256 Checksum
$sha256 = (Get-FileHash $destApk -Algorithm SHA256).Hash
$checksumFile = Join-Path $releaseDir "khetchacha-release-$($appVersion -replace '\+', '_').sha256"
"$sha256  $([System.IO.Path]::GetFileName($destApk))" | Out-File -FilePath $checksumFile -Encoding utf8

# Save Release Metadata Manifest
$manifestFile = Join-Path $releaseDir "RELEASE_MANIFEST.json"
$metadata = @{
    appName         = "KhetChacha"
    version         = $appVersion
    apkFile         = [System.IO.Path]::GetFileName($destApk)
    apkSizeBytes    = $apkItem.Length
    apkSizeMB       = [Math]::Round($apkItem.Length / 1MB, 2)
    sha256          = $sha256
    generatedAtUtc  = [System.DateTime]::UtcNow.ToString("o")
    flutterTests    = "PASSED"
    pythonTests     = "PASSED"
    staticAnalysis  = "PASSED (0 issues)"
}
$metadata | ConvertTo-Json -Depth 4 | Out-File -FilePath $manifestFile -Encoding utf8

$swTotal.Stop()
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "       RELEASE PREPARATION COMPLETE (SUCCESS)             " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  App Version:  $appVersion" -ForegroundColor White
Write-Host "  APK Path:     $destApk" -ForegroundColor White
Write-Host "  APK Size:     $([Math]::Round($apkItem.Length / 1MB, 2)) MB" -ForegroundColor White
Write-Host "  SHA256:       $sha256" -ForegroundColor Yellow
Write-Host "  Checksum Doc: $checksumFile" -ForegroundColor White
Write-Host "  Manifest:     $manifestFile" -ForegroundColor White
Write-Host "  Time Elapsed: $([Math]::Round($swTotal.Elapsed.TotalSeconds, 1)) seconds" -ForegroundColor White
Write-Host "==========================================================`n" -ForegroundColor Green

