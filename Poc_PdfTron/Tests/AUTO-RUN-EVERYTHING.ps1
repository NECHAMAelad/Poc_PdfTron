# ============================================================================
# ?? Automated Load Test Runner
# ============================================================================
# This script automatically:
#   1. Starts the server
#   2. Waits for it to be ready
#   3. Runs the load test with concurrent conversions
#   4. Generates a detailed report
# ============================================================================

param(
    [int]$MaxParallel = 20,  # Optimal setting based on load testing (was 10)
    [int]$WaitForServerSeconds = 45
)

$ErrorActionPreference = "Continue"

Clear-Host

Write-Host ""
Write-Host "??????????????????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?              ?? Automated Load Test - PDF Conversion API                   ?" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

$currentDir = Get-Location
$InputDir = "C:\Temp\Input"
$BaseUrl = "http://localhost:5063"

# ============================================================================
# Step 1: Pre-flight Checks
# ============================================================================

Write-Host "?? Step 1: Pre-flight Checks" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

# Check input directory
if (-not (Test-Path $InputDir)) {
    Write-Host "  ??  Input directory doesn't exist. Creating..." -ForegroundColor Yellow
    New-Item -Path $InputDir -ItemType Directory -Force | Out-Null
    Write-Host "  ? Directory created: $InputDir" -ForegroundColor Green
}

$files = @(Get-ChildItem -Path $InputDir -File -ErrorAction SilentlyContinue)
$fileCount = $files.Count

if ($fileCount -eq 0) {
    Write-Host "  ? No files in directory!" -ForegroundColor Red
    Write-Host ""
    Write-Host "     Copy test files to: $InputDir" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter after copying files..."
    
    $files = @(Get-ChildItem -Path $InputDir -File -ErrorAction SilentlyContinue)
    $fileCount = $files.Count
    
    if ($fileCount -eq 0) {
        Write-Host "  ? Still no files! Aborting." -ForegroundColor Red
        exit 1
    }
}

Write-Host "  ? Found $fileCount files" -ForegroundColor Green

# File breakdown
$totalSizeMB = [math]::Round(($files | Measure-Object Length -Sum).Sum / 1MB, 2)
Write-Host ""
Write-Host "     ?? Breakdown:" -ForegroundColor White
$files | Group-Object Extension | Sort-Object Name | ForEach-Object {
    $sizeMB = [math]::Round(($_.Group | Measure-Object Length -Sum).Sum / 1MB, 2)
    Write-Host "        • $($_.Name.PadRight(7)): $($_.Count.ToString().PadLeft(3)) files ($sizeMB MB)" -ForegroundColor Gray
}
Write-Host "        • Total: $fileCount files ($totalSizeMB MB)" -ForegroundColor White
Write-Host ""

