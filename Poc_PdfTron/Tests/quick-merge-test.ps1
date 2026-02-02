# Quick Merge Test - Automatic Server Start + Merge Test
# סקריפט בדיקה מלא - מפעיל שרת ובודק איחוד קבצים

<#
.SYNOPSIS
    סקריפט אוטומטי להרצת שרת ובדיקת איחוד קבצים ל-PDF

.DESCRIPTION
    הסקריפט:
    1. בודק אם השרת רץ, ואם לא - מפעיל אותו אוטומטית
    2. מאפשר לך לבחור קבצים לאיחוד
    3. מבצע את האיחוד
    4. פותח את התוצאה

.PARAMETER Files
    רשימת קבצים לאיחוד (מופרדת בפסיקים)
    דוגמה: "file1.docx,file2.xlsx,file3.jpg"

.PARAMETER OutputName
    שם לקובץ הפלט (אופציונלי)

.PARAMETER AutoOpen
    לפתוח את הקובץ המאוחד אוטומטית (ברירת מחדל: true)

.EXAMPLE
    .\quick-merge-test.ps1
    # מצב אינטראקטיבי - הסקריפט ישאל אותך מה לאחד

.EXAMPLE
    .\quick-merge-test.ps1 -Files "doc1.docx,image.jpg,report.xlsx"
    # מאחד את הקבצים שצוינו

.EXAMPLE
    .\quick-merge-test.ps1 -Files "file1.docx,file2.pdf" -OutputName "merged_report"
    # מאחד עם שם מותאם אישית
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
    Write-Host "║              בדיקה מהירה ואיחוד קבצים ל-PDF              ║" -ForegroundColor Cyan
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
    
    Write-Host "🚀 מפעיל שרת..." -ForegroundColor Yellow
    Write-Host ""
    
    # Find project directory
    $scriptDir = Split-Path -Parent $PSCommandPath
    $projectDir = Split-Path -Parent $scriptDir
    $csprojPath = Join-Path $projectDir "Poc_PdfTron.csproj"
    
    if (-not (Test-Path $csprojPath)) {
        Write-Host "❌ לא נמצא קובץ הפרויקט: $csprojPath" -ForegroundColor Red
        return $null
    }
    
    Write-Host "📁 מיקום הפרויקט: $projectDir" -ForegroundColor Gray
    
    # Start server in new window
    $serverProcess = Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "cd '$projectDir'; Write-Host '🚀 מפעיל שרת PDF...' -ForegroundColor Cyan; dotnet run"
    ) -PassThru -WindowStyle Normal
    
    Write-Host "⏳ ממתין לשרת להתחיל..." -ForegroundColor Yellow
    
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
            Write-Host "  ממתין... ($waited/$maxWait שניות)" -ForegroundColor Gray
        }
    }
    
    if ($serverStarted) {
        Write-Host ""
        Write-Host "✅ השרת הופעל בהצלחה!" -ForegroundColor Green
        Write-Host "🌐 כתובת: $Url" -ForegroundColor Green
        Write-Host ""
        return $serverProcess
    } else {
        Write-Host ""
        Write-Host "❌ השרת לא עלה אחרי $maxWait שניות" -ForegroundColor Red
        Write-Host "   בדוק את החלון שנפתח לשגיאות" -ForegroundColor Yellow
        return $null
    }
}

function Get-AvailableFiles {
    param([string]$FolderPath)
    
    if (-not (Test-Path $FolderPath)) {
        Write-Host "⚠️  תיקיית הקלט לא קיימת: $FolderPath" -ForegroundColor Yellow
        Write-Host "   יוצר תיקייה..." -ForegroundColor Gray
        New-Item -ItemType Directory -Path $FolderPath -Force | Out-Null
        return @()
    }
    
    $files = Get-ChildItem -Path $FolderPath -File | Select-Object -ExpandProperty Name
    return $files
}

