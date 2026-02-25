# ====================================================================================================
# Script: test-url-conversion.ps1
# Description: בדיקת המרת HTML מ-URL ל-PDF
# ====================================================================================================

# הגדרות
$ApiUrl = "http://localhost:5063"
$OutputFolder = "OutputFolder"

# צבעים לפלט
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-Host ""
Write-ColorOutput Green "=========================================="
Write-ColorOutput Green "  המרת HTML מ-URL ל-PDF - בדיקה"
Write-ColorOutput Green "=========================================="
Write-Host ""

# בדיקה שהשרת רץ
Write-Host "בודק אם השרת פעיל..."
try {
    $healthCheck = Invoke-RestMethod -Uri "$ApiUrl/health" -Method Get -TimeoutSec 3
    Write-ColorOutput Green "✓ השרת פעיל"
} catch {
    Write-ColorOutput Red "✗ השרת לא פעיל!"
    Write-ColorOutput Yellow "הפעל את השרת עם: dotnet run --project Poc_PdfTron"
    exit 1
}

Write-Host ""

# בקשת URL מהמשתמש
Write-ColorOutput Cyan "הזן כתובת URL של דף HTML להמרה:"
Write-Host "דוגמאות:"
Write-Host "  https://www.example.com"
Write-Host "  https://www.wikipedia.org"
Write-Host "  https://www.ynet.co.il"
Write-Host ""
$url = Read-Host "URL"

# בדיקה שהוזן URL
if ([string]::IsNullOrWhiteSpace($url)) {
    Write-ColorOutput Red "✗ לא הוזן URL!"
    exit 1
}

# בדיקה שה-URL תקין
if (-not ($url -match '^https?://')) {
    Write-ColorOutput Red "✗ URL לא תקין! חייב להתחיל ב-http:// או https://"
    exit 1
}

Write-Host ""
Write-ColorOutput Cyan "שם קובץ פלט (אופציונלי, Enter לדלג):"
$outputFileName = Read-Host "שם קובץ"

Write-Host ""
Write-Host "מתחיל המרה..."
Write-Host "URL: $url"
Write-Host ""

# הכנת הבקשה
$body = @{
    url = $url
}

if (-not [string]::IsNullOrWhiteSpace($outputFileName)) {
    $body.outputFileName = $outputFileName
}

$jsonBody = $body | ConvertTo-Json

Write-ColorOutput Yellow "שולח בקשה ל-API..."

try {
    # שליחת הבקשה
    $startTime = Get-Date
    
    $response = Invoke-WebRequest `
        -Uri "$ApiUrl/api/pdfconversion/convert-from-url" `
        -Method Post `
        -Body $jsonBody `
        -ContentType "application/json" `
        -TimeoutSec 60
    
    $duration = (Get-Date) - $startTime
    
    if ($response.StatusCode -eq 200) {
        Write-ColorOutput Green "✓ המרה הצליחה!"
        Write-Host "משך זמן: $([math]::Round($duration.TotalSeconds, 2)) שניות"
        
        # קבלת שם הקובץ מה-header
        $fileName = "url_conversion.pdf"
        if ($response.Headers."Content-Disposition") {
            $contentDisposition = $response.Headers."Content-Disposition"[0]
            if ($contentDisposition -match 'filename="?([^"]+)"?') {
                $fileName = $matches[1]
            }
        }
        
        # שמירת הקובץ
        $outputPath = Join-Path $OutputFolder $fileName
        [System.IO.File]::WriteAllBytes($outputPath, $response.Content)
        
        Write-Host ""
        Write-ColorOutput Green "✓ PDF נשמר בהצלחה!"
        Write-Host "מיקום: $outputPath"
        Write-Host "גודל: $([math]::Round($response.Content.Length / 1KB, 2)) KB"
        
        # שאלה האם לפתוח את הקובץ
        Write-Host ""
        $openFile = Read-Host "לפתוח את ה-PDF? (y/n)"
        
        if ($openFile -eq 'y') {
            Start-Process $outputPath
            Write-ColorOutput Green "✓ הקובץ נפתח"
        }
        
    } else {
        Write-ColorOutput Red "✗ המרה נכשלה!"
        Write-Host "קוד שגיאה: $($response.StatusCode)"
    }
    
} catch {
    Write-ColorOutput Red "✗ שגיאה בהמרה!"
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $statusDescription = $_.Exception.Response.StatusDescription
        
        Write-Host "קוד שגיאה: $statusCode - $statusDescription"
        
        # ניסיון לקרוא את תוכן השגיאה
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errorContent = $reader.ReadToEnd()
            $reader.Close()
            
            # ניסיון לפרסר כ-JSON
            try {
                $errorJson = $errorContent | ConvertFrom-Json
                if ($errorJson.detail) {
                    Write-Host "פרטי שגיאה: $($errorJson.detail)"
                }
            } catch {
                Write-Host "פרטי שגיאה: $errorContent"
            }
        } catch {
            # לא הצלחנו לקרוא את תוכן השגיאה
        }
    } else {
        Write-Host "שגיאה: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-ColorOutput Green "=========================================="
Write-ColorOutput Green "  הבדיקה הסתיימה"
Write-ColorOutput Green "=========================================="
Write-Host ""
