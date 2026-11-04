# KhetChacha Release Handoff Guide

## Release Summary
- **Target App Version**: 1.0.0+1
- **Git Branch**: $currentBranch
- **Current HEAD Commit**: $headCommit
- **Generated At (UTC)**: 2026-11-04 20:14:03 UTC
- **APK Checksum**: 9F4ADF8F3FB2035FBF043A70B72918EEA39C446038CA0CE11A3EDDD17178FF8B  khetchacha-release-1.0.0_1.apk

---

## 1. Test Verification Status
- **Flutter Test Suite**: 225/225 passed (see eports/flutter_test_report.txt)
- **Python AI Engine Test Suite**: 75/75 passed (see eports/python_test_report.txt)
- **Static Code Analysis**: 0 issues found (see eports/flutter_analyze_report.txt)

---

## 2. Uncommitted Working Tree Changes
`	ext
 M ai_engine/backend/main.py
 M ai_engine/data/agriculture_pdfs/test_upload_advisory.pdf
 M ai_engine/gemini/response_generator.py
 M ai_engine/khetchacha_backend.pid
 M lib/localization/govt_scheme_localization.dart
 M lib/models/ai_chat_models.dart
 M lib/screens/quick_access/ask_khet_chacha_ai_page.dart
 M lib/screens/schemes/govt_schemes_directory_page.dart
 M lib/services/ai_chat_api_service.dart
 M lib/services/ai_chat_tts_service.dart
 M lib/services/govt_scheme_service.dart
 M lib/services/language_detection_helper.dart
 M test/ai_chat_api_service_test.dart
 M test/ai_chat_multilingual_tts_test.dart
?? ai_engine/tests/test_multilingual_encoding.py
?? release/
?? scripts/
?? test/multilingual_encoding_test.dart

`

## 3. Unpushed Commits (Ahead of origin/main)
`	ext
ccfbeb4 fix: improve agricultural answer safety and persistent AI backend

`

---

## 4. Critical Git Advisory: Tracked Large Files (>50 MB)
The following files were previously committed in local history and exceed or approach GitHub's 100 MB upload limit:

| File Path | Size | GitHub Impact |
|:---|:---|:---|
| $(@{Path=finalsceme.zip; SizeMB=212.57}.Path) | 212.57 MB | âš ï¸ BLOCKS PUSH (>100 MB) |
| $(@{Path=government_schemes_extracted/finalsceme/gujrat.zip; SizeMB=167.8}.Path) | 167.8 MB | âš ï¸ BLOCKS PUSH (>100 MB) |
| $(@{Path=scheme_extractor/venv/Lib/site-packages/playwright/driver/node.exe; SizeMB=89.56}.Path) | 89.56 MB | âš ï¸ Warning (>50 MB) |

### Recommended Action for Publisher:
To prevent GitHub remote rejection, ensure files > 100 MB (such as .zip or node executables) are either:
1. Untracked from Git without deleting working files:
   `ash
   git rm --cached finalsceme.zip
   git rm --cached government_schemes_extracted/finalsceme/gujrat.zip
   git rm --cached scheme_extractor/venv/Lib/site-packages/playwright/driver/node.exe
   git commit -m "chore: remove large zip binaries from git index"
   `
2. Or added to .gitignore to prevent future tracking.

---

## 5. Step-by-Step GitHub Release Instructions (For Friend)

### Step A: Verify the Package
Run integrity checks before publishing:
`powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_release.ps1
`

### Step B: Stage and Commit Desired Code Changes
Review the status and stage only code and tests (never .env):
`ash
git add lib/
git add test/
git add ai_engine/backend/
git add ai_engine/gemini/
git add ai_engine/tests/
git add scripts/
git commit -m "feat(release): v1.0.0+1 production release with multilingual UTF-8 fixes"
`

### Step C: Push to GitHub Main
`ash
git push origin main
`

### Step D: Create GitHub Release with APK
`ash
gh release create v1.0.0+1 
  release/khetchacha-release-1.0.0_1.apk 
  release/khetchacha-release-1.0.0_1.sha256 
  --title "KhetChacha 1.0.0+1 Production Release" 
  --notes "Full production APK with Indic multilingual AI chat, ICAR safety guards, and offline agronomic fallbacks."
`

---

## 6. Tester Instructions (For Android Device Validation)
1. Transfer khetchacha-release-1.0.0_1.apk to an Android phone.
2. Ensure Developer Options allows "Install Unknown Apps".
3. Install the APK:
   `ash
   adb install -r release/khetchacha-release-1.0.0_1.apk
   `
4. Verify Gujarati AI advisory in the chat page renders clean Gujarati text without Ã Âª... character corruption.
