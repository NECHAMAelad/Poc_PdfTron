# Quick Merge Test - Automatic Server Start + Merge Test
# Complete automated script - starts server and tests file merging

<#
.SYNOPSIS
    Automated script for starting server and testing file merge to PDF

.DESCRIPTION
    This script:
    1. Checks if server is running, starts it automatically if not
    2. Allows you to select files to merge
    3. Performs the merge
    4. Opens the result

.PARAMETER Files
    Comma-separated list of files to merge
    Example: "file1.docx,file2.xlsx,file3.jpg"

.PARAMETER OutputName
    Output file name (optional)

.PARAMETER AutoOpen
    Automatically open merged file (default: true)

.EXAMPLE
    .\quick-merge-test.ps1
    # Interactive mode - script will ask what to merge

.EXAMPLE
    .\quick-merge-test.ps1 -Files "doc1.docx,image.jpg,report.xlsx"
    # Merge specified files

.EXAMPLE
    .\quick-merge-test.ps1 -Files "file1.docx,file2.pdf" -OutputName "merged_report"
    # Merge with custom output name
#>

param(
    [string]$Files = "",
    [string]$OutputName = "",
    [bool]$AutoOpen = $true,
    [string]$BaseUrl = "http://localhost:5063",
    [string]$InputFolder = "C:\Temp\Input",
    [string]$OutputFolder = "C:\Temp\Output"
)

$ErrorActionPreference = "Continue"

# ==========================================
# FUNCTIONS
# ==========================================

function Show-Banner {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         PDF Merge - Quick Test & Server Launcher         ║" -ForegroundColor Cyan
    Write-Host "║              Quick Test & File Merge to PDF              ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-ServerRunning {
    param([string]$Url)
    
    try {
        $response = Invoke-WebRequest -Uri "$Url/api/pdfconversion/settings" -Method Get -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Start-PdfServer {
    param([string]$Url)
    
    Write-Host "🚀 Starting server..." -ForegroundColor Yellow
    Write-Host ""
    
    # Find project directory
    $scriptDir = Split-Path -Parent $PSCommandPath
    $projectDir = Split-Path -Parent $scriptDir
    $csprojPath = Join-Path $projectDir "Poc_PdfTron.csproj"
    
    if (-not (Test-Path $csprojPath)) {
        Write-Host "❌ Project file not found: $csprojPath" -ForegroundColor Red
        return $null
    }
    
    Write-Host "📁 Project location: $projectDir" -ForegroundColor Gray
    
    # Start server in new window
    $serverProcess = Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "cd '$projectDir'; Write-Host '🚀 Starting PDF server...' -ForegroundColor Cyan; dotnet run"
    ) -PassThru -WindowStyle Normal
    
    Write-Host "⏳ Waiting for server to start..." -ForegroundColor Yellow
    
    # Wait for server to start (max 30 seconds)
    $maxWait = 30
    $waited = 0
    $serverStarted = $false
    
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 1
        $waited++
        
        if (Test-ServerRunning -Url $Url) {
            $serverStarted = $true
            break
        }
        
        # Show progress
        if ($waited % 5 -eq 0) {
            Write-Host "  Waiting... ($waited/$maxWait seconds)" -ForegroundColor Gray
        }
    }
    
    if ($serverStarted) {
        Write-Host ""
        Write-Host "✅ Server started successfully!" -ForegroundColor Green
        Write-Host "🌐 URL: $Url" -ForegroundColor Green
        Write-Host ""
        return $serverProcess
    } else {
        Write-Host ""
        Write-Host "❌ Server did not start after $maxWait seconds" -ForegroundColor Red
        Write-Host "   Check the opened window for errors" -ForegroundColor Yellow
        return $null
    }
}

function Get-AvailableFiles {
    param([string]$FolderPath)
    
    if (-not (Test-Path $FolderPath)) {
        Write-Host "⚠️  Input folder does not exist: $FolderPath" -ForegroundColor Yellow
        Write-Host "   Creating folder..." -ForegroundColor Gray
        New-Item -ItemType Directory -Path $FolderPath -Force | Out-Null
        return @()
    }
    
    $files = Get-ChildItem -Path $FolderPath -File | Select-Object -ExpandProperty Name
    return $files
}

