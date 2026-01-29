# ============================================================================
# ?? Automatic Analysis of Load Test Results + Recommendations
# ============================================================================

param(
    [string]$ReportPath = ""
)

$ErrorActionPreference = "SilentlyContinue"

Clear-Host

Write-Host ""
Write-Host "??????????????????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?              ?? Load Test Results - Automatic Analysis                     ?" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Find latest report if not specified
if ([string]::IsNullOrEmpty($ReportPath)) {
    $reports = Get-ChildItem -Path "." -Filter "LOAD_TEST_REPORT_*.md" | Sort-Object LastWriteTime -Descending
    if ($reports.Count -eq 0) {
        Write-Host "? No reports found" -ForegroundColor Red
        Write-Host "   Run test first: .\AUTO-RUN-EVERYTHING.ps1" -ForegroundColor Yellow
        exit 1
    }
    $ReportPath = $reports[0].FullName
}

if (-not (Test-Path $ReportPath)) {
    Write-Host "? Report not found: $ReportPath" -ForegroundColor Red
    exit 1
}

Write-Host "?? Analyzing report: $(Split-Path $ReportPath -Leaf)" -ForegroundColor White
Write-Host ""

# Read report
$content = Get-Content $ReportPath -Raw

# ============================================================================
# Extract Data from Report
# ============================================================================

Write-Host "?? Step 1: Extracting Data" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

# Extract basic numbers
$totalFiles = 0
$successCount = 0
$failureCount = 0
$totalDuration = 0.0
$conversionRate = 0.0

if ($content -match 'Total files.*\|\s*(\d+)') { $totalFiles = [int]$matches[1] }
if ($content -match 'Successes.*\|\s*?\s*(\d+)') { $successCount = [int]$matches[1] }
if ($content -match 'Failures.*\|\s*?\s*(\d+)') { $failureCount = [int]$matches[1] }
if ($content -match 'Total duration.*\|\s*([\d.]+)') { $totalDuration = [double]$matches[1] }
if ($content -match 'Conversion rate.*\|\s*([\d.]+)') { $conversionRate = [double]$matches[1] }

# Extract CPU data
$cpuStart = 0
$cpuEnd = 0
$cpuAvg = 0
$cpuMax = 0
$cpuDelta = 0

if ($content -match 'Start.*CPU.*\|\s*([\d.]+)%') { $cpuStart = [double]$matches[1] }
if ($content -match 'End.*CPU.*\|\s*([\d.]+)%') { $cpuEnd = [double]$matches[1] }
if ($content -match 'Average.*CPU.*\|\s*([\d.]+)%') { $cpuAvg = [double]$matches[1] }
if ($content -match 'Peak.*CPU.*\|\s*([\d.]+)%') { $cpuMax = [double]$matches[1] }
if ($content -match 'Change.*CPU.*\|\s*([+-]?[\d.]+)%') { $cpuDelta = [double]$matches[1] }

# Extract memory data
$memStart = 0.0
$memEnd = 0.0
$memAvg = 0.0
$memMax = 0.0
$memDelta = 0.0

if ($content -match 'Start.*Memory.*\|\s*([\d.]+)\s*GB') { $memStart = [double]$matches[1] }
if ($content -match 'End.*Memory.*\|\s*([\d.]+)\s*GB') { $memEnd = [double]$matches[1] }
if ($content -match 'Average.*Memory.*\|\s*([\d.]+)\s*GB') { $memAvg = [double]$matches[1] }
if ($content -match 'Peak.*Memory.*\|\s*([\d.]+)\s*GB') { $memMax = [double]$matches[1] }
if ($content -match 'Change.*Memory.*\|\s*([+-]?[\d.]+)\s*GB') { $memDelta = [double]$matches[1] }

# Display data
Write-Host "  ?? Performance Data:" -ForegroundColor White
Write-Host "     • Files: $totalFiles | Success: $successCount | Failures: $failureCount" -ForegroundColor Gray
Write-Host "     • Time: $totalDuration sec | Rate: $conversionRate files/sec" -ForegroundColor Gray
Write-Host ""
Write-Host "  ?? Resources:" -ForegroundColor White
Write-Host "     • CPU: $cpuStart% ? $cpuEnd% (avg: $cpuAvg%, peak: $cpuMax%)" -ForegroundColor Gray
Write-Host "     • Memory: $memStart GB ? $memEnd GB (avg: $memAvg GB, peak: $memMax GB)" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# Analysis and Scoring
# ============================================================================