# Check if server is already running
Write-Host "  ?? Checking if server is running..." -ForegroundColor Gray
$serverAlreadyRunning = $false
try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -TimeoutSec 2 -ErrorAction Stop
    Write-Host "  ? Server is already running!" -ForegroundColor Green
    $serverAlreadyRunning = $true
}
catch {
    Write-Host "  ??  Server not running - will start shortly" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# Step 2: Start Server (if not running)
# ============================================================================

if (-not $serverAlreadyRunning) {
    Write-Host "?? Step 2: Starting Server" -ForegroundColor Yellow
    Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host ""

    $serverScript = Join-Path $currentDir "start-both.ps1"
    
    if (-not (Test-Path $serverScript)) {
        Write-Host "  ? Server script not found: $serverScript" -ForegroundColor Red
        exit 1
    }

    Write-Host "  ?? Opening server window..." -ForegroundColor White
    
    # Open separate PowerShell window for server
    $serverProcess = Start-Process powershell -ArgumentList `
        "-NoExit", `
        "-Command", `
        "& { Set-Location '$currentDir'; .\start-both.ps1 }" `
        -PassThru
    
    Write-Host "  ? Server window opened (PID: $($serverProcess.Id))" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ? Waiting $WaitForServerSeconds seconds for server to start..." -ForegroundColor Yellow
    
    # Wait with progress bar
    for ($i = 1; $i -le $WaitForServerSeconds; $i++) {
        Start-Sleep -Seconds 1
        
        $percent = [math]::Round(($i / $WaitForServerSeconds) * 100)
        $bar = "?" * [math]::Floor($percent / 5)
        $spaces = " " * (20 - $bar.Length)
        
        Write-Host "`r     [$bar$spaces] $percent% ($i/$WaitForServerSeconds seconds)" -NoNewline -ForegroundColor Cyan
        
        # Check every 5 seconds
        if ($i % 5 -eq 0 -and $i -ge 10) {
            try {
                $health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -TimeoutSec 2 -ErrorAction Stop
                Write-Host ""
                Write-Host "  ? Server ready! (after $i seconds)" -ForegroundColor Green
                break
            }
            catch {
                # Continue waiting
            }
        }
    }
    
    Write-Host ""
    Write-Host ""
    
    # Final verification
    try {
        $health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
        Write-Host "  ? Final check: Server is responding!" -ForegroundColor Green
    }
    catch {
        Write-Host "  ? Server not responding after $WaitForServerSeconds seconds" -ForegroundColor Red
        Write-Host "     Check the server window for errors" -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne 'y') {
            exit 1
        }
    }
    
    Write-Host ""
}

# ============================================================================
# Step 3: Measure Initial Resources
# ============================================================================

Write-Host "?? Step 3: Measuring Initial Resources" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

$initialCpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$os = Get-CimInstance Win32_OperatingSystem
$totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMemoryGB = [math]::Round($totalMemoryGB - $freeMemoryGB, 2)

Write-Host "  • CPU: $initialCpu%" -ForegroundColor Gray
Write-Host "  • Memory: $usedMemoryGB GB / $totalMemoryGB GB" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# Step 4: Run Load Test
# ============================================================================

Write-Host "?? Step 4: Running Load Test" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ?? Test Parameters:" -ForegroundColor White
Write-Host "     • Files: $fileCount" -ForegroundColor Gray
Write-Host "     • Parallelism: $MaxParallel concurrent conversions" -ForegroundColor Gray
Write-Host "     • Input: $InputDir" -ForegroundColor Gray
Write-Host ""

$testScript = Join-Path $currentDir "test-concurrent-load.ps1"

if (-not (Test-Path $testScript)) {
    Write-Host "  ? Test script not found: $testScript" -ForegroundColor Red
    exit 1
}

Write-Host "  ?? Opening test window..." -ForegroundColor White

# Open separate PowerShell window for testing
$testCommand = @"
Set-Location '$currentDir'
Write-Host ''
Write-Host '??????????????????????????????????????????????????????????????????????????????' -ForegroundColor Cyan
Write-Host '?                    ?? Load Test - Running!                                 ?' -ForegroundColor Cyan
Write-Host '??????????????????????????????????????????????????????????????????????????????' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Running test with $MaxParallel parallel conversions...' -ForegroundColor Yellow
Write-Host ''

.\test-concurrent-load.ps1 -MaxParallel $MaxParallel -InputDir '$InputDir' -BaseUrl '$BaseUrl'

Write-Host ''
Write-Host '????????????????????????????????????????????????????????????????????????????' -ForegroundColor Cyan
Write-Host ''
Write-Host '? Test Complete!' -ForegroundColor Green
Write-Host ''
Write-Host 'To view detailed analysis, run:' -ForegroundColor Yellow
Write-Host '   .\analyze-results.ps1' -ForegroundColor Cyan
Write-Host ''
Write-Host 'This window will stay open - you can review the results' -ForegroundColor Gray
Write-Host ''
Read-Host 'Press Enter to close'
"@