function Show-FileList {
    param([array]$Files)
    
    Write-Host "📂 Available files in input folder:" -ForegroundColor Cyan
    Write-Host "   Location: $InputFolder" -ForegroundColor Gray
    Write-Host ""
    
    if ($Files.Count -eq 0) {
        Write-Host "   ⚠️  No files found!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   💡 Add files to the folder:" -ForegroundColor Yellow
        Write-Host "      $InputFolder" -ForegroundColor White
        Write-Host ""
        Write-Host "   Supported file types:" -ForegroundColor Gray
        Write-Host "      • Word: .docx, .doc" -ForegroundColor Gray
        Write-Host "      • Excel: .xlsx, .xls" -ForegroundColor Gray
        Write-Host "      • PowerPoint: .pptx, .ppt" -ForegroundColor Gray
        Write-Host "      • Images: .jpg, .png, .gif, .bmp" -ForegroundColor Gray
        Write-Host "      • Text: .txt, .rtf" -ForegroundColor Gray
        Write-Host "      • PDF: .pdf" -ForegroundColor Gray
        Write-Host ""
        return $false
    }
    
    for ($i = 0; $i -lt $Files.Count; $i++) {
        Write-Host "   $($i + 1). $($Files[$i])" -ForegroundColor White
    }
    
    Write-Host ""
    return $true
}

function Get-UserFileSelection {
    param([array]$AvailableFiles)
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "📝 Enter file names to merge (comma-separated):" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Examples:" -ForegroundColor Gray
    Write-Host "   • file1.docx,file2.xlsx,file3.jpg" -ForegroundColor White
    Write-Host "   • document.docx,image.png" -ForegroundColor White
    Write-Host ""
    Write-Host "   Or enter numbers: 1,2,3" -ForegroundColor Gray
    Write-Host ""
    
    $input = Read-Host "➤ Files"
    
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $null
    }
    
    # Check if input is numbers
    if ($input -match '^\d+([,\s]+\d+)*$') {
        # User entered numbers - convert to file names
        $numbers = $input -split '[,\s]+' | Where-Object { $_ -match '\d+' } | ForEach-Object { [int]$_ }
        $selectedFiles = @()
        
        foreach ($num in $numbers) {
            if ($num -gt 0 -and $num -le $AvailableFiles.Count) {
                $selectedFiles += $AvailableFiles[$num - 1]
            } else {
                Write-Host "   ⚠️  Invalid number: $num" -ForegroundColor Yellow
            }
        }
        
        if ($selectedFiles.Count -eq 0) {
            return $null
        }
        
        return ($selectedFiles -join ',')
    }
    
    # User entered file names directly
    return $input
}

