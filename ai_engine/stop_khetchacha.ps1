# ==============================================================================
# KhetChacha Agriculture AI Engine - Stop Script
# ==============================================================================
# Safely stops the persistent backend process and cleans up PID tracking.
# ==============================================================================

$ErrorActionPreference = "SilentlyContinue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PidFile = Join-Path $ScriptDir "khetchacha_backend.pid"

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "    KHETCHACHA AI ENGINE - SERVICE SHUTDOWN MANAGER      " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$stopped = $false

# 1. Stop by saved PID if present
if (Test-Path $PidFile) {
    $pidToStop = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($pidToStop) {
        $p = Get-Process -Id $pidToStop -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "[INFO] Stopping KhetChacha process PID $pidToStop..." -ForegroundColor Yellow
            Stop-Process -Id $pidToStop -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            $stopped = $true
        }
    }
    Remove-Item -Path $PidFile -Force -ErrorAction SilentlyContinue
}

# 2. Check any remaining listener on port 8000
$portConnections = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
foreach ($conn in $portConnections) {
    if ($conn.OwningProcess -and $conn.OwningProcess -gt 0) {
        Write-Host "[INFO] Freeing port 8000 listener PID $($conn.OwningProcess)..." -ForegroundColor Yellow
        Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
        $stopped = $true
    }
}

if ($stopped) {
    Write-Host "[SUCCESS] KhetChacha AI Engine stopped cleanly and port 8000 released." -ForegroundColor Green
} else {
    Write-Host "[INFO] No active KhetChacha process was found running on port 8000." -ForegroundColor Cyan
}
Write-Host "==========================================================" -ForegroundColor Yellow

