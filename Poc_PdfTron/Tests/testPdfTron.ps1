# ============================================================================
# testPdfTron.ps1 - Complete PDF Conversion Test
# ============================================================================
# This script does EVERYTHING automatically:
#   1. Starts the API server
#   2. Waits for it to be ready
#   3. Converts your file to PDF
#   4. Opens the converted PDF
#   5. Cleans up when done
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$FileName,
    
    [string]$InputDirectory = "C:\Temp\Input",
    [string]$OutputDirectory = "C:\Temp\Output"
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-SuccessMessage {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-InfoMessage {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor White
}

function Write-WarningMessage {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ============================================================================
# Banner
# ============================================================================

Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   PDF Conversion - Complete Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Step 1: Validate Input File
# ============================================================================

Write-Step "Step 1: Validating Input File"

$inputFilePath = Join-Path $InputDirectory $FileName

if (-not (Test-Path $inputFilePath)) {
    Write-ErrorMessage "File not found: $inputFilePath"
    Write-Host ""
    Write-WarningMessage "Available files in ${InputDirectory}"
    if (Test-Path $InputDirectory) {
        Get-ChildItem $InputDirectory | ForEach-Object {
            Write-Host "   - $($_.Name)" -ForegroundColor Gray
        }
    } else {
        Write-WarningMessage "Input directory does not exist!"
    }
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}

$fileInfo = Get-Item $inputFilePath
$fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

Write-SuccessMessage "File found!"
Write-InfoMessage "   File: $FileName"
Write-InfoMessage "   Path: $inputFilePath"
Write-InfoMessage "   Size: $fileSizeMB MB"
Write-InfoMessage "   Extension: $($fileInfo.Extension)"

# ============================================================================
# Step 2: Ensure Output Directory Exists
# ============================================================================

Write-Step "Step 2: Preparing Output Directory"

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-SuccessMessage "Created output directory: $OutputDirectory"
} else {
    Write-SuccessMessage "Output directory exists: $OutputDirectory"
}

# ============================================================================
# Step 3: Start API Server
# ============================================================================

Write-Step "Step 3: Starting API Server"

# Get project root directory
$projectRoot = Split-Path -Parent $PSScriptRoot

Write-InfoMessage "Project directory: $projectRoot"
Write-InfoMessage "Starting server..."

# Start server in background
$serverProcess = Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$projectRoot'; `$host.ui.RawUI.WindowTitle = 'PDF API Server'; Write-Host 'Starting PDF Conversion API...' -ForegroundColor Green; dotnet run"
) -PassThru -WindowStyle Normal

Write-SuccessMessage "Server process started (PID: $($serverProcess.Id))"
Write-InfoMessage "Waiting for server to be ready..."

# Wait for server to start
$apiUrl = "http://localhost:5063"
$maxRetries = 30
$retryCount = 0
$serverReady = $false

Start-Sleep -Seconds 5

while (-not $serverReady -and $retryCount -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri "$apiUrl/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $serverReady = $true
        }
    }
    catch {
        $retryCount++
        Write-Host "   Waiting... ($retryCount/$maxRetries)" -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if (-not $serverReady) {
    Write-ErrorMessage "Server did not start in time!"
    Write-WarningMessage "Cleaning up..."
    Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}

Write-SuccessMessage "Server is ready!"
Write-InfoMessage "   URL: $apiUrl"
Write-InfoMessage "   Swagger: $apiUrl/swagger"

# ============================================================================
# Step 4: Convert File to PDF
# ============================================================================

Write-Step "Step 4: Converting File to PDF"

$outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($FileName) + ".pdf"
$outputFilePath = Join-Path $OutputDirectory $outputFileName

Write-InfoMessage "Converting: $FileName -> $outputFileName"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    # Prepare the request
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileBin = [System.IO.File]::ReadAllBytes($inputFilePath)
    
    # Build multipart form data
    $LF = "`r`n"
    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"",
        "Content-Type: application/octet-stream$LF",
        [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBin),
        "--$boundary--$LF"
    ) -join $LF

    # Make the request - USE Invoke-WebRequest for binary response
    $response = Invoke-WebRequest `
        -Uri "$apiUrl/api/pdfconversion/upload-and-convert" `
        -Method POST `
        -ContentType "multipart/form-data; boundary=$boundary" `
        -Body $bodyLines `
        -TimeoutSec 120 `
        -UseBasicParsing
    
    $stopwatch.Stop()
    
    # Save PDF - Get bytes from Content property
    [System.IO.File]::WriteAllBytes($outputFilePath, $response.Content)
    
    $outputFileInfo = Get-Item $outputFilePath
    $outputSizeMB = [math]::Round($outputFileInfo.Length / 1MB, 2)
    
    Write-SuccessMessage "Conversion successful!"
    Write-InfoMessage "   Duration: $($stopwatch.Elapsed.TotalSeconds.ToString('0.00')) seconds"
    Write-InfoMessage "   Output: $outputFilePath"
    Write-InfoMessage "   PDF Size: $outputSizeMB MB"
}
catch {
    $stopwatch.Stop()
    Write-ErrorMessage "Conversion failed!"
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host ""
            Write-Host "Server Response:" -ForegroundColor Yellow
            Write-Host $responseBody -ForegroundColor Gray
        }
        catch {
            Write-Host "Could not read error response" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-WarningMessage "Cleaning up..."
    Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}