Write-Host "?? Step 2: Analysis and Scoring" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

$scores = @{
    Success = 0
    CPU = 0
    Memory = 0
    Speed = 0
}

# Success score
$successRate = if ($totalFiles -gt 0) { ($successCount / $totalFiles) * 100 } else { 0 }
$scores.Success = [math]::Min(100, $successRate)

if ($successRate -ge 98) {
    Write-Host "  ? Success Rate: $([math]::Round($successRate, 1))% - Excellent!" -ForegroundColor Green
    $successGrade = "A+"
} elseif ($successRate -ge 90) {
    Write-Host "  ? Success Rate: $([math]::Round($successRate, 1))% - Very Good" -ForegroundColor Green
    $successGrade = "A"
} elseif ($successRate -ge 75) {
    Write-Host "  ??  Success Rate: $([math]::Round($successRate, 1))% - Moderate" -ForegroundColor Yellow
    $successGrade = "B"
} else {
    Write-Host "  ? Success Rate: $([math]::Round($successRate, 1))% - Low" -ForegroundColor Red
    $successGrade = "C"
}

# CPU score
if ($cpuAvg -le 50) {
    Write-Host "  ? CPU: $cpuAvg% average - Excellent! Room to increase parallelism" -ForegroundColor Green
    $scores.CPU = 100
    $cpuGrade = "A+"
} elseif ($cpuAvg -le 70) {
    Write-Host "  ? CPU: $cpuAvg% average - Good, well balanced" -ForegroundColor Green
    $scores.CPU = 85
    $cpuGrade = "A"
} elseif ($cpuAvg -le 85) {
    Write-Host "  ??  CPU: $cpuAvg% average - Slightly high" -ForegroundColor Yellow
    $scores.CPU = 70
    $cpuGrade = "B"
} else {
    Write-Host "  ? CPU: $cpuAvg% average - Too high! Reduce parallelism" -ForegroundColor Red
    $scores.CPU = 50
    $cpuGrade = "C"
}

# Memory score
if ($memDelta -le 1.0) {
    Write-Host "  ? Memory: +$memDelta GB - Excellent! Efficient usage" -ForegroundColor Green
    $scores.Memory = 100
    $memGrade = "A+"
} elseif ($memDelta -le 2.0) {
    Write-Host "  ? Memory: +$memDelta GB - Good, acceptable" -ForegroundColor Green
    $scores.Memory = 85
    $memGrade = "A"
} elseif ($memDelta -le 4.0) {
    Write-Host "  ??  Memory: +$memDelta GB - Slightly high" -ForegroundColor Yellow
    $scores.Memory = 70
    $memGrade = "B"
} else {
    Write-Host "  ? Memory: +$memDelta GB - Too high! Possible memory leak" -ForegroundColor Red
    $scores.Memory = 50
    $memGrade = "C"
}

# Speed score
$avgTimePerFile = if ($totalFiles -gt 0) { $totalDuration / $totalFiles } else { 0 }
if ($avgTimePerFile -le 2.0) {
    Write-Host "  ? Speed: $([math]::Round($avgTimePerFile, 2))s per file - Fast!" -ForegroundColor Green
    $scores.Speed = 100
    $speedGrade = "A+"
} elseif ($avgTimePerFile -le 5.0) {
    Write-Host "  ? Speed: $([math]::Round($avgTimePerFile, 2))s per file - Good" -ForegroundColor Green
    $scores.Speed = 85
    $speedGrade = "A"
} elseif ($avgTimePerFile -le 10.0) {
    Write-Host "  ??  Speed: $([math]::Round($avgTimePerFile, 2))s per file - Moderate" -ForegroundColor Yellow
    $scores.Speed = 70
    $speedGrade = "B"
} else {
    Write-Host "  ? Speed: $([math]::Round($avgTimePerFile, 2))s per file - Slow" -ForegroundColor Red
    $scores.Speed = 50
    $speedGrade = "C"
}

