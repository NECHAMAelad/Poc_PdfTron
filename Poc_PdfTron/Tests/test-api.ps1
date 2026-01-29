# ========================================
# PDF Conversion API - Complete Test Script
# ========================================

$ErrorActionPreference = "Continue"
$baseUrl = "http://localhost:5063"  # Using HTTP to avoid certificate issues

# Load required assemblies
Add-Type -AssemblyName System.Web

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PDF Conversion API - Test Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ========================================
# Step 1: Health Checks
# ========================================
Write-Host "Step 1: Running Health Checks..." -ForegroundColor Yellow

try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "? Health Check: " -NoNewline -ForegroundColor Green
    Write-Host "OK - $($health.message)" -ForegroundColor White
} catch {
    Write-Host "? Health Check Failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nMake sure the API is running with: dotnet run" -ForegroundColor Yellow
    exit 1
}

try {
    $pdfnetc = Invoke-RestMethod -Uri "$baseUrl/health/pdfnetc" -Method Get
    Write-Host "? PDFNetC Check: " -NoNewline -ForegroundColor Green
    Write-Host "OK - $($pdfnetc.message)" -ForegroundColor White
} catch {
    Write-Host "? PDFNetC Check Failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPDFNetC.dll might be missing or inaccessible" -ForegroundColor Yellow
}

try {
    $settings = Invoke-RestMethod -Uri "$baseUrl/api/pdfconversion/settings" -Method Get
    Write-Host "? Settings Check: " -NoNewline -ForegroundColor Green
    Write-Host "OK - PDFTron Initialized: $($settings.pdfTronInitialized)" -ForegroundColor White
} catch {
    Write-Host "? Settings Check Failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

# ========================================
# Step 2: Ensure Directories Exist
# ========================================
Write-Host "`nStep 2: Checking Directories..." -ForegroundColor Yellow

$inputDir = "C:\Temp\Input"
$outputDir = "C:\Temp\Output"

if (-not (Test-Path $inputDir)) {
    New-Item -Path $inputDir -ItemType Directory -Force | Out-Null
    Write-Host "? Created Input directory: $inputDir" -ForegroundColor Green
} else {
    Write-Host "? Input directory exists: $inputDir" -ForegroundColor Green
}

if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Host "? Created Output directory: $outputDir" -ForegroundColor Green
} else {
    Write-Host "? Output directory exists: $outputDir" -ForegroundColor Green
}

# ========================================
# Step 3: Check for Test Files
# ========================================
Write-Host "`nStep 3: Checking for Test Files..." -ForegroundColor Yellow

$testFiles = Get-ChildItem $inputDir -Filter "*.doc*" -ErrorAction SilentlyContinue

