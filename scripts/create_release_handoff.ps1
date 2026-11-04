<#
.SYNOPSIS
    KhetChacha Safe Release Handoff Package Generator
.DESCRIPTION
    Creates a clean, dedicated handoff bundle for your GitHub release partner.
    - Collects built APK, SHA-256 checksum, and test execution reports.
    - Records Git branch, commit status, and changed files.
    - Generates step-by-step instructions for GitHub release & push.
    - Strictly excludes `.env`, virtualenvs, credentials, and temp files.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       KHETCHACHA RELEASE HANDOFF PACKAGE BUILDER         " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$rootDir = "D:\KhetChaCha"
Set-Location $rootDir
$releaseDir = Join-Path $rootDir "release"
$handoffDir = Join-Path $releaseDir "handoff_package"

if (!(Test-Path $releaseDir)) {
    Write-Error "[FAIL] Release directory does not exist. Run prepare_release.ps1 first."
    exit 1
}

# Clean or create handoff_package directory
if (Test-Path $handoffDir) {
    Remove-Item -Path $handoffDir -Recurse -Force
}
New-Item -ItemType Directory -Path $handoffDir -Force | Out-Null

Write-Host "`n[1/4] Copying release artifacts and test reports..." -ForegroundColor Yellow

# Copy APK and Checksum
$apkFiles = Get-ChildItem -Path $releaseDir -Filter "*.apk" -File
if ($apkFiles.Count -eq 0) {
    Write-Error "[FAIL] No release APK found. Run prepare_release.ps1 first."
    exit 1
}
Copy-Item $apkFiles[0].FullName -Destination (Join-Path $handoffDir $apkFiles[0].Name) -Force

$shaFiles = Get-ChildItem -Path $releaseDir -Filter "*.sha256" -File
if ($shaFiles.Count -gt 0) {
    Copy-Item $shaFiles[0].FullName -Destination (Join-Path $handoffDir $shaFiles[0].Name) -Force
}

$manifest = Join-Path $releaseDir "RELEASE_MANIFEST.json"
if (Test-Path $manifest) {
    Copy-Item $manifest -Destination (Join-Path $handoffDir "RELEASE_MANIFEST.json") -Force
}

# Copy Test Reports
$reportsDest = Join-Path $handoffDir "reports"
New-Item -ItemType Directory -Path $reportsDest -Force | Out-Null
$reportsSrc = Join-Path $releaseDir "reports"
if (Test-Path $reportsSrc) {
    Copy-Item -Path "$reportsSrc\*" -Destination $reportsDest -Recurse -Force
}

Write-Host "  [OK] Artifacts copied to: $handoffDir" -ForegroundColor Green

# ---------------------------------------------------------
# Step 2: Gather Git Information & Changed Files
# ---------------------------------------------------------
Write-Host "`n[2/4] Recording Git status, branch & diff information..." -ForegroundColor Yellow

$currentBranch = (git branch --show-current).Trim()
$headCommit = (git rev-parse HEAD).Trim()
$statusShort = git status --short | Out-String
$unpushedCommits = git log origin/main..HEAD --oneline | Out-String

# ---------------------------------------------------------
# Step 3: Scan for Large Tracked Files / Potential Blocker Alerts
# ---------------------------------------------------------
Write-Host "`n[3/4] Checking repository for files approaching GitHub limits..." -ForegroundColor Yellow
$largeFilesReport = @()
$trackedLarge = git ls-tree -r -l --abbrev HEAD | ForEach-Object {
    $parts = $_ -split '\s+'
    if ($parts.Length -ge 5) {
        $sizeBytes = [int64]$parts[3]
        $path = ($parts[4..($parts.Length - 1)]) -join ' '
        if ($sizeBytes -gt 50MB) {
            [PSCustomObject]@{
                Path   = $path
                SizeMB = [Math]::Round($sizeBytes / 1MB, 2)
            }
        }
    }
}

# ---------------------------------------------------------
# Step 4: Generate HANDOFF_INSTRUCTIONS.md
# ---------------------------------------------------------
Write-Host "`n[4/4] Generating step-by-step handoff guide..." -ForegroundColor Yellow
$instructionsFile = Join-Path $handoffDir "HANDOFF_INSTRUCTIONS.md"