$totalScore = ($scores.Success + $scores.CPU + $scores.Memory + $scores.Speed) / 4

Write-Host ""
Write-Host "  ?? Overall Score: $([math]::Round($totalScore, 0))/100" -ForegroundColor White
Write-Host ""

# ============================================================================
# Automatic Recommendations
# ============================================================================

Write-Host "?? Step 3: Recommendations" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

$recommendations = @()

# Recommendations based on parallelism
if ($content -match 'Concurrent conversions.*:\s*(\d+)') {
    $currentParallel = [int]$matches[1]
    
    if ($cpuAvg -lt 50 -and $memDelta -lt 1.5) {
        $suggestedParallel = [math]::Min($currentParallel * 2, 30)
        $recommendations += @{
            Priority = "HIGH"
            Type = "Parallelism"
            Message = "CPU and RAM are low - can increase parallelism"
            Action = ".\AUTO-RUN-EVERYTHING.ps1 -MaxParallel $suggestedParallel"
            Reason = "Low resource utilization ($cpuAvg% CPU, +$memDelta GB RAM)"
        }
    }
    elseif ($cpuAvg -gt 85 -or $memDelta -gt 3.0) {
        $suggestedParallel = [math]::Max([math]::Floor($currentParallel * 0.6), 3)
        $recommendations += @{
            Priority = "HIGH"
            Type = "Parallelism"
            Message = "Resources exhausted - reduce parallelism"
            Action = ".\AUTO-RUN-EVERYTHING.ps1 -MaxParallel $suggestedParallel"
            Reason = "High load ($cpuAvg% CPU or +$memDelta GB RAM)"
        }
    }
    elseif ($cpuAvg -ge 60 -and $cpuAvg -le 75) {
        $recommendations += @{
            Priority = "LOW"
            Type = "Parallelism"
            Message = "Optimal parallelism - good resource utilization"
            Action = "Continue with MaxParallel $currentParallel"
            Reason = "Good balance between load and performance"
        }
    }
}

# Recommendations based on failures
if ($failureCount -gt 0) {
    $failureRate = ($failureCount / $totalFiles) * 100
    
    if ($failureRate -gt 20) {
        $recommendations += @{
            Priority = "CRITICAL"
            Type = "Failures"
            Message = "High failure rate ($([math]::Round($failureRate, 1))%)"
            Action = "Check logs and reduce load"
            Reason = "$failureCount out of $totalFiles files failed"
        }
    }
    elseif ($failureRate -gt 5) {
        $recommendations += @{
            Priority = "MEDIUM"
            Type = "Failures"
            Message = "Some failures ($([math]::Round($failureRate, 1))%)"
            Action = "Check problematic files"
            Reason = "Some files were not converted successfully"
        }
    }
}

# Recommendations based on speed
if ($avgTimePerFile -gt 10) {
    $recommendations += @{
        Priority = "MEDIUM"
        Type = "Performance"
        Message = "Slow conversions ($([math]::Round($avgTimePerFile, 2))s per file)"
        Action = "Check large/complex files, consider hardware upgrade"
        Reason = "High average conversion time"
        }
}

# Recommendations based on memory
if ($memDelta -gt 4) {
    $recommendations += @{
        Priority = "HIGH"
        Type = "Memory"
        Message = "High memory consumption (+$memDelta GB)"
        Action = "Reduce parallelism or check for memory leaks"
        Reason = "Significant memory increase"
    }
}

