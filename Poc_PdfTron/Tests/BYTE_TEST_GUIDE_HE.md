# 🚀 בדיקת המרת Byte Array - מדריך מהיר

## איך להריץ בדיקה?

### דרך 1: בדיקה אוטומטית (הכי פשוט!)

פשוט הרץ את הסקריפט:

```powershell
Tests\quick-byte-test.ps1
```

**מה הסקריפט עושה?**
1. ✅ בודק אם השרת רץ (אם לא - מפעיל אותו!)
2. ✅ יוצר byte array מטקסט
3. ✅ שולח להמרה ל-PDF
4. ✅ שומר את ה-PDF
5. ✅ פותח אותו אוטומטית!
6. ✅ מנקה (עוצר שרת אם הופעל)

**לא צריך להפעיל את השרת בעצמך!** הסקריפט עושה הכל 🚀

---

### דרך 2: צפה בדוגמאות Byte Array

לראות איך יוצרים byte arrays:

```powershell
Tests\create-byte-array-examples.ps1
```

הסקריפט מראה:
- 📝 המרת טקסט ל-byte array
- 📄 קריאת קובץ ל-byte array
- 🔍 Magic bytes (זיהוי סוג קובץ)
- 💾 שמירת byte array לקובץ

---

### דרך 3: בדיקה ידנית (PowerShell)

הרץ שלב אחר שלב:

#### שלב 1: צור byte array
```powershell
$text = "שלום! זהו טקסט לבדיקה."
$bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
Write-Host "נוצרו $($bytes.Length) bytes"
```

#### שלב 2: שלח להמרה
```powershell
$body = @{
    FileBytes = $bytes
    OriginalFileName = "test.txt"
    OutputFileName = "my_test"
} | ConvertTo-Json

$response = Invoke-RestMethod `
    -Uri "http://localhost:5000/api/pdfconversion/convert-from-bytes" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body
```

#### שלב 3: שמור PDF
```powershell
if ($response.success) {
    $pdfBytes = [Convert]::FromBase64String($response.pdfBytes)
    [System.IO.File]::WriteAllBytes("C:\Temp\output.pdf", $pdfBytes)
    Write-Host "✓ PDF נשמר!"
    Start-Process "C:\Temp\output.pdf"
}
```

---

### דרך 4: בדיקה עם קובץ קיים

```powershell
# קרא קובץ קיים
$fileBytes = [System.IO.File]::ReadAllBytes("C:\Temp\Input\sample.docx")

# המר
$body = @{
    FileBytes = $fileBytes
    OriginalFileName = "sample.docx"
} | ConvertTo-Json

$response = Invoke-RestMethod `
    -Uri "http://localhost:5000/api/pdfconversion/convert-from-bytes" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body

# שמור תוצאה
if ($response.success) {
    $pdfBytes = [Convert]::FromBase64String($response.pdfBytes)
    [System.IO.File]::WriteAllBytes("C:\Temp\result.pdf", $pdfBytes)
    Write-Host "✓ הומר בהצלחה! סוג קובץ: $($response.detectedFileType)"
}
```

---

## 🔍 איך לבדוק שזה עובד?

### 1. בדוק שה-API רץ
```powershell
Invoke-RestMethod "http://localhost:5000/api/pdfconversion/settings"
```

אם תקבל תשובה - ה-API רץ ✅

### 2. בדוק את הלוגים
```powershell
Get-Content "Logs\log-$(Get-Date -Format 'yyyyMMdd').txt" -Tail 50 -Wait
```

תראה בלוגים:
```
[Information] Starting byte array conversion (Size: 1234 bytes, OriginalFileName: test.txt)
[Information] Detected file type: .txt
[Information] Byte array conversion completed successfully
```

### 3. בדוק את התוצאה
- PDF נשמר ב: `C:\Temp\Output\`
- פתח אותו וראה שהתוכן נכון

---

## ⚠️ פתרון בעיות נפוצות

### שגיאה: "Could not connect"
**פתרון:** ודא שהאפליקציה רצה
```powershell
cd Poc_PdfTron
dotnet run
```

### שגיאה: "File size too large"
**פתרון:** הקובץ גדול מ-50MB
- השתמש בקובץ קטן יותר
- או שנה הגדרה ב-`appsettings.json`

### שגיאה: "Could not detect file type"
**פתרון:** תן שם קובץ מפורש:
```powershell
$body = @{
    FileBytes = $bytes
    OriginalFileName = "myfile.docx"  # ← חשוב!
}
```

---

## 📊 מה לצפות לראות?

### תשובה מוצלחת:
```json
{
  "success": true,
  "pdfBytes": "JVBERi0xLjQKJe...",  // Base64
  "outputFileName": "my_test.pdf",
  "pdfSizeBytes": 12345,
  "detectedFileType": ".txt",
  "conversionDuration": "00:00:01.234"
}
```

### תשובה עם שגיאה:
```json
{
  "success": false,
  "errorMessage": "File size too large (65MB). Maximum allowed: 50MB"
}
```

---

## 🎯 דוגמאות מהירות לקופי-פייסט

### טקסט פשוט:
```powershell
$bytes = [System.Text.Encoding]::UTF8.GetBytes("Hello World!")
$body = @{ FileBytes = $bytes; OriginalFileName = "test.txt" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:5000/api/pdfconversion/convert-from-bytes" -Method Post -Body $body -ContentType "application/json"
```

### קובץ קיים:
```powershell
$bytes = [System.IO.File]::ReadAllBytes("C:\Temp\Input\file.docx")
$body = @{ FileBytes = $bytes; OriginalFileName = "file.docx" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:5000/api/pdfconversion/convert-from-bytes" -Method Post -Body $body -ContentType "application/json"
```

### הורדה ישירה:
```powershell
$bytes = [System.Text.Encoding]::UTF8.GetBytes("Test document")
$body = @{ FileBytes = $bytes; OriginalFileName = "test.txt" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:5000/api/pdfconversion/convert-from-bytes-and-download" -Method Post -Body $body -ContentType "application/json" -OutFile "output.pdf"
```

---

## 🎉 סיכום

**הדרך הכי מהירה לבדוק:**
```powershell
# 1. הרץ סקריפט בדיקה
Tests\quick-byte-test.ps1

# 2. ראה דוגמאות
Tests\create-byte-array-examples.ps1
```

**זהו! תהנה מההמרה! 🚀**
