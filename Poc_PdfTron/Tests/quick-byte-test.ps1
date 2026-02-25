# ========================================
# Quick Byte Array Conversion Test
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Quick Byte Array Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$possiblePorts = @(5063)
$baseUrl = $null
$projectPath = Join-Path $PSScriptRoot ".."

# ========================================
# Check if server is running, start if needed
# ========================================
Write-Host "[Setup] Checking if server is running..." -ForegroundColor Yellow

$serverRunning = $false
$serverProcess = $null

# Try to find running server on common ports
foreach ($port in $possiblePorts) {
    try {
        $testUrl = "http://localhost:$port/health"
        Write-Host "  Checking port $port..." -ForegroundColor Gray
        $response = Invoke-WebRequest -Uri $testUrl -TimeoutSec 2 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $serverRunning = $true
            $baseUrl = "http://localhost:$port"
            Write-Host "✓ Server found running on port $port" -ForegroundColor Green
            break
        }
    }
    catch {
        Write-Host "  Port $port - not responding" -ForegroundColor DarkGray
    }
}

if (-not $serverRunning) {
    Write-Host "⚠ Server is not running" -ForegroundColor Yellow
}

if (-not $serverRunning) {
    Write-Host "Starting server..." -ForegroundColor Cyan
    Write-Host "  Project path: $projectPath" -ForegroundColor Gray
    
    # Start the server in background
    $serverProcess = Start-Process -FilePath "dotnet" `
        -ArgumentList "run --project `"$projectPath`" --urls `"http://localhost:5063`"" `
        -WorkingDirectory $projectPath `
        -PassThru `
        -WindowStyle Normal
    
    Write-Host "  Process ID: $($serverProcess.Id)" -ForegroundColor Gray
    Write-Host "  Waiting for server to start on port 5063..." -ForegroundColor Gray
    
    # Wait for server to be ready (max 60 seconds)
    $maxWaitSeconds = 60
    $waited = 0
    $serverReady = $false
    
    while ($waited -lt $maxWaitSeconds) {
        Start-Sleep -Seconds 2
        $waited += 2
        
        try {
            $testUrl = "http://localhost:5063/health"
            $response = Invoke-WebRequest -Uri $testUrl -TimeoutSec 2 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $serverReady = $true
                $baseUrl = "http://localhost:5063"
                break
            }
        }
        catch {
            Write-Host "." -NoNewline -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    
    if ($serverReady) {
        Write-Host "✓ Server started successfully on port 5063!" -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host "✗ Server failed to start within $maxWaitSeconds seconds" -ForegroundColor Red
        Write-Host "Please check the server logs or start manually:" -ForegroundColor Yellow
        Write-Host "  cd $projectPath" -ForegroundColor Gray
        Write-Host "  dotnet run" -ForegroundColor Gray
        if ($serverProcess -and -not $serverProcess.HasExited) {
            Stop-Process -Id $serverProcess.Id -Force
        }
        exit 1
    }
}
else {
    Write-Host ""
}

if (-not $baseUrl) {
    Write-Host "✗ Error: Could not determine server URL" -ForegroundColor Red
    exit 1
}

Write-Host "Using API URL: $baseUrl" -ForegroundColor Cyan
Write-Host ""

# ========================================
# Option 1: Create a simple text file as byte array
# ========================================
Write-Host "[Option 1] Creating simple text file from byte array..." -ForegroundColor Yellow
Write-Host ""

# Create text content
$textContent = @"
שלום!
זהו קובץ טקסט פשוט שנוצר מ-byte array.

This is a simple text file created from a byte array.
We will convert it to PDF using the new byte array conversion feature.

תאריך: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
"@

# IMPORTANT: Use UTF-8 encoding with BOM for Hebrew support
$textBytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)

Write-Host "Created text byte array:" -ForegroundColor Gray
Write-Host "  Size: $($textBytes.Length) bytes" -ForegroundColor Gray
Write-Host "  First 10 bytes: $($textBytes[0..9] -join ', ')" -ForegroundColor Gray
Write-Host ""

# Convert to Base64 for JSON transmission
$base64Content = [Convert]::ToBase64String($textBytes)

# Prepare request - using Base64 encoded bytes
$body = @{
    FileBytes = $base64Content
    OriginalFileName = "test_from_bytes.txt"
    OutputFileName = "converted_from_bytes"
} | ConvertTo-Json -Depth 10

Write-Host "Sending to API..." -ForegroundColor Gray

try {
    $response = Invoke-RestMethod `
        -Uri "$baseUrl/api/pdfconversion/convert-from-bytes" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body `
        -TimeoutSec 30
    
    if ($response.success) {
        Write-Host "✓ Conversion successful!" -ForegroundColor Green
        Write-Host "  Detected type: $($response.detectedFileType)" -ForegroundColor Green
        Write-Host "  PDF size: $([math]::Round($response.pdfSizeBytes / 1KB, 2)) KB" -ForegroundColor Green
        Write-Host "  Duration: $($response.conversionDuration)" -ForegroundColor Green
        
        # Save PDF
        $outputDir = "C:\Temp\Output"
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $outputPath = Join-Path $outputDir "test_from_bytes.pdf"
        $pdfBytes = [Convert]::FromBase64String($response.pdfBytes)
        [System.IO.File]::WriteAllBytes($outputPath, $pdfBytes)
        
        Write-Host "  Saved to: $outputPath" -ForegroundColor Green
        Write-Host ""
        
        # Open the PDF
        Write-Host "Opening PDF..." -ForegroundColor Cyan
        Start-Process $outputPath
    }
    else {
        Write-Host "✗ Conversion failed: $($response.errorMessage)" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""

# ========================================
# Option 2: Read an existing file if available
# ========================================
Write-Host "[Option 2] Testing with existing file (if available)..." -ForegroundColor Yellow
Write-Host ""

$testFilesDir = "C:\Temp\Input"
$testFiles = @("sample.docx", "test.docx", "document.docx", "sample.txt", "test.txt")

$foundFile = $null
foreach ($fileName in $testFiles) {
    $filePath = Join-Path $testFilesDir $fileName
    if (Test-Path $filePath) {
        $foundFile = $filePath
        break
    }
}

if ($foundFile) {
Write-Host "Found test file: $foundFile" -ForegroundColor Gray
    
# Read file into byte array
$fileBytes = [System.IO.File]::ReadAllBytes($foundFile)
$fileSizeMB = [math]::Round($fileBytes.Length / 1MB, 2)
    
Write-Host "File details:" -ForegroundColor Gray
Write-Host "  Size: $fileSizeMB MB ($($fileBytes.Length) bytes)" -ForegroundColor Gray
Write-Host "  First 10 bytes: $($fileBytes[0..9] -join ', ')" -ForegroundColor Gray
Write-Host ""
    
# Convert to Base64
$base64Content = [Convert]::ToBase64String($fileBytes)
    
# Prepare request
$body = @{
    FileBytes = $base64Content
    OriginalFileName = (Split-Path $foundFile -Leaf)
    OutputFileName = "test_existing_file"
} | ConvertTo-Json -Depth 10
    
Write-Host "Sending to API..." -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod `
            -Uri "$baseUrl/api/pdfconversion/convert-from-bytes" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 60
        
        if ($response.success) {
            Write-Host "✓ Conversion successful!" -ForegroundColor Green
            Write-Host "  Detected type: $($response.detectedFileType)" -ForegroundColor Green
            Write-Host "  PDF size: $([math]::Round($response.pdfSizeBytes / 1KB, 2)) KB" -ForegroundColor Green
            Write-Host "  Duration: $($response.conversionDuration)" -ForegroundColor Green
            
            # Save PDF
            $outputPath = "C:\Temp\Output\test_existing_file.pdf"
            $pdfBytes = [Convert]::FromBase64String($response.pdfBytes)
            [System.IO.File]::WriteAllBytes($outputPath, $pdfBytes)
            
            Write-Host "  Saved to: $outputPath" -ForegroundColor Green
            Write-Host ""
            
            # Open the PDF
            Write-Host "Opening PDF..." -ForegroundColor Cyan
            Start-Process $outputPath
        }
        else {
            Write-Host "✗ Conversion failed: $($response.errorMessage)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Error: $_" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
else {
    Write-Host "⚠ No test files found in $testFilesDir" -ForegroundColor Yellow
    Write-Host "  Looking for: $($testFiles -join ', ')" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# Option 3: Test with direct download endpoint
# ========================================
Write-Host "[Option 3] Testing direct download endpoint..." -ForegroundColor Yellow
Write-Host ""

# Create another text file
$textContent2 = @"
בדיקת הורדה ישירה

זהו מסמך נוסף שנוצר מ-byte array.
הפעם נשתמש ב-endpoint שמחזיר את ה-PDF ישירות.

Direct Download Test

This document is created from a byte array.
This time we use the endpoint that returns the PDF directly.

Created: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
"@

# IMPORTANT: Use UTF-8 encoding for Hebrew support
$textBytes2 = [System.Text.Encoding]::UTF8.GetBytes($textContent2)

Write-Host "Created text byte array:" -ForegroundColor Gray
Write-Host "  Size: $($textBytes2.Length) bytes" -ForegroundColor Gray
Write-Host ""

# Convert to Base64
$base64Content2 = [Convert]::ToBase64String($textBytes2)

# Prepare request
$body = @{
    FileBytes = $base64Content2
    OriginalFileName = "direct_download.txt"
    OutputFileName = "direct_download_test"
} | ConvertTo-Json -Depth 10

Write-Host "Sending to download endpoint..." -ForegroundColor Gray

try {
    $outputPath = "C:\Temp\Output\direct_download_test.pdf"
    
    Invoke-RestMethod `
        -Uri "$baseUrl/api/pdfconversion/convert-from-bytes-and-download" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body `
        -OutFile $outputPath `
        -TimeoutSec 30
    
    if (Test-Path $outputPath) {
        $pdfSize = (Get-Item $outputPath).Length
        Write-Host "✓ Direct download successful!" -ForegroundColor Green
        Write-Host "  Saved to: $outputPath" -ForegroundColor Green
        Write-Host "  PDF size: $([math]::Round($pdfSize / 1KB, 2)) KB" -ForegroundColor Green
        Write-Host ""
        
        # Open the PDF
        Write-Host "Opening PDF..." -ForegroundColor Cyan
        Start-Process $outputPath
    }
}
catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check the output folder: C:\Temp\Output\" -ForegroundColor Cyan
Write-Host ""

# ========================================
# Cleanup - Stop server if we started it
# ========================================
if ($serverProcess -and -not $serverProcess.HasExited) {
    Write-Host "[Cleanup] Stopping the server..." -ForegroundColor Yellow
    
    try {
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Server stopped" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠ Could not stop server (Process ID: $($serverProcess.Id))" -ForegroundColor Yellow
        Write-Host "You may need to stop it manually" -ForegroundColor Yellow
    }
    
    Write-Host ""
}
else {
    Write-Host "Note: Server was already running before the test, keeping it running." -ForegroundColor Gray
    Write-Host ""
}