# Display recommendations
if ($recommendations.Count -eq 0) {
    Write-Host "  ? No recommendations - everything looks great!" -ForegroundColor Green
}
else {
    $priorityOrder = @{
        "CRITICAL" = 1
        "HIGH" = 2
        "MEDIUM" = 3
        "LOW" = 4
    }
    
    $sortedRecommendations = $recommendations | Sort-Object { $priorityOrder[$_.Priority] }
    
    $counter = 1
    foreach ($rec in $sortedRecommendations) {
        $color = switch ($rec.Priority) {
            "CRITICAL" { "Red" }
            "HIGH" { "Yellow" }
            "MEDIUM" { "Cyan" }
            "LOW" { "Green" }
        }
        
        $icon = switch ($rec.Priority) {
            "CRITICAL" { "??" }
            "HIGH" { "?? " }
            "MEDIUM" { "??" }
            "LOW" { "?" }
        }
        
        Write-Host "  $icon Recommendation $counter [$($rec.Priority)]:" -ForegroundColor $color
        Write-Host "     ?? $($rec.Message)" -ForegroundColor White
        Write-Host "     ?? Action: $($rec.Action)" -ForegroundColor Gray
        Write-Host "     ??  Reason: $($rec.Reason)" -ForegroundColor DarkGray
        Write-Host ""
        
        $counter++
    }
}

# ============================================================================
# Report Card Summary
# ============================================================================

Write-Host "?? Step 4: Report Card" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  ????????????????????????????????????????????????" -ForegroundColor Gray
Write-Host "  ? Criterion              ? Score    ? Grade    ?" -ForegroundColor Gray
Write-Host "  ????????????????????????????????????????????????" -ForegroundColor Gray
Write-Host "  ? Success Rate           ? $([math]::Round($scores.Success).ToString().PadLeft(3))%     ? $($successGrade.PadRight(8)) ?" -ForegroundColor $(if($successGrade -match "A"){"Green"}elseif($successGrade -eq "B"){"Yellow"}else{"Red"})
Write-Host "  ? CPU Usage              ? $([math]::Round($scores.CPU).ToString().PadLeft(3))%     ? $($cpuGrade.PadRight(8)) ?" -ForegroundColor $(if($cpuGrade -match "A"){"Green"}elseif($cpuGrade -eq "B"){"Yellow"}else{"Red"})
Write-Host "  ? Memory Management      ? $([math]::Round($scores.Memory).ToString().PadLeft(3))%     ? $($memGrade.PadRight(8)) ?" -ForegroundColor $(if($memGrade -match "A"){"Green"}elseif($memGrade -eq "B"){"Yellow"}else{"Red"})
Write-Host "  ? Conversion Speed       ? $([math]::Round($scores.Speed).ToString().PadLeft(3))%     ? $($speedGrade.PadRight(8)) ?" -ForegroundColor $(if($speedGrade -match "A"){"Green"}elseif($speedGrade -eq "B"){"Yellow"}else{"Red"})
Write-Host "  ????????????????????????????????????????????????" -ForegroundColor Gray
Write-Host "  ? Overall Score          ? $([math]::Round($totalScore).ToString().PadLeft(3))%     ? $(if($totalScore -ge 90){"A+"}elseif($totalScore -ge 80){"A"}elseif($totalScore -ge 70){"B"}else{"C"}).PadRight(8) ?" -ForegroundColor $(if($totalScore -ge 80){"Green"}elseif($totalScore -ge 70){"Yellow"}else{"Red"})
Write-Host "  ????????????????????????????????????????????????" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# Next Steps
# ============================================================================

Write-Host "?? What's Next?" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

$topRecommendation = $sortedRecommendations | Select-Object -First 1

if ($topRecommendation) {
    Write-Host "  ?? Top Recommended Action:" -ForegroundColor White
    Write-Host "     $($topRecommendation.Action)" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "  ?? Additional Actions:" -ForegroundColor White
Write-Host "     • View full report: .\show-load-test-results.ps1" -ForegroundColor Gray
Write-Host "     • Run another test: .\AUTO-RUN-EVERYTHING.ps1" -ForegroundColor Gray
Write-Host "     • Test multiple configs: .\test-multiple-configs.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "????????????????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

if ($totalScore -ge 80) {
    Write-Host "?? System performing excellently! Keep it up!" -ForegroundColor Green
}
elseif ($totalScore -ge 70) {
    Write-Host "?? Good performance, minor improvements possible" -ForegroundColor Yellow
}
else {
    Write-Host "??  Improvements needed - follow recommendations above" -ForegroundColor Red
}

Write-Host ""
