# ==============================================================================
# KhetChacha Agriculture AI Engine - Persistent Production Starter Script
# ==============================================================================
# Starts a single, long-running persistent Uvicorn server on 0.0.0.0:8000.
# No reload flags. Reuses warm state across all incoming farmer chat queries.
# ==============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$PidFile = Join-Path $ScriptDir "khetchacha_backend.pid"
$HealthUrl = "http://127.0.0.1:8000/health"
$PhysicalIp = "10.180.217.194"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "    KHETCHACHA AI ENGINE - PERSISTENT SERVICE MANAGER    " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# 1. Check if backend is ALREADY running and healthy
$AlreadyRunning = $false
try {
    $resp = Invoke-RestMethod -Uri $HealthUrl -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($resp.status -eq "healthy") {
        $AlreadyRunning = $true
    }
} catch {
    $AlreadyRunning = $false
}

if ($AlreadyRunning) {
    Write-Host "[OK] KhetChacha Backend is ALREADY RUNNING and healthy!" -ForegroundColor Cyan
    # Refresh PID directly from active listening port 8000
    $conn = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) {
        $conn.OwningProcess | Out-File -FilePath $PidFile -Encoding ascii
        Write-Host "     Active Process PID (port 8000): $($conn.OwningProcess)" -ForegroundColor Cyan
    } elseif (Test-Path $PidFile) {
        $currentPid = Get-Content $PidFile -ErrorAction SilentlyContinue
        Write-Host "     Active Process PID (from file): $currentPid" -ForegroundColor Cyan
    }
    Write-Host "     Local API URL:       http://localhost:8000" -ForegroundColor White
    Write-Host "     Physical Device URL: http://${PhysicalIp}:8000" -ForegroundColor Yellow
    Write-Host "     Health Endpoint:     http://${PhysicalIp}:8000/health" -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
    exit 0
}

# 2. Cleanup stale PID file if present
if (Test-Path $PidFile) {
    Remove-Item -Path $PidFile -Force -ErrorAction SilentlyContinue
}

# 3. Locate Python executable
$PythonPath = "python"
$VenvPython = Join-Path $ScriptDir ".venv\Scripts\python.exe"
if (Test-Path $VenvPython) {
    $PythonPath = $VenvPython
    Write-Host "[INFO] Using virtual environment Python: $PythonPath" -ForegroundColor Gray
} else {
    Write-Host "[INFO] Using system Python" -ForegroundColor Gray
}

# 4. Start single persistent Uvicorn process via WMI (detached from console session)
Write-Host "[INFO] Starting persistent KhetChacha AI Engine on 0.0.0.0:8000..." -ForegroundColor Yellow

$cmdLine = "`"$PythonPath`" -m uvicorn ai_engine.backend.main:app --host 0.0.0.0 --port 8000 --log-level info"
$procResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
    CommandLine = $cmdLine
    CurrentDirectory = $ProjectRoot
}

if ($procResult.ReturnValue -ne 0) {
    Write-Error "[FAIL] Failed to launch Python process (Return code: $($procResult.ReturnValue))."
    exit 1
}

# Save spawned PID
$spawnedPid = $procResult.ProcessId
$spawnedPid | Out-File -FilePath $PidFile -Encoding ascii
Write-Host "[OK] Server process spawned with PID $spawnedPid." -ForegroundColor Green

# 5. Wait for warm server readiness
Write-Host "[INFO] Waiting for service container warmup and health check..." -NoNewline
$isHealthy = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500
    Write-Host "." -NoNewline
    try {
        $check = Invoke-RestMethod -Uri $HealthUrl -Method Get -TimeoutSec 1 -ErrorAction SilentlyContinue
        if ($check.status -eq "healthy") {
            $isHealthy = $true
            break
        }
    } catch {
        # continue waiting
    }
}
Write-Host ""

if ($isHealthy) {
    # Ensure PID file reflects the actual listening process on port 8000
    $conn = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    $actualPid = if ($conn) { $conn.OwningProcess } else { $process.Id }
    $actualPid | Out-File -FilePath $PidFile -Encoding ascii

    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] KhetChacha AI Engine is Online and Persistent!" -ForegroundColor Green
    Write-Host "     Process PID:         $actualPid" -ForegroundColor Cyan
    Write-Host "     Local API URL:       http://localhost:8000" -ForegroundColor White
    Write-Host "     Physical Device URL: http://${PhysicalIp}:8000" -ForegroundColor Yellow
    Write-Host "     Health Check:        http://${PhysicalIp}:8000/health" -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Server spawned (PID $($process.Id)), but /health did not respond within 15s." -ForegroundColor Yellow
    Write-Host "Check terminal logs or verify port 8000." -ForegroundColor Yellow
}