if ($testFiles.Count -eq 0) {
    Write-Host "? No test files found in Input directory" -ForegroundColor Yellow
    Write-Host "  Please add a .docx or .docm file to: $inputDir" -ForegroundColor Yellow
    Write-Host "`nCreating a simple test file..." -ForegroundColor Cyan
    
    try {
        # Try to create a test file using Word COM
        $word = New-Object -ComObject Word.Application -ErrorAction Stop
        $word.Visible = $false
        
        $doc = $word.Documents.Add()
        $doc.Content.Text = @"
PDF Conversion Test Document
============================

Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

This is a test document for PDF conversion.

Features to test:
? Text conversion
? Formatting preservation
? File size handling

Test completed successfully!
"@
        
        $testFile = Join-Path $inputDir "test_$(Get-Date -Format 'yyyyMMdd_HHmmss').docx"
        $doc.SaveAs([ref]$testFile, [ref]16) # 16 = wdFormatXMLDocument (DOCX)
        $doc.Close()
        $word.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
        
        Write-Host "? Created test file: $testFile" -ForegroundColor Green
        $testFiles = Get-ChildItem $inputDir -Filter "*.doc*"
        
    } catch {
        Write-Host "? Could not create test file automatically" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPlease manually create a Word document in: $inputDir" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "? Found $($testFiles.Count) test file(s):" -ForegroundColor Green
    foreach ($file in $testFiles) {
        Write-Host "  - $($file.Name) ($([math]::Round($file.Length / 1KB, 2)) KB)" -ForegroundColor White
    }
}

# ========================================
# Step 4: Test File Validation
# ========================================
Write-Host "`nStep 4: Testing File Validation..." -ForegroundColor Yellow

$testFile = $testFiles[0].FullName
Write-Host "Using file: $($testFiles[0].Name)" -ForegroundColor Cyan

try {
    $encodedPath = [System.Uri]::EscapeDataString($testFile)
    $validation = Invoke-RestMethod -Uri "$baseUrl/api/pdfconversion/validate?filePath=$encodedPath" -Method Get
    Write-Host "? File Validation: " -NoNewline -ForegroundColor Green
    Write-Host "PASSED - $($validation.message)" -ForegroundColor White
} catch {
    Write-Host "? File Validation Failed!" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  Error: $($errorDetails.detail)" -ForegroundColor Red
    } else {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}

# ========================================
# Step 5: Test PDF Conversion
# ========================================
Write-Host "`nStep 5: Testing PDF Conversion..." -ForegroundColor Yellow
Write-Host "Converting: $($testFiles[0].Name)" -ForegroundColor Cyan

$conversionRequest = @{
    sourceFilePath = $testFile
    outputFileName = "test_output_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
} | ConvertTo-Json

try {
    $startTime = Get-Date
    
    $result = Invoke-RestMethod `
        -Uri "$baseUrl/api/pdfconversion/convert" `
        -Method Post `
        -Body $conversionRequest `
        -ContentType "application/json"
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host "`n? CONVERSION SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Gray
    Write-Host "Output File    : " -NoNewline -ForegroundColor White
    Write-Host $result.outputFilePath -ForegroundColor Cyan
    Write-Host "File Name      : " -NoNewline -ForegroundColor White
    Write-Host $result.outputFileName -ForegroundColor Cyan
    Write-Host "File Size      : " -NoNewline -ForegroundColor White
    Write-Host "$([math]::Round($result.outputFileSizeBytes / 1KB, 2)) KB" -ForegroundColor Yellow
    Write-Host "Duration       : " -NoNewline -ForegroundColor White
    Write-Host $result.conversionDuration -ForegroundColor Magenta
    Write-Host "Total Time     : " -NoNewline -ForegroundColor White
    Write-Host "$([math]::Round($duration, 2)) seconds" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Gray
    
    # Check if output file exists
    if (Test-Path $result.outputFilePath) {
        Write-Host "`n? Output PDF file verified on disk" -ForegroundColor Green
        
        $openFile = Read-Host "`nOpen the PDF file? (Y/N)"
        if ($openFile -eq "Y" -or $openFile -eq "y") {
            Start-Process $result.outputFilePath
        }
    } else {
        Write-Host "`n? Warning: Output file not found on disk!" -ForegroundColor Yellow
        Write-Host "  Expected location: $($result.outputFilePath)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "`n? CONVERSION FAILED!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Gray
    
    if ($_.ErrorDetails.Message) {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "Error Title    : " -NoNewline -ForegroundColor White
        Write-Host $errorDetails.title -ForegroundColor Red
        Write-Host "Error Detail   : " -NoNewline -ForegroundColor White
        Write-Host $errorDetails.detail -ForegroundColor Red
        
        if ($errorDetails.developerMessage) {
            Write-Host "`nDeveloper Info:" -ForegroundColor Yellow
            Write-Host $errorDetails.developerMessage -ForegroundColor Gray
        }
    } else {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host "========================================" -ForegroundColor Gray
}

# ========================================
# Step 6: Summary
# ========================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Suite Completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nOutput Directory: $outputDir" -ForegroundColor White
Write-Host "View all converted files:" -ForegroundColor White

$outputFiles = Get-ChildItem $outputDir -Filter "*.pdf" -ErrorAction SilentlyContinue
if ($outputFiles.Count -gt 0) {
    foreach ($file in $outputFiles) {
        Write-Host "  - $($file.Name) ($([math]::Round($file.Length / 1KB, 2)) KB) - Modified: $($file.LastWriteTime)" -ForegroundColor Cyan
    }
} else {
    Write-Host "  No PDF files found in output directory" -ForegroundColor Yellow
}

Write-Host "`nAPI Endpoints:" -ForegroundColor White
Write-Host "  - Swagger UI: $baseUrl" -ForegroundColor Cyan
Write-Host "  - Health: $baseUrl/health" -ForegroundColor Cyan
Write-Host "  - Convert: $baseUrl/api/pdfconversion/convert" -ForegroundColor Cyan
Write-Host "`n" -ForegroundColor White
