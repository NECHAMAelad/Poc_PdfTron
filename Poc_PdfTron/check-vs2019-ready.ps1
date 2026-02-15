# בדיקת תאימות Visual Studio 2019
# Script to verify VS2019 compatibility

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   בדיקת תאימות Visual Studio 2019" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check .NET SDK
Write-Host "1. בודק התקנת .NET SDK..." -ForegroundColor Yellow
try {
    $sdks = dotnet --list-sdks
    $hasDotNet6 = $sdks | Where-Object { $_ -match "^6\.0\." }
    
    if ($hasDotNet6) {
        Write-Host "   ✅ .NET 6.0 SDK מותקן:" -ForegroundColor Green
        $hasDotNet6 | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
    } else {
        Write-Host "   ❌ .NET 6.0 SDK לא מותקן!" -ForegroundColor Red
        Write-Host "   הורד מכאן: https://dotnet.microsoft.com/download/dotnet/6.0" -ForegroundColor Yellow
        Write-Host "   או ראה: INSTALL_DOTNET6_HE.md" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "   ❌ dotnet לא נמצא! התקן .NET 6.0 SDK" -ForegroundColor Red
    Write-Host "   הורד מכאן: https://dotnet.microsoft.com/download/dotnet/6.0" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 2. Check project file
Write-Host "2. בודק קובץ פרויקט..." -ForegroundColor Yellow
$projectFile = "Poc_PdfTron.csproj"

if (Test-Path $projectFile) {
    $content = Get-Content $projectFile -Raw
    
    if ($content -match "<TargetFramework>net6\.0</TargetFramework>") {
        Write-Host "   ✅ Target Framework: net6.0" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Target Framework לא net6.0!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   ❌ קובץ פרויקט לא נמצא!" -ForegroundColor Red
    Write-Host "   הרץ סקריפט מתיקיית Poc_PdfTron" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 3. Restore packages
Write-Host "3. משחזר חבילות NuGet..." -ForegroundColor Yellow
try {
    $restoreOutput = dotnet restore 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Restore הצליח" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Restore נכשל!" -ForegroundColor Red
        Write-Host $restoreOutput
        exit 1
    }
} catch {
    Write-Host "   ❌ שגיאה ב-Restore" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 4. Build project
Write-Host "4. בונה את הפרויקט..." -ForegroundColor Yellow
try {
    $buildOutput = dotnet build --no-restore 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Build הצליח!" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Build נכשל!" -ForegroundColor Red
        Write-Host $buildOutput
        exit 1
    }
} catch {
    Write-Host "   ❌ שגיאה ב-Build" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 5. Check PDFNetC.dll
Write-Host "5. בודק PDFNetC.dll..." -ForegroundColor Yellow
$pdfnetcPath = "bin\Debug\net6.0\PDFNetC.dll"
if (Test-Path $pdfnetcPath) {
    $fileSize = (Get-Item $pdfnetcPath).Length / 1MB
    Write-Host "   ✅ PDFNetC.dll נמצא ($($fileSize.ToString('F2')) MB)" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  PDFNetC.dll לא נמצא - אבל אמור להיווצר בזמן Build" -ForegroundColor Yellow
}

Write-Host ""

# 6. Check packages
Write-Host "6. בודק חבילות..." -ForegroundColor Yellow
try {
    $packages = dotnet list package | Out-String
    
    if ($packages -match "PDFTron\.NET\.x64\s+[\d.]+\s+([\d.]+)") {
        $pdftronVersion = $Matches[1]
        Write-Host "   ✅ PDFTron.NET.x64: $pdftronVersion" -ForegroundColor Green
    }
    
    if ($packages -match "Swashbuckle\.AspNetCore\s+[\d.]+\s+([\d.]+)") {
        $swaggerVersion = $Matches[1]
        Write-Host "   ✅ Swashbuckle.AspNetCore: $swaggerVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️  לא הצליח לבדוק חבילות" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   סיכום" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ הפרויקט מוכן לשימוש ב-Visual Studio 2019!" -ForegroundColor Green
Write-Host ""
Write-Host "צעדים הבאים:" -ForegroundColor Yellow
Write-Host "1. פתח Visual Studio 2019 (גרסה 16.11+)" -ForegroundColor White
Write-Host "2. פתח את הקובץ: Poc_PdfTron.csproj" -ForegroundColor White
Write-Host "3. לחץ F5 להרצה" -ForegroundColor White
Write-Host ""
Write-Host "מדריכים נוספים:" -ForegroundColor Yellow
Write-Host "- VS2019_COMPATIBILITY.md (מדריך מפורט)" -ForegroundColor White
Write-Host "- CHANGES_SUMMARY_HE.md (סיכום שינויים)" -ForegroundColor White
Write-Host "- INSTALL_DOTNET6_HE.md (התקנת .NET 6)" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
