# ========================================
# HTML to PDF Conversion Test
# ????? ???? HTML ?-PDF
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  HTML to PDF Conversion Test" -ForegroundColor Cyan
Write-Host "  ????? ???? HTML ?-PDF" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$baseUrl = "http://localhost:5063"
$projectPath = Join-Path $PSScriptRoot ".."
$testHtmlFile = Join-Path $PSScriptRoot "test-complex-hebrew.html"
$outputDir = "C:\Temp\Output"

# ========================================
# ????? 1: ??? ???? ?-HTML ?????
# ========================================
Write-Host "[????? 1] ???? ?? ???? ?-HTML ????..." -ForegroundColor Yellow

if (-not (Test-Path $testHtmlFile)) {
    Write-Host "? ???? HTML ?? ????: $testHtmlFile" -ForegroundColor Red
    Write-Host "??? ??? ?????? test-complex-hebrew.html ???? ??????? Tests" -ForegroundColor Yellow
    exit 1
}

Write-Host "? ???? HTML ????: $(Split-Path $testHtmlFile -Leaf)" -ForegroundColor Green
$htmlSize = (Get-Item $testHtmlFile).Length
Write-Host "  ????: $([math]::Round($htmlSize / 1KB, 2)) KB" -ForegroundColor Gray
Write-Host ""

# ========================================
# ????? 2: ??? ???? ?????
# ========================================
Write-Host "[????? 2] ???? ?? ???? ????..." -ForegroundColor Yellow