function Show-FileList {
    param([array]$Files)
    
    Write-Host "📂 קבצים זמינים בתיקיית הקלט:" -ForegroundColor Cyan
    Write-Host "   מיקום: $InputFolder" -ForegroundColor Gray
    Write-Host ""
    
    if ($Files.Count -eq 0) {
        Write-Host "   ⚠️  לא נמצאו קבצים!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   💡 הוסף קבצים לתיקייה:" -ForegroundColor Yellow
        Write-Host "      $InputFolder" -ForegroundColor White
        Write-Host ""
        Write-Host "   סוגי קבצים נתמכים:" -ForegroundColor Gray
        Write-Host "      • Word: .docx, .doc" -ForegroundColor Gray
        Write-Host "      • Excel: .xlsx, .xls" -ForegroundColor Gray
        Write-Host "      • PowerPoint: .pptx, .ppt" -ForegroundColor Gray
        Write-Host "      • תמונות: .jpg, .png, .gif, .bmp" -ForegroundColor Gray
        Write-Host "      • טקסט: .txt, .rtf" -ForegroundColor Gray
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
    Write-Host "📝 הזן את שמות הקבצים לאיחוד (מופרדים בפסיק):" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   דוגמאות:" -ForegroundColor Gray
    Write-Host "   • file1.docx,file2.xlsx,file3.jpg" -ForegroundColor White
    Write-Host "   • document.docx,image.png" -ForegroundColor White
    Write-Host ""
    Write-Host "   או הזן מספרים: 1,2,3" -ForegroundColor Gray
    Write-Host ""
    
    $input = Read-Host "➤ קבצים"
    
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
                Write-Host "   ⚠️  מספר לא תקין: $num" -ForegroundColor Yellow
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
    Write-Host "🔄 מאחד קבצים..." -ForegroundColor Cyan
    Write-Host ""
    
    $mergeRequest = @{
        sourceFiles = $FileList
    }
    
    if (-not [string]::IsNullOrWhiteSpace($OutputFileName)) {
        $mergeRequest.outputFileName = $OutputFileName
    }
    
    $requestJson = $mergeRequest | ConvertTo-Json
    
    Write-Host "📤 שולח בקשה:" -ForegroundColor Gray
    Write-Host $requestJson -ForegroundColor DarkGray
    Write-Host ""
    
    try {
        $result = Invoke-RestMethod -Uri "$Url/api/pdfconversion/merge" `
            -Method Post `
            -Body $requestJson `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        Write-Host "✅ איחוד הושלם בהצלחה!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 תוצאות:" -ForegroundColor Cyan
        Write-Host "   • קובץ פלט: $($result.outputFileName)" -ForegroundColor White
        Write-Host "   • מיקום: $($result.outputFilePath)" -ForegroundColor Gray
        Write-Host "   • קבצים עובדו: $($result.filesProcessed)/$($result.totalFiles)" -ForegroundColor White
        Write-Host "   • משך זמן: $($result.duration)" -ForegroundColor Gray
        Write-Host ""
        
        if ($result.successfulFiles.Count -gt 0) {
            Write-Host "✅ קבצים שאוחדו בהצלחה:" -ForegroundColor Green
            $result.successfulFiles | ForEach-Object { 
                Write-Host "   ✓ $_" -ForegroundColor Green 
            }
            Write-Host ""
        }
        
        if ($result.failedFiles.Count -gt 0) {
            Write-Host "❌ קבצים שנכשלו:" -ForegroundColor Red
            $result.failedFiles | ForEach-Object { 
                Write-Host "   ✗ $($_.fileName)" -ForegroundColor Red
                Write-Host "     שגיאה: $($_.errorMessage)" -ForegroundColor Yellow
            }
            Write-Host ""
        }
        
        return $result
        
    } catch {
        Write-Host "❌ האיחוד נכשל!" -ForegroundColor Red
        Write-Host "   שגיאה: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.ErrorDetails.Message) {
            try {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "   פרטים: $($errorDetails.detail)" -ForegroundColor Yellow
            } catch {
                Write-Host "   פרטים: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
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
Write-Host "🔍 בודק אם השרת רץ..." -ForegroundColor Cyan

$serverProcess = $null
$serverWasStarted = $false

if (Test-ServerRunning -Url $BaseUrl) {
    Write-Host "✅ השרת כבר רץ!" -ForegroundColor Green
    Write-Host "🌐 כתובת: $BaseUrl" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "⚠️  השרת לא רץ" -ForegroundColor Yellow
    Write-Host ""
    
    $serverProcess = Start-PdfServer -Url $BaseUrl
    
    if ($null -eq $serverProcess) {
        Write-Host ""
        Write-Host "❌ לא ניתן להפעיל את השרת" -ForegroundColor Red
        Write-Host "   הפעל את השרת ידנית: dotnet run" -ForegroundColor Yellow
        exit 1
    }
    
    $serverWasStarted = $true
}

# Step 2: Get available files
$availableFiles = Get-AvailableFiles -FolderPath $InputFolder

if (-not (Show-FileList -Files $availableFiles)) {
    Write-Host "לחץ Enter ליציאה..." -ForegroundColor Gray
    Read-Host
    
    if ($serverWasStarted -and $null -ne $serverProcess) {
        Write-Host "🛑 עוצר את השרת..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

# Step 3: Get files to merge
if ([string]::IsNullOrWhiteSpace($Files)) {
    $Files = Get-UserFileSelection -AvailableFiles $availableFiles
    
    if ([string]::IsNullOrWhiteSpace($Files)) {
        Write-Host ""
        Write-Host "❌ לא נבחרו קבצים. יוצא..." -ForegroundColor Red
        
        if ($serverWasStarted -and $null -ne $serverProcess) {
            Write-Host "🛑 עוצר את השרת..." -ForegroundColor Yellow
            Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
        }
        
        exit 1
    }
}

Write-Host ""
Write-Host "✅ נבחרו קבצים: $Files" -ForegroundColor Green

# Step 4: Get output name (if not provided)
if ([string]::IsNullOrWhiteSpace($OutputName)) {
    Write-Host ""
    Write-Host "📝 שם לקובץ הפלט (אופציונלי, Enter לברירת מחדל):" -ForegroundColor Cyan
    $OutputName = Read-Host "➤ שם"
}

if (-not [string]::IsNullOrWhiteSpace($OutputName)) {
    Write-Host "   שם הפלט: $OutputName" -ForegroundColor Gray
}

# Step 5: Perform merge
$result = Invoke-MergeRequest -Url $BaseUrl -FileList $Files -OutputFileName $OutputName

if ($null -eq $result -or -not $result.success) {
    Write-Host ""
    Write-Host "❌ האיחוד נכשל" -ForegroundColor Red
    Write-Host ""
    Write-Host "לחץ Enter ליציאה..." -ForegroundColor Gray
    Read-Host
    
    if ($serverWasStarted -and $null -ne $serverProcess) {
        Write-Host "🛑 עוצר את השרת..." -ForegroundColor Yellow
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }
    
    exit 1
}

# Step 6: Open the file
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

$shouldOpen = $AutoOpen

if (-not $AutoOpen) {
    $openChoice = Read-Host "📂 לפתוח את הקובץ המאוחד? (Y/N)"
    $shouldOpen = ($openChoice -eq 'Y' -or $openChoice -eq 'y')
}

if ($shouldOpen -and (Test-Path $result.outputFilePath)) {
    Write-Host "📂 פותח את הקובץ..." -ForegroundColor Cyan
    Start-Process $result.outputFilePath
    Write-Host ""
} elseif ($shouldOpen) {
    Write-Host "⚠️  הקובץ לא נמצא: $($result.outputFilePath)" -ForegroundColor Yellow
    Write-Host ""
}

# Step 7: Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "✨ הבדיקה הושלמה!" -ForegroundColor Green
Write-Host ""

if ($serverWasStarted) {
    Write-Host "ℹ️  השרת ממשיך לרוץ בחלון הנפרד" -ForegroundColor Cyan
    Write-Host "   אפשר להשתמש בו שוב ללא הפעלה מחדש" -ForegroundColor Gray
    Write-Host "   לעצירה: סגור את חלון השרת או לחץ Ctrl+C בחלון" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📂 קובץ הפלט נמצא ב:" -ForegroundColor Cyan
Write-Host "   $($result.outputFilePath)" -ForegroundColor White
Write-Host ""
Write-Host "לחץ Enter לסיום..." -ForegroundColor Gray
Read-Host
