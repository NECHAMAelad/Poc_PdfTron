# Test script for PDF Merge functionality
# Test script for merging files to PDF

param(
    [string]$BaseUrl = "http://localhost:5063",
    [string]$InputFolder = "C:\Temp\Input",
    [string]$OutputFolder = "C:\Temp\Output"
)

$ErrorActionPreference = "Stop"

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "   PDF Merge API - Test Script" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# Check if service is running
Write-Host "Checking if service is running..." -ForegroundColor Yellow
try {
    $settingsResponse = Invoke-RestMethod -Uri "$BaseUrl/api/pdfconversion/settings" -Method Get
    if ($settingsResponse.pdfTronInitialized) {
        Write-Host "✓ Service is running and PDFTron is initialized" -ForegroundColor Green
    } else {
        Write-Host "✗ Service is running but PDFTron is not initialized" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Service is not running or not accessible" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# List available files in Input folder
Write-Host "Files in Input folder:" -ForegroundColor Yellow
if (Test-Path $InputFolder) {
    $files = Get-ChildItem -Path $InputFolder -File | Select-Object -ExpandProperty Name
    if ($files.Count -eq 0) {
        Write-Host "  (No files found)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please add some test files to: $InputFolder" -ForegroundColor Yellow
        exit 1
    }
    $files | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
} else {
    Write-Host "  Input folder does not exist: $InputFolder" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Ask user to select files
Write-Host "Enter file names to merge (comma-separated):" -ForegroundColor Yellow
Write-Host "Example: file1.docx,file2.txt,file3.png" -ForegroundColor Gray
$fileList = Read-Host "Files"

if ([string]::IsNullOrWhiteSpace($fileList)) {
    Write-Host "No files specified. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Ask for output file name
Write-Host "Enter output file name (optional, press Enter for default):" -ForegroundColor Yellow
$outputFileName = Read-Host "Output name"

Write-Host ""

# Test 1: Merge with info response
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Test 1: Merge Files (returns info)" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

$mergeRequest = @{
    sourceFiles = $fileList
}

if (-not [string]::IsNullOrWhiteSpace($outputFileName)) {
    $mergeRequest.outputFileName = $outputFileName
}

$requestJson = $mergeRequest | ConvertTo-Json

Write-Host "Request:" -ForegroundColor Yellow
Write-Host $requestJson -ForegroundColor Gray
Write-Host ""

try {
    Write-Host "Sending merge request..." -ForegroundColor Yellow
    
    $result = Invoke-RestMethod -Uri "$BaseUrl/api/pdfconversion/merge" `
        -Method Post `
        -Body $requestJson `
        -ContentType "application/json"
    
    Write-Host ""
    Write-Host "✓ Merge completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Results:" -ForegroundColor Cyan
    Write-Host "  Success: $($result.success)" -ForegroundColor White
    Write-Host "  Output File: $($result.outputFileName)" -ForegroundColor White
    Write-Host "  Output Path: $($result.outputFilePath)" -ForegroundColor White
    Write-Host "  Files Processed: $($result.filesProcessed) of $($result.totalFiles)" -ForegroundColor White
    Write-Host "  Duration: $($result.duration)" -ForegroundColor White
    
    if ($result.successfulFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Successful Files:" -ForegroundColor Green
        $result.successfulFiles | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }
    }
    
    if ($result.failedFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed Files:" -ForegroundColor Red
        $result.failedFiles | ForEach-Object { 
            Write-Host "  ✗ $($_.fileName)" -ForegroundColor Red
            Write-Host "    Error: $($_.errorMessage)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    # Ask if user wants to open the file
    $openFile = Read-Host "Open the merged PDF file? (Y/N)"
    if ($openFile -eq 'Y' -or $openFile -eq 'y') {
        if (Test-Path $result.outputFilePath) {
            Start-Process $result.outputFilePath
        } else {
            Write-Host "File not found at: $($result.outputFilePath)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host ""
    Write-Host "✗ Merge failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.ErrorDetails.Message) {
        Write-Host ""
        Write-Host "Details:" -ForegroundColor Yellow
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  $($errorDetails.detail)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host ""

# Test 2: Merge and Download
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Test 2: Merge and Download (returns PDF directly)" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

$downloadTest = Read-Host "Test download endpoint? (Y/N)"

if ($downloadTest -eq 'Y' -or $downloadTest -eq 'y') {
    Write-Host ""
    
    $downloadPath = Join-Path $env:TEMP "merged_download_$(Get-Date -Format 'yyyyMMdd_HHmmss').pdf"
    
    Write-Host "Sending merge-and-download request..." -ForegroundColor Yellow
    Write-Host "Download path: $downloadPath" -ForegroundColor Gray
    
    try {
        Invoke-RestMethod -Uri "$BaseUrl/api/pdfconversion/merge-and-download" `
            -Method Post `
            -Body $requestJson `
            -ContentType "application/json" `
            -OutFile $downloadPath
        
        Write-Host ""
        Write-Host "✓ PDF downloaded successfully!" -ForegroundColor Green
        Write-Host "  Location: $downloadPath" -ForegroundColor White
        
        $fileInfo = Get-Item $downloadPath
        Write-Host "  Size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor White
        
        Write-Host ""
        $openDownload = Read-Host "Open the downloaded PDF? (Y/N)"
        if ($openDownload -eq 'Y' -or $openDownload -eq 'y') {
            Start-Process $downloadPath
        }
        
    } catch {
        Write-Host ""
        Write-Host "✗ Download failed!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.ErrorDetails.Message) {
            Write-Host ""
            Write-Host "Details:" -ForegroundColor Yellow
            $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "  $($errorDetails.detail)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Tests completed!" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