# ============================================================================
# Step 5: Open the PDF
# ============================================================================

Write-Step "Step 5: Opening Converted PDF"

if (Test-Path $outputFilePath) {
    Write-InfoMessage "Opening PDF in default viewer..."
    Start-Process $outputFilePath
    Write-SuccessMessage "PDF opened!"
} else {
    Write-ErrorMessage "Output PDF not found: $outputFilePath"
}

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "           SUCCESS!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Conversion Summary:" -ForegroundColor Cyan
Write-Host "   Input File:  $FileName ($fileSizeMB MB)" -ForegroundColor White
Write-Host "   Output File: $outputFileName ($outputSizeMB MB)" -ForegroundColor White
Write-Host "   Duration:    $($stopwatch.Elapsed.TotalSeconds.ToString('0.00')) seconds" -ForegroundColor White
Write-Host "   Location:    $outputFilePath" -ForegroundColor White
Write-Host ""
Write-Host "API Server:" -ForegroundColor Cyan
Write-Host "   Status:  Running (PID: $($serverProcess.Id))" -ForegroundColor White
Write-Host "   URL:     $apiUrl" -ForegroundColor White
Write-Host "   Swagger: $apiUrl/swagger" -ForegroundColor White
Write-Host ""

# ============================================================================
# Cleanup Options
# ============================================================================

Write-Host "========================================" -ForegroundColor Gray
Write-Host ""
Write-Host "What would you like to do?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Keep server running (convert more files)" -ForegroundColor White
Write-Host "  2. Stop server and exit" -ForegroundColor White
Write-Host "  3. Open output folder" -ForegroundColor White
Write-Host "  4. Open Swagger UI" -ForegroundColor White
Write-Host ""
Write-Host -NoNewline "Choose option (1-4) or press Enter to stop: " -ForegroundColor Yellow
$choice = Read-Host

switch ($choice) {
    "1" {
        Write-Host ""
        Write-SuccessMessage "Server is still running!"
        Write-InfoMessage "Server URL: $apiUrl"
        Write-InfoMessage "Swagger UI: $apiUrl/swagger"
        Write-InfoMessage "To convert another file, run:"
        Write-Host "   .\testPdfTron.ps1 -FileName 'yourfile.docx'" -ForegroundColor Cyan
        Write-Host ""
        Write-WarningMessage "Remember to stop the server manually when done!"
        Write-Host "   Use: Stop-Process -Id $($serverProcess.Id)" -ForegroundColor Gray
        Write-Host ""
    }
    "3" {
        Write-Host ""
        Write-InfoMessage "Opening output folder..."
        Start-Process explorer.exe -ArgumentList $OutputDirectory
        Start-Sleep -Seconds 2
        Write-Host ""
        Write-SuccessMessage "Server stopped."
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }
    "4" {
        Write-Host ""
        Write-InfoMessage "Opening Swagger UI..."
        Start-Process "$apiUrl/swagger"
        Start-Sleep -Seconds 3
        Write-Host ""
        Write-WarningMessage "Keeping server running for Swagger..."
        Write-InfoMessage "Press any key when ready to stop..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Write-Host ""
        Write-SuccessMessage "Server stopped."
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }
    default {
        Write-Host ""
        Write-InfoMessage "Stopping server..."
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
        Write-SuccessMessage "Server stopped."
        Write-Host ""
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Thank you for using testPdfTron!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
