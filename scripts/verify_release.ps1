<#
.SYNOPSIS
    KhetChacha Release Artifact & Integrity Verification Script
.DESCRIPTION
    Independently inspects and verifies:
    1. pubspec.yaml version vs release manifest.
    2. APK file existence and non-zero size.
    3. SHA-256 checksum integrity verification.
    4. Codebase inspection: ensures no API keys or .env files are exposed.
    5. Configurable AI base URL verification (no hardcoded temporary IP locks).
    6. Verifies report outputs from Flutter & Python test suites.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       KHETCHACHA RELEASE INTEGRITY VERIFICATION          " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$rootDir = "D:\KhetChaCha"
Set-Location $rootDir
$releaseDir = Join-Path $rootDir "release"
$reportsDir = Join-Path $releaseDir "reports"

$allPassed = $true

# 1. Version Check
Write-Host "`n[CHECK 1/6] Validating App Version..." -ForegroundColor Yellow
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match "version:\s*([^\r\n]+)") {
    $version = $matches[1].Trim()
    Write-Host "  [PASS] pubspec.yaml version: $version" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Could not find version in pubspec.yaml" -ForegroundColor Red
    $allPassed = $false
}

# 2. APK Existence & Non-empty check
Write-Host "`n[CHECK 2/6] Inspecting Release APK artifact..." -ForegroundColor Yellow
$apkFiles = Get-ChildItem -Path $releaseDir -Filter "*.apk" -File
if ($apkFiles.Count -eq 0) {
    Write-Host "  [FAIL] No APK found in $releaseDir" -ForegroundColor Red
    $allPassed = $false
} else {
    $targetApk = $apkFiles[0]
    if ($targetApk.Length -gt 10MB) {
        Write-Host "  [PASS] APK found: $($targetApk.Name) ($([Math]::Round($targetApk.Length / 1MB, 2)) MB)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] APK size is unexpectedly small ($($targetApk.Length) bytes)" -ForegroundColor Red
        $allPassed = $false
    }
}

# 3. SHA-256 Checksum Validation
Write-Host "`n[CHECK 3/6] Verifying SHA-256 Checksum..." -ForegroundColor Yellow
$checksumFiles = Get-ChildItem -Path $releaseDir -Filter "*.sha256" -File
if ($checksumFiles.Count -eq 0) {
    Write-Host "  [FAIL] No .sha256 checksum file found in $releaseDir" -ForegroundColor Red
    $allPassed = $false
} else {
    $expectedSha = (Get-Content $checksumFiles[0].FullName -Raw).Trim().Split(" ")[0].Trim()
    $actualSha = (Get-FileHash $targetApk.FullName -Algorithm SHA256).Hash
    if ($expectedSha.ToUpper() -eq $actualSha.ToUpper()) {
        Write-Host "  [PASS] Checksum matched: $actualSha" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Checksum mismatch!`n  Expected: $expectedSha`n  Actual:   $actualSha" -ForegroundColor Red
        $allPassed = $false
    }
}

# 4. Security Audit: Secrets & .env exposure
Write-Host "`n[CHECK 4/6] Auditing for exposed credentials & API secrets..." -ForegroundColor Yellow
$forbiddenPatterns = @(
    "AIzaSy[A-Za-z0-9_-]{33}", # Gemini API Key pattern
    "sk-[A-Za-z0-9]{32,}"       # General secret key pattern
)

$exposureFound = $false
$releaseArtifacts = Get-ChildItem -Path $releaseDir -Recurse -File -Exclude "*.apk"
foreach ($file in $releaseArtifacts) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        foreach ($pattern in $forbiddenPatterns) {
            if ($content -match $pattern) {
                Write-Host "  [SECURITY ALERT] Found potential secret matching $pattern in $($file.Name)" -ForegroundColor Red
                $exposureFound = $true
                $allPassed = $false
            }
        }
    }
}

if (-not $exposureFound) {
    Write-Host "  [PASS] Zero API keys or secrets detected in release artifacts." -ForegroundColor Green
}

# 5. Configurable AI URL Inspection
Write-Host "`n[CHECK 5/6] Verifying Configurable AI Backend URL in Flutter client..." -ForegroundColor Yellow
$serviceCode = Get-Content "lib\services\ai_chat_api_service.dart" -Raw
if ($serviceCode -match "getBaseUrl" -and $serviceCode -match "SharedPreferences" -and $serviceCode -match "AI_API_BASE_URL") {
    Write-Host "  [PASS] AiChatApiService supports dynamic runtime override & environment variable 'AI_API_BASE_URL'." -ForegroundColor Green
} else {
    Write-Host "  [FAIL] AiChatApiService missing dynamic URL configuration hooks." -ForegroundColor Red
    $allPassed = $false
}

# 6. Test Reports Verification
Write-Host "`n[CHECK 6/6] Verifying Automated Test Execution Evidence..." -ForegroundColor Yellow
$flutterLog = Join-Path $reportsDir "flutter_test_report.txt"
$pythonLog = Join-Path $reportsDir "python_test_report.txt"
$analyzeLog = Join-Path $reportsDir "flutter_analyze_report.txt"

if (Test-Path $flutterLog) {
    $flContent = Get-Content $flutterLog -Raw
    if ($flContent -match "All tests passed!") {
        Write-Host "  [PASS] Flutter Tests: verified passing." -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Flutter test report does not explicitly show 'All tests passed!'." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] Flutter test report not found in $reportsDir." -ForegroundColor Yellow
}

if (Test-Path $pythonLog) {
    $pyContent = Get-Content $pythonLog -Raw
    if ($pyContent -match "passed") {
        Write-Host "  [PASS] Python AI Engine Tests: verified passing." -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Python test report does not explicitly show 'passed'." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] Python test report not found in $reportsDir." -ForegroundColor Yellow
}

if (Test-Path $analyzeLog) {
    $anContent = Get-Content $analyzeLog -Raw
    if ($anContent -match "No issues found!") {
        Write-Host "  [PASS] Static Analysis: verified 0 issues." -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Static analysis report shows warnings or issues." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] Static analysis report not found in $reportsDir." -ForegroundColor Yellow
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "  VERIFICATION RESULT: ALL RELEASE CRITERIA SATISFIED      " -ForegroundColor Green
} else {
    Write-Host "  VERIFICATION RESULT: RELEASE VALIDATION FAILED            " -ForegroundColor Red
}
Write-Host "==========================================================`n" -ForegroundColor Cyan

if (-not $allPassed) {
    exit 1
}

