# ============================================
# PDF Viewer - Quick Start Script
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   PDF Viewer - Quick Start" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get parent directory (project root)
$projectRoot = Split-Path -Parent $PSScriptRoot

# 1. Start the API
Write-Host "[1/3] Starting PDF Conversion API..." -ForegroundColor Green
$apiProcess = Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectRoot'; dotnet run" -PassThru
Write-Host "      API starting... (PID: $($apiProcess.Id))" -ForegroundColor Gray

# 2. Wait for API to be ready
Write-Host "[2/3] Waiting for API to be ready..." -ForegroundColor Green
Start-Sleep -Seconds 8

$apiReady = $false
$retries = 0
$maxRetries = 10

while (-not $apiReady -and $retries -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5063/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $apiReady = $true
            Write-Host "      API is ready!" -ForegroundColor Gray
        }
    }
    catch {
        $retries++
        Write-Host "      Waiting... ($retries/$maxRetries)" -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if (-not $apiReady) {
    Write-Host ""
    Write-Host "WARNING: API might not be ready yet." -ForegroundColor Yellow
    Write-Host "You can still try opening the browser, it might work." -ForegroundColor Yellow
    Write-Host ""
}

# 3. Open the browser
Write-Host "[3/3] Opening browser..." -ForegroundColor Green
Start-Sleep -Seconds 1
Start-Process "http://localhost:5063"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available URLs:" -ForegroundColor White
Write-Host "  Home Page:       " -NoNewline; Write-Host "http://localhost:5063" -ForegroundColor Cyan
Write-Host "  PDF Viewer:      " -NoNewline; Write-Host "http://localhost:5063/pdf-viewer.html" -ForegroundColor Cyan
Write-Host "  API Docs:        " -NoNewline; Write-Host "http://localhost:5063/swagger" -ForegroundColor Cyan
Write-Host ""
Write-Host "To stop the API, close the API PowerShell window or press Ctrl+C" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit this window..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