function Invoke-MergeRequest {
    param(
        [string]$Url,
        [string]$FileList,
        [string]$OutputFileName
    )
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "🔄 Merging files..." -ForegroundColor Cyan
    Write-Host ""
    
    $mergeRequest = @{
        sourceFiles = $FileList
    }
    
    if (-not [string]::IsNullOrWhiteSpace($OutputFileName)) {
        $mergeRequest.outputFileName = $OutputFileName
    }
    
    $requestJson = $mergeRequest | ConvertTo-Json
    
    Write-Host "📤 Sending request:" -ForegroundColor Gray
    Write-Host $requestJson -ForegroundColor DarkGray
    Write-Host ""
    
    try {
        $result = Invoke-RestMethod -Uri "$Url/api/pdfconversion/merge" `
            -Method Post `
            -Body $requestJson `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        Write-Host "✅ Merge completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Results:" -ForegroundColor Cyan
        Write-Host "   • Output file: $($result.outputFileName)" -ForegroundColor White
        Write-Host "   • Location: $($result.outputFilePath)" -ForegroundColor Gray
        Write-Host "   • Files processed: $($result.filesProcessed)/$($result.totalFiles)" -ForegroundColor White
        Write-Host "   • Duration: $($result.duration)" -ForegroundColor Gray
        Write-Host ""
        
        if ($result.successfulFiles.Count -gt 0) {
            Write-Host "✅ Successfully merged files:" -ForegroundColor Green
            $result.successfulFiles | ForEach-Object { 
                Write-Host "   ✓ $_" -ForegroundColor Green 
            }
            Write-Host ""
        }
        
        if ($result.failedFiles.Count -gt 0) {
            Write-Host "❌ Failed files:" -ForegroundColor Red
            $result.failedFiles | ForEach-Object { 
                Write-Host "   ✗ $($_.fileName)" -ForegroundColor Red
                Write-Host "     Error: $($_.errorMessage)" -ForegroundColor Yellow
            }
            Write-Host ""
        }
        
        return $result
        
    } catch {
        Write-Host "❌ Merge failed!" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.ErrorDetails.Message) {
            try {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "   Details: $($errorDetails.detail)" -ForegroundColor Yellow
            } catch {
                Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
            }
        }
        Write-Host ""
        return $null
    }
}

# ==========================================
# MAIN SCRIPT
# ==========================================

Show-Banner

# Step 1: Check/Start Server
Write-Host "🔍 Checking if server is running..." -ForegroundColor Cyan

$serverProcess = $null
$serverWasStarted = $false

if (Test-ServerRunning -Url $BaseUrl) {
    Write-Host "✅ Server is already running!" -ForegroundColor Green
    Write-Host "🌐 URL: $BaseUrl" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "⚠️  Server is not running" -ForegroundColor Yellow
    Write-Host ""
    
    $serverProcess = Start-PdfServer -Url $BaseUrl
    
    if ($null -eq $serverProcess) {
        Write-Host ""
        Write-Host "❌ Could not start server" -ForegroundColor Red
        Write-Host "   Start server manually: dotnet run" -ForegroundColor Yellow
        exit 1
    }
    
    $serverWasStarted = $true
}

# Step 2: Get available files
$availableFiles = Get-AvailableFiles -FolderPath $InputFolder

if (-not (Show-FileList -Files $availableFiles)) {
    Write-Host "Press Enter to exit..." -ForegroundColor Gray
    Read-Host
    
    if ($serverWasStarted -and $null -ne $serverProcess) {
        Write-Host "🛑 Stopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

# Step 3: Get files to merge
if ([string]::IsNullOrWhiteSpace($Files)) {
    $Files = Get-UserFileSelection -AvailableFiles $availableFiles
    
    if ([string]::IsNullOrWhiteSpace($Files)) {
        Write-Host ""
        Write-Host "❌ No files selected. Exiting..." -ForegroundColor Red
        
        if ($serverWasStarted -and $null -ne $serverProcess) {
            Write-Host "🛑 Stopping server..." -ForegroundColor Yellow
            Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
        }
        
        exit 1
    }
}

Write-Host ""
Write-Host "✅ Selected files: $Files" -ForegroundColor Green

# Step 4: Get output name (if not provided)
if ([string]::IsNullOrWhiteSpace($OutputName)) {
    Write-Host ""
    Write-Host "📝 Output file name (optional, Enter for default):" -ForegroundColor Cyan
    $OutputName = Read-Host "➤ Name"
}

if (-not [string]::IsNullOrWhiteSpace($OutputName)) {
    Write-Host "   Output name: $OutputName" -ForegroundColor Gray
}

# Step 5: Perform merge
$result = Invoke-MergeRequest -Url $BaseUrl -FileList $Files -OutputFileName $OutputName

if ($null -eq $result -or -not $result.success) {
    Write-Host ""
    Write-Host "❌ Merge failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press Enter to exit..." -ForegroundColor Gray
    Read-Host
    
    if ($serverWasStarted -and $null -ne $serverProcess) {
        Write-Host "🛑 Stopping server..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

# Step 6: Open the file
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

$shouldOpen = $AutoOpen

if (-not $AutoOpen) {
    $openChoice = Read-Host "📂 Open merged file? (Y/N)"
    $shouldOpen = ($openChoice -eq 'Y' -or $openChoice -eq 'y')
}

if ($shouldOpen -and (Test-Path $result.outputFilePath)) {
    Write-Host "📂 Opening file..." -ForegroundColor Cyan
    Start-Process $result.outputFilePath
    Write-Host ""
} elseif ($shouldOpen) {
    Write-Host "⚠️  File not found: $($result.outputFilePath)" -ForegroundColor Yellow
    Write-Host ""
}

# Step 7: Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "✨ Test completed!" -ForegroundColor Green
Write-Host ""

if ($serverWasStarted) {
    Write-Host "ℹ️  Server continues running in separate window" -ForegroundColor Cyan
    Write-Host "   You can use it again without restarting" -ForegroundColor Gray
    Write-Host "   To stop: Close server window or press Ctrl+C in that window" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📂 Output file location:" -ForegroundColor Cyan
Write-Host "   $($result.outputFilePath)" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter to finish..." -ForegroundColor Gray
Read-Host
