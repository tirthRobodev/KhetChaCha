# KhetChacha — Automated APK Build & Firebase App Distribution Setup Guide

This guide walks you step-by-step through configuring **GitHub Actions** and **Firebase App Distribution** so that every push to the `main` branch automatically compiles an Android Release APK and delivers it directly to your 3 team members' Android phones.

---

## 📋 System Overview & Project Configuration

Your project's existing verified identifiers (extracted from `google-services.json` and `build.gradle.kts`):

| Property | Value | Notes |
| :--- | :--- | :--- |
| **Firebase Project ID** | `khetchacha-d7afe` | Configured in Firebase Console |
| **Firebase Project Number** | `342078322934` | Google Cloud Project Number |
| **Android App ID** | `1:342078322934:android:17882ed9e3b63e95ca14d7` | Mobile SDK App ID |
| **Package Name** | `com.example.khetchacha` | Preserved untouched |
| **Target Architecture** | ARM64 / Universal Android Release APK | Optimized AOT compilation |
| **Default Tester Group** | `khetchacha-team` | Group name in Firebase Console |

---

## 🛠️ Step 1: Enable Firebase App Distribution & Add Team Members

1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Select your project: **`khetchacha-d7afe`**.
3. In the left-hand navigation sidebar, click on **Release & Monitor** → **App Distribution**.
   *(If prompted for the first time, click **Get started**).*
4. Click on the **Testers & Groups** tab.
5. Under **Groups**, click **Add group**:
   - Name the group: `khetchacha-team`
6. Inside the `khetchacha-team` group, click **Add testers**:
   - Enter the email addresses of your **3 team members** (e.g., `member1@gmail.com, member2@gmail.com, member3@gmail.com`).
   - Click **Save**.
   - Firebase will automatically send an invitation email to each team member.

---

## 🔑 Step 2: Create a Firebase Service Account Key

To allow GitHub Actions to securely upload and distribute APKs without passwords:

1. Open the [Google Cloud Console Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) for project **`khetchacha-d7afe`**.
2. Click **+ CREATE SERVICE ACCOUNT** at the top:
   - **Service account name**: `github-actions-app-distributor`
   - **Service account ID**: `github-actions-app-distributor`
   - Click **CREATE AND CONTINUE**.
3. In the **Grant this service account access to project** step:
   - In the **Select a role** dropdown, search for and choose:  
     👉 **Firebase App Distribution Admin**
   - Click **CONTINUE**, then click **DONE**.
4. In the Service Accounts list, click on the newly created service account:  
   `github-actions-app-distributor@khetchacha-d7afe.iam.gserviceaccount.com`.
5. Navigate to the **KEYS** tab at the top.
6. Click **ADD KEY** → **Create new key**:
   - Choose key type: **JSON**.
   - Click **CREATE**.
7. A `.json` file will download to your computer (e.g. `khetchacha-d7afe-xxxxxx.json`).
   > ⚠️ **CRITICAL SECURITY RULE:** Never commit this file to Git. It contains private cryptographic credentials. Keep it securely on your local computer only.

---

## 🔒 Step 3: Add Secrets to Your GitHub Repository

1. Open your KhetChacha GitHub repository in your web browser.
2. Go to **Settings** (tab at the top right of your repo).
3. In the left sidebar, click **Secrets and variables** → **Actions**.
4. Under **Repository secrets**, click **New repository secret**:
   - **Name:** `FIREBASE_SERVICE_ACCOUNT_KEY`
   - **Secret:** Open the `.json` file downloaded in Step 2 with Notepad or VS Code, copy the **entire contents** (including `{` and `}`), and paste it into the Secret box.
   - Click **Add secret**.
5. (Optional) Click **New repository secret** again:
   - **Name:** `FIREBASE_APP_ID`
   - **Secret:** `1:342078322934:android:17882ed9e3b63e95ca14d7`
   - Click **Add secret**.  
   *(If omitted, the workflow automatically uses this default).*

---

## 📱 Step 4: What Your 3 Team Members Experience

When a build is dispatched, your 3 team members will receive the update automatically:

### Initial Setup (One-time per phone):
1. Each team member receives an email from Firebase: **"You're invited to test KhetChacha"**.
2. They open the email on their Android phone and tap **Get Started**.
3. They accept the invitation using their Google account.
4. They install the lightweight **Firebase App Tester** companion app (or can download directly from Chrome).

### Future Updates (Every Push to `main`):
1. Whenever code is pushed to `main`, GitHub Actions automatically:
   - Validates code formatting and tests.
   - Compiles the release APK with an auto-incremented build number.
   - Uploads the APK to Firebase App Distribution.
2. Team members receive an instant push notification / email:  
   **"A new version of KhetChacha is available (Build #X)"** with the commit changelog.
3. They open the notification, tap **Download**, and tap **Install / Update**.
4. The app updates smoothly in-place without losing local data.

---

## 🚀 Step 5: How to Trigger Builds

### Automatic Trigger:
- Whenever you push or merge completed code into the `main` branch:
  ```bash
  git checkout main
  git merge antigravity/dashboard
  git push origin main
  ```
  GitHub Actions immediately triggers the `.github/workflows/build_and_distribute.yml` workflow.

### Manual Trigger (From GitHub UI):
1. In your GitHub repository, click on the **Actions** tab.
2. In the left sidebar, click **KhetChacha Android Release & Distribution**.
3. Click the **Run workflow** dropdown on the right:
   - Select branch: `main`.
   - Distribute to Firebase: `true` (checked).
   - Optional: Enter custom release notes (e.g. "Testing new Mandi rates & Crop Calendar").
4. Click the green **Run workflow** button.

---

## 🛡️ Reliability & Safety Architecture

- **Fail-Fast Validation:** If tests fail or code analysis detects syntax errors, the pipeline stops immediately. No broken build is ever distributed to testers.
- **Monotonically Increasing Version Codes:** Android requires higher `versionCode` to update existing installations. The workflow automatically sets `versionCode` to `${{ github.run_number }}` so every build cleanly updates over previous builds.
- **Artifact Archiving:** Every compiled APK is automatically archived on GitHub for 30 days under the Actions run artifacts. You can download the `.apk` directly from GitHub at any time.
- **Zero Secrets Leakage:** Keystores, service accounts, and private keys are strictly listed in `.gitignore` and managed exclusively via GitHub Secrets.

