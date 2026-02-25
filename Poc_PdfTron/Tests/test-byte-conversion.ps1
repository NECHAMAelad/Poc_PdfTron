# ========================================
# Test Script for Byte Array to PDF Conversion
# ========================================

$ErrorActionPreference = "Stop"

# Configuration
$baseUrl = "http://localhost:5000"
$testFilesDir = "C:\Temp\Input"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Byte Array to PDF Conversion Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# Test 1: Convert DOCX from Byte Array
# ========================================
Write-Host "[Test 1] Converting DOCX file from byte array..." -ForegroundColor Yellow

$docxFile = Join-Path $testFilesDir "sample.docx"

if (Test-Path $docxFile) {
    try {
        # Read file into byte array
        Write-Host "Reading file: $docxFile" -ForegroundColor Gray
        $fileBytes = [System.IO.File]::ReadAllBytes($docxFile)
        $fileSizeMB = [math]::Round($fileBytes.Length / 1MB, 2)
        Write-Host "File size: $fileSizeMB MB ($($fileBytes.Length) bytes)" -ForegroundColor Gray
        
        # Convert to Base64 for JSON transmission
        $base64String = [Convert]::ToBase64String($fileBytes)
        
        # Prepare request
        $body = @{
            FileBytes = $fileBytes
            OriginalFileName = "sample.docx"
            OutputFileName = "test_from_bytes_docx"
        } | ConvertTo-Json
        
        Write-Host "Sending conversion request..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri "$baseUrl/api/pdfconversion/convert-from-bytes" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 60
        
        if ($response.success) {
            Write-Host "? DOCX conversion successful!" -ForegroundColor Green
            Write-Host "  Output: $($response.outputFileName)" -ForegroundColor Green
            Write-Host "  PDF Size: $([math]::Round($response.pdfSizeBytes / 1KB, 2)) KB" -ForegroundColor Green
            Write-Host "  Detected Type: $($response.detectedFileType)" -ForegroundColor Green
            Write-Host "  Duration: $($response.conversionDuration)" -ForegroundColor Green
            
            # Optionally save the PDF bytes
            if ($response.pdfBytes) {
                $outputPath = "C:\Temp\Output\test_from_bytes_docx_result.pdf"
                $pdfBytesArray = [Convert]::FromBase64String($response.pdfBytes)
                [System.IO.File]::WriteAllBytes($outputPath, $pdfBytesArray)
                Write-Host "  Saved to: $outputPath" -ForegroundColor Green
            }
        } else {
            Write-Host "? DOCX conversion failed: $($response.errorMessage)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "? Error in Test 1: $_" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "? Test file not found: $docxFile" -ForegroundColor Red
}

Write-Host ""

# ========================================
# Test 2: Convert Image from Byte Array
# ========================================
Write-Host "[Test 2] Converting image file from byte array..." -ForegroundColor Yellow

$imageFile = Join-Path $testFilesDir "sample.jpg"

if (Test-Path $imageFile) {
    try {
        # Read file into byte array
        Write-Host "Reading file: $imageFile" -ForegroundColor Gray
        $fileBytes = [System.IO.File]::ReadAllBytes($imageFile)
        $fileSizeMB = [math]::Round($fileBytes.Length / 1MB, 2)
        Write-Host "File size: $fileSizeMB MB ($($fileBytes.Length) bytes)" -ForegroundColor Gray
        
        # Prepare request (without OriginalFileName to test auto-detection)
        $body = @{
            FileBytes = $fileBytes
            OutputFileName = "test_from_bytes_image"
        } | ConvertTo-Json
        
        Write-Host "Sending conversion request (auto-detect mode)..." -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri "$baseUrl/api/pdfconversion/convert-from-bytes" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 60
        
        if ($response.success) {
            Write-Host "? Image conversion successful!" -ForegroundColor Green
            Write-Host "  Output: $($response.outputFileName)" -ForegroundColor Green
            Write-Host "  PDF Size: $([math]::Round($response.pdfSizeBytes / 1KB, 2)) KB" -ForegroundColor Green
            Write-Host "  Auto-Detected Type: $($response.detectedFileType)" -ForegroundColor Green
            Write-Host "  Duration: $($response.conversionDuration)" -ForegroundColor Green
        } else {
            Write-Host "? Image conversion failed: $($response.errorMessage)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "? Error in Test 2: $_" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "? Test file not found: $imageFile (skipping)" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# Test 3: Convert and Download (Direct File Return)
# ========================================
Write-Host "[Test 3] Converting Excel file and downloading PDF directly..." -ForegroundColor Yellow

$excelFile = Join-Path $testFilesDir "sample.xlsx"

if (Test-Path $excelFile) {
    try {
        # Read file into byte array
        Write-Host "Reading file: $excelFile" -ForegroundColor Gray
        $fileBytes = [System.IO.File]::ReadAllBytes($excelFile)
        
        # Prepare request
        $body = @{
            FileBytes = $fileBytes
            OriginalFileName = "sample.xlsx"
            OutputFileName = "test_from_bytes_excel"
        } | ConvertTo-Json
        
        Write-Host "Sending conversion-and-download request..." -ForegroundColor Gray
        $outputPath = "C:\Temp\Output\test_from_bytes_excel_direct.pdf"
        
        Invoke-RestMethod -Uri "$baseUrl/api/pdfconversion/convert-from-bytes-and-download" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body `
            -OutFile $outputPath `
            -TimeoutSec 60
        
        if (Test-Path $outputPath) {
            $pdfSize = (Get-Item $outputPath).Length
            Write-Host "? Excel conversion and download successful!" -ForegroundColor Green
            Write-Host "  Saved to: $outputPath" -ForegroundColor Green
            Write-Host "  PDF Size: $([math]::Round($pdfSize / 1KB, 2)) KB" -ForegroundColor Green
        } else {
            Write-Host "? PDF file was not created" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "? Error in Test 3: $_" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
} else {
    Write-Host "? Test file not found: $excelFile (skipping)" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# Test 4: File Size Limit Test (Negative Test)
# ========================================
Write-Host "[Test 4] Testing file size limit (should fail for >50MB)..." -ForegroundColor Yellow

try {
    # Create a large byte array (60MB)
    Write-Host "Creating 60MB test byte array..." -ForegroundColor Gray
    $largeBytes = New-Object byte[] (60 * 1024 * 1024)
    
    # Prepare request
    $body = @{
        FileBytes = $largeBytes
        OriginalFileName = "large_file.txt"
    } | ConvertTo-Json
    
    Write-Host "Sending conversion request..." -ForegroundColor Gray
    $response = Invoke-RestMethod -Uri "$baseUrl/api/pdfconversion/convert-from-bytes" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body `
        -TimeoutSec 60
    
    if ($response.success) {
        Write-Host "? Test failed - should have rejected large file" -ForegroundColor Red
    } else {
        Write-Host "? File size limit working correctly!" -ForegroundColor Green
        Write-Host "  Error message: $($response.errorMessage)" -ForegroundColor Green
    }
}
catch {
    # Expected to fail with 400 Bad Request
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "? File size limit working correctly (400 Bad Request)" -ForegroundColor Green
    } else {
        Write-Host "? Unexpected error: $_" -ForegroundColor Red
    }
}

Write-Host ""

# ========================================
# Test 5: Unsupported File Type Test
# ========================================
Write-Host "[Test 5] Testing unsupported file type detection..." -ForegroundColor Yellow

try {
    # Create a fake executable file header
    Write-Host "Creating fake .exe file bytes..." -ForegroundColor Gray
    $exeBytes = [byte[]](0x4D, 0x5A) + (New-Object byte[] 1000)  # MZ header
    
    # Prepare request
    $body = @{
        FileBytes = $exeBytes
        OriginalFileName = "test.exe"
    } | ConvertTo-Json
    
    Write-Host "Sending conversion request..." -ForegroundColor Gray
    $response = Invoke-RestMethod -Uri "$baseUrl/api/pdfconversion/convert-from-bytes" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body `
        -TimeoutSec 60
    
    if ($response.success) {
        Write-Host "? Test failed - should have rejected .exe file" -ForegroundColor Red
    } else {
        Write-Host "? File type validation working correctly!" -ForegroundColor Green
        Write-Host "  Error message: $($response.errorMessage)" -ForegroundColor Green
    }
}
catch {
    # Expected to fail with 400 Bad Request
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "? File type validation working correctly (400 Bad Request)" -ForegroundColor Green
    } else {
        Write-Host "? Unexpected error: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  All Tests Completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