try {
    $health = Invoke-WebRequest -Uri "$baseUrl/health" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "? ???? ???? ??????: $baseUrl" -ForegroundColor Green
}
catch {
    Write-Host "? ???? ?? ????!" -ForegroundColor Red
    Write-Host "??? ???? ?? ???? ???????: dotnet run --project `"$projectPath`"" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# ========================================
# ????? 3: ??? ??????? C:\Temp\Input ??????
# ========================================
Write-Host "[????? 3] ????/???? ?????? Input..." -ForegroundColor Yellow

$inputDir = "C:\Temp\Input"
if (-not (Test-Path $inputDir)) {
    New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
    Write-Host "? ????? ??????: $inputDir" -ForegroundColor Green
}
else {
    Write-Host "? ?????? ?????: $inputDir" -ForegroundColor Green
}

# ???? ?? ???? ?-HTML ??????? Input
$inputHtmlPath = Join-Path $inputDir "test-complex-hebrew.html"
Copy-Item -Path $testHtmlFile -Destination $inputHtmlPath -Force
Write-Host "? ????? ????? ?: $inputHtmlPath" -ForegroundColor Green
Write-Host ""

# ========================================
# ????? 4: ????? ?????? ????? ?? API
# ========================================
Write-Host "[????? 4] ???? ?????? ???? HTML ?? ?-API..." -ForegroundColor Yellow

try {
    $encodedPath = [System.Uri]::EscapeDataString($inputHtmlPath)
    $validation = Invoke-RestMethod -Uri "$baseUrl/api/pdfconversion/validate?filePath=$encodedPath" -Method Get
    Write-Host "? ???? HTML ???? ????? ?????" -ForegroundColor Green
}
catch {
    Write-Host "? ????? ?????? ?????!" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  ?????: $($errorDetails.detail)" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""

# ========================================
# ????? 5: ???? HTML ?-PDF
# ========================================
Write-Host "[????? 5] ???? ???? HTML ?-PDF..." -ForegroundColor Yellow
Write-Host ""

$conversionRequest = @{
    sourceFilePath = $inputHtmlPath
    outputFileName = "test_html_output_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
} | ConvertTo-Json

try {
    $startTime = Get-Date
    
    Write-Host "  ???? ???? ?-API..." -ForegroundColor Gray
    $result = Invoke-RestMethod `
        -Uri "$baseUrl/api/pdfconversion/convert" `
        -Method Post `
        -Body $conversionRequest `
        -ContentType "application/json" `
        -TimeoutSec 60
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host ""
    Write-Host "? ????? ??????!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Gray
    Write-Host "?? ???? ???    : " -NoNewline -ForegroundColor White
    Write-Host $result.outputFilePath -ForegroundColor Cyan
    Write-Host "?? ?? ????     : " -NoNewline -ForegroundColor White
    Write-Host $result.outputFileName -ForegroundColor Cyan
    Write-Host "?? ???? ????   : " -NoNewline -ForegroundColor White
    Write-Host "$([math]::Round($result.outputFileSizeBytes / 1KB, 2)) KB" -ForegroundColor Yellow
    Write-Host "??  ??? ????   : " -NoNewline -ForegroundColor White
    Write-Host $result.conversionDuration -ForegroundColor Magenta
    Write-Host "? ??? ????    : " -NoNewline -ForegroundColor White
    Write-Host "$([math]::Round($duration, 2)) ?????" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Gray
    
    # ????? ?? ????? ???? ?????
    if (Test-Path $result.outputFilePath) {
        Write-Host ""
        Write-Host "? ???? PDF ???? ?????" -ForegroundColor Green
        
        # ???? ??? ?????
        Write-Host ""
        $open = Read-Host "??? ????? ?? ???? ?-PDF? (Y/N)"
        if ($open -eq "Y" -or $open -eq "y") {
            Start-Process $result.outputFilePath
            Write-Host "? ???? PDF ????" -ForegroundColor Green
        }
    }
    else {
        Write-Host ""
        Write-Host "? ?????: ???? PDF ?? ???? ?????!" -ForegroundColor Yellow
        Write-Host "  ????? ????: $($result.outputFilePath)" -ForegroundColor Yellow
    }
    
}
catch {
    Write-Host ""
    Write-Host "? ????? ?????!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Gray
    
    if ($_.ErrorDetails.Message) {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "?? ????? ????? : " -NoNewline -ForegroundColor White
        Write-Host $errorDetails.title -ForegroundColor Red
        Write-Host "?? ???? ????? : " -NoNewline -ForegroundColor White
        Write-Host $errorDetails.detail -ForegroundColor Red
        
        if ($errorDetails.developerMessage) {
            Write-Host ""
            Write-Host "?? ???? ?????:" -ForegroundColor Yellow
            Write-Host $errorDetails.developerMessage -ForegroundColor Gray
        }
    }
    else {
        Write-Host "?????: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host "========================================" -ForegroundColor Gray
    exit 1
}

# ========================================
# ????? 6: ???? ?? Byte Array
# ========================================
Write-Host ""
Write-Host "[????? 6] ???? ???? ?? Byte Array..." -ForegroundColor Yellow
Write-Host ""

try {
    # ??? ?? ???? ?-HTML
    $htmlBytes = [System.IO.File]::ReadAllBytes($testHtmlFile)
    $base64Html = [Convert]::ToBase64String($htmlBytes)
    
    Write-Host "  ???? byte array: $($htmlBytes.Length) bytes" -ForegroundColor Gray
    Write-Host "  ???? ?-API..." -ForegroundColor Gray
    
    $byteRequest = @{
        FileBytes = $base64Html
        OriginalFileName = "test-complex-hebrew.html"
        OutputFileName = "test_html_bytes_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    } | ConvertTo-Json -Depth 10
    
    $byteResult = Invoke-RestMethod `
        -Uri "$baseUrl/api/pdfconversion/convert-from-bytes" `
        -Method Post `
        -ContentType "application/json" `
        -Body $byteRequest `
        -TimeoutSec 60
    
    if ($byteResult.success) {
        Write-Host ""
        Write-Host "? ???? Byte Array ??????!" -ForegroundColor Green
        Write-Host "  ??? ???? ????: $($byteResult.detectedFileType)" -ForegroundColor Cyan
        Write-Host "  ???? PDF: $([math]::Round($byteResult.pdfSizeBytes / 1KB, 2)) KB" -ForegroundColor Yellow
        Write-Host "  ??? ????: $($byteResult.conversionDuration)" -ForegroundColor Magenta
        
        # ????? ?????
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $bytePdfPath = Join-Path $outputDir "test_html_bytes_$(Get-Date -Format 'yyyyMMdd_HHmmss').pdf"
        $pdfBytes = [Convert]::FromBase64String($byteResult.pdfBytes)
        [System.IO.File]::WriteAllBytes($bytePdfPath, $pdfBytes)
        
        Write-Host "  ???? ?: $bytePdfPath" -ForegroundColor Green
        
        Write-Host ""
        $openByte = Read-Host "??? ????? ?? ???? ?-PDF? (Y/N)"
        if ($openByte -eq "Y" -or $openByte -eq "y") {
            Start-Process $bytePdfPath
            Write-Host "? ???? PDF ????" -ForegroundColor Green
        }
    }
    else {
        Write-Host "? ???? Byte Array ?????: $($byteResult.errorMessage)" -ForegroundColor Red
    }
}
catch {
    Write-Host "? ????? ????? Byte Array: $($_.Exception.Message)" -ForegroundColor Red
}

# ========================================
# ?????
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ?????? ??????!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? ?????? ???: $outputDir" -ForegroundColor White
Write-Host "?? ???? PDF ??????:" -ForegroundColor White

$pdfFiles = Get-ChildItem $outputDir -Filter "*.pdf" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 5

if ($pdfFiles) {
    foreach ($pdf in $pdfFiles) {
        $fileSize = [math]::Round($pdf.Length / 1KB, 2)
        $modTime = $pdf.LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")
        Write-Host "  ? $($pdf.Name) ($fileSize KB) - $modTime" -ForegroundColor Cyan
    }
}
else {
    Write-Host "  ??? ???? PDF ???????" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "?? ??? ?? ????? ?????: $baseUrl/pdf-viewer.html" -ForegroundColor Cyan
Write-Host "?? ????? API: $baseUrl/swagger" -ForegroundColor Cyan
Write-Host ""