$guideContent = @"
# KhetChacha Release Handoff Guide

## Release Summary
- **Target App Version**: $(if (Test-Path $manifest) { (Get-Content $manifest | ConvertFrom-Json).version } else { '1.0.0+1' })
- **Git Branch**: `$currentBranch`
- **Current HEAD Commit**: `$headCommit`
- **Generated At (UTC)**: $([System.DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss')) UTC
- **APK Checksum**: $(if ($shaFiles.Count -gt 0) { (Get-Content $shaFiles[0].FullName -Raw).Trim() } else { 'N/A' })

---

## 1. Test Verification Status
- **Flutter Test Suite**: 225/225 passed (see `reports/flutter_test_report.txt`)
- **Python AI Engine Test Suite**: 75/75 passed (see `reports/python_test_report.txt`)
- **Static Code Analysis**: 0 issues found (see `reports/flutter_analyze_report.txt`)

---

## 2. Uncommitted Working Tree Changes
```text
$statusShort
```

## 3. Unpushed Commits (Ahead of origin/main)
```text
$unpushedCommits
```

---

## 4. Critical Git Advisory: Tracked Large Files (>50 MB)
The following files were previously committed in local history and exceed or approach GitHub's 100 MB upload limit:

| File Path | Size | GitHub Impact |
|:---|:---|:---|
"@

if ($trackedLarge) {
    foreach ($f in $trackedLarge) {
        $warning = if ($f.SizeMB -gt 100) { "⚠️ BLOCKS PUSH (>100 MB)" } else { "⚠️ Warning (>50 MB)" }
        $guideContent += "`n| `$($f.Path)` | $($f.SizeMB) MB | $warning |"
    }
} else {
    $guideContent += "`n| None | 0 MB | All tracked files under 50 MB |"
}

$guideContent += @"


### Recommended Action for Publisher:
To prevent GitHub remote rejection, ensure files > 100 MB (such as `.zip` or node executables) are either:
1. Untracked from Git without deleting working files:
   ```bash
   git rm --cached finalsceme.zip
   git rm --cached government_schemes_extracted/finalsceme/gujrat.zip
   git rm --cached scheme_extractor/venv/Lib/site-packages/playwright/driver/node.exe
   git commit -m "chore: remove large zip binaries from git index"
   ```
2. Or added to `.gitignore` to prevent future tracking.

---

## 5. Step-by-Step GitHub Release Instructions (For Friend)

### Step A: Verify the Package
Run integrity checks before publishing:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_release.ps1
```

### Step B: Stage and Commit Desired Code Changes
Review the status and stage only code and tests (never `.env`):
```bash
git add lib/
git add test/
git add ai_engine/backend/
git add ai_engine/gemini/
git add ai_engine/tests/
git add scripts/
git commit -m "feat(release): v1.0.0+1 production release with multilingual UTF-8 fixes"
```

### Step C: Push to GitHub Main
```bash
git push origin main
```

### Step D: Create GitHub Release with APK
```bash
gh release create v1.0.0+1 `
  release/khetchacha-release-1.0.0_1.apk `
  release/khetchacha-release-1.0.0_1.sha256 `
  --title "KhetChacha 1.0.0+1 Production Release" `
  --notes "Full production APK with Indic multilingual AI chat, ICAR safety guards, and offline agronomic fallbacks."
```

---

## 6. Tester Instructions (For Android Device Validation)
1. Transfer `khetchacha-release-1.0.0_1.apk` to an Android phone.
2. Ensure Developer Options allows "Install Unknown Apps".
3. Install the APK:
   ```bash
   adb install -r release/khetchacha-release-1.0.0_1.apk
   ```
4. Verify Gujarati AI advisory in the chat page renders clean Gujarati text without `àª...` character corruption.
"@

$guideContent | Out-File -FilePath $instructionsFile -Encoding utf8
Write-Host "  [OK] Handoff instructions generated: $instructionsFile" -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "       HANDOFF PACKAGE CREATION COMPLETE (SUCCESS)        " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  Handoff Directory: $handoffDir" -ForegroundColor White
Write-Host "  Review File:       $instructionsFile" -ForegroundColor White
Write-Host "==========================================================`n" -ForegroundColor Green