$testProcess = Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    $testCommand `
    -PassThru

Write-Host "  ? Test window opened (PID: $($testProcess.Id))" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 5: Monitor and Wait
# ============================================================================

Write-Host "?? Step 5: Monitoring Test" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  ?? Two windows are now open:" -ForegroundColor White
Write-Host "     1??  Server window (green) - Shows conversion logs" -ForegroundColor Gray
Write-Host "     2??  Test window (blue) - Shows progress and stats" -ForegroundColor Gray
Write-Host ""

Write-Host "  ??  Estimated time: $([math]::Round($fileCount / 2, 0))-$([math]::Round($fileCount * 2, 0)) seconds" -ForegroundColor Gray
Write-Host "     (depends on file size and complexity)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  ?? Monitoring for report creation..." -ForegroundColor White
Write-Host ""

# Wait for report to be created
$reportCreated = $false
$checkCount = 0
$maxChecks = 120  # 2 minutes max wait

while (-not $reportCreated -and $checkCount -lt $maxChecks) {
    Start-Sleep -Seconds 1
    $checkCount++
    
    # Check for new report
    $latestReport = Get-ChildItem -Path $currentDir -Filter "LOAD_TEST_REPORT_*.md" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    
    if ($latestReport) {
        $reportCreated = $true
    }
    
    # Show dots every 5 seconds
    if ($checkCount % 5 -eq 0) {
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }
}

if ($reportCreated) {
    Write-Host ""
    Write-Host ""
    Write-Host "  ? Test completed!" -ForegroundColor Green
    Write-Host "  ?? Report created: $($latestReport.Name)" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host ""
    Write-Host "  ??  Test still running (or report not found)" -ForegroundColor Yellow
    Write-Host "     Check the test window" -ForegroundColor Gray
}

Write-Host ""

# ============================================================================
# Step 6: Show Quick Summary
# ============================================================================

Write-Host "?? Step 6: Quick Summary" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

$finalCpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$os2 = Get-CimInstance Win32_OperatingSystem
$finalFreeMemoryGB = [math]::Round($os2.FreePhysicalMemory / 1MB, 2)
$finalUsedMemoryGB = [math]::Round($totalMemoryGB - $finalFreeMemoryGB, 2)
$memoryDelta = $finalUsedMemoryGB - $usedMemoryGB

Write-Host "  ?? Resource Changes:" -ForegroundColor White
Write-Host "     • CPU: $initialCpu% ? $finalCpu%" -ForegroundColor Gray
Write-Host "     • Memory: $usedMemoryGB GB ? $finalUsedMemoryGB GB ($(if($memoryDelta -gt 0){'+' + [math]::Round($memoryDelta, 2)}else{[math]::Round($memoryDelta, 2)}) GB)" -ForegroundColor Gray
Write-Host ""

if ($reportCreated) {
    Write-Host "  ?? Full report:" -ForegroundColor Yellow
    Write-Host "     $($latestReport.FullName)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""

# ============================================================================
# Summary
# ============================================================================

Write-Host "??????????????????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?                            ? Run Summary                                  ?" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

Write-Host "What happened:" -ForegroundColor White
Write-Host "  ? Server started and running" -ForegroundColor Green
Write-Host "  ? Load test ran with $MaxParallel parallel conversions" -ForegroundColor Green
Write-Host "  ? Tested $fileCount files ($totalSizeMB MB)" -ForegroundColor Green
if ($reportCreated) {
    Write-Host "  ? Detailed report generated" -ForegroundColor Green
}
Write-Host ""

Write-Host "Open windows:" -ForegroundColor White
Write-Host "  ?? Server window - Keep running (don't close!)" -ForegroundColor Green
Write-Host "  ?? Test window - You can review the results" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor White
Write-Host "  ?? View detailed analysis:" -ForegroundColor Yellow
Write-Host "     .\analyze-results.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ?? Run another test with different parallelism:" -ForegroundColor Yellow
Write-Host "     .\AUTO-RUN-EVERYTHING.ps1 -MaxParallel 20" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ?? Test multiple configurations:" -ForegroundColor Yellow
Write-Host "     .\test-multiple-configs.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "????????????????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "? All done! Check the test window for results." -ForegroundColor Green
Write-Host ""
Write-Host "This window can be closed or left open - the test is running independently" -ForegroundColor Gray
Write-Host ""
