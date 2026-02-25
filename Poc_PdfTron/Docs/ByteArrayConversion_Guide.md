# המרת Byte Array ל-PDF - מדריך שימוש

## תיאור כללי

מערכת ההמרה תומכת כעת בהמרה ישירה מ-`byte[]` ל-PDF, ללא צורך בשמירה לקובץ פיזי תחילה.

זה שימושי במיוחד כאשר:
- הקובץ כבר נמצא בזיכרון כ-byte array
- רוצים להימנע מגישה לדיסק
- עובדים עם קבצים זמניים או דינמיים
- מקבלים נתונים מ-API אחר או מ-Database

---

## הגבלות ודרישות

### הגבלת גודל
- **מקסימום:** 50MB
- אם הקובץ גדול יותר, הבקשה תכשל עם שגיאה מפורשת

### סוגי קבצים נתמכים
המערכת תומכת באותם סוגי קבצים כמו ההמרה הרגילה:

**Microsoft Office (21 פורמטים):**
- Word: `.doc`, `.docx`, `.docm`, `.dot`, `.dotx`, `.dotm`
- Excel: `.xls`, `.xlsx`, `.xlsm`, `.xlt`, `.xltx`, `.xltm`
- PowerPoint: `.ppt`, `.pptx`, `.pptm`, `.pot`, `.potx`, `.potm`, `.pps`, `.ppsx`, `.ppsm`

**תמונות (12 פורמטים):**
- `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.tif`, `.tiff`, `.webp`, `.svg`, `.emf`, `.wmf`, `.eps`

**טקסט (4 פורמטים):**
- `.txt`, `.rtf`, `.xml`, `.md`

**אחרים:**
- `.pdf`, `.xps`, `.oxps`, `.pcl`

---

## זיהוי אוטומטי של סוג הקובץ

המערכת מזהה אוטומטית את סוג הקובץ בשתי דרכים:

### 1. זיהוי מ-Magic Bytes (עדיפות ראשונה)
המערכת בודקת את הבייטים הראשונים של הקובץ:

| סוג קובץ | Magic Bytes |
|----------|-------------|
| PDF | `%PDF` (0x25, 0x50, 0x44, 0x46) |
| DOCX/XLSX/PPTX | `PK` (0x50, 0x4B) - קובצי ZIP |
| DOC/XLS/PPT | OLE header (0xD0, 0xCF, 0x11, 0xE0...) |
| JPEG | 0xFF, 0xD8, 0xFF |
| PNG | 0x89, 0x50, 0x4E, 0x47... |
| GIF | `GIF8` (0x47, 0x49, 0x46, 0x38) |
| BMP | `BM` (0x42, 0x4D) |

### 2. זיהוי משם הקובץ (עדיפות שנייה)
אם לא הצליח לזהות מ-magic bytes, המערכת משתמשת בשדה `OriginalFileName`

### 3. זיהוי כקובץ טקסט (נסיון אחרון)
אם 95%+ מהבייטים הם תווים מודפסים ASCII, הקובץ מזוהה כ-`.txt`

---

## API Endpoints

### 1. `/api/pdfconversion/convert-from-bytes`

המרה מ-byte array והחזרת התוצאה כ-JSON (כולל PDF ב-Base64).

**Request:**
```json
{
  "fileBytes": [77, 90, 144, 0, ...],  // byte array
  "originalFileName": "document.docx",  // אופציונלי - לזיהוי סוג קובץ
  "outputFileName": "my_output"         // אופציונלי - שם הפלט (ללא .pdf)
}
```

**Response (הצלחה):**
```json
{
  "success": true,
  "pdfBytes": "JVBERi0xLjQKJeLjz9...",  // Base64 encoded PDF
  "outputFileName": "my_output.pdf",
  "pdfSizeBytes": 245678,
  "detectedFileType": ".docx",
  "conversionDuration": "00:00:02.1234567",
  "errorMessage": null,
  "errorDetails": null
}
```

**Response (כשלון):**
```json
{
  "success": false,
  "pdfBytes": null,
  "errorMessage": "File size too large (65.23MB). Maximum allowed: 50MB",
  "errorDetails": "System.ArgumentException: ..."
}
```

---

### 2. `/api/pdfconversion/convert-from-bytes-and-download`

המרה מ-byte array והחזרת קובץ PDF ישירות (להורדה).

**Request:** אותו כמו endpoint מס' 1

**Response:** 
- Content-Type: `application/pdf`
- קובץ PDF להורדה ישירה

---

## דוגמאות שימוש

### C# - קריאה מ-Disk והמרה

```csharp
using System.Net.Http.Json;

// קרא קובץ לתוך byte array
byte[] fileBytes = File.ReadAllBytes(@"C:\Temp\document.docx");

// הכן את הבקשה
var request = new
{
    FileBytes = fileBytes,
    OriginalFileName = "document.docx",
    OutputFileName = "converted_document"
};

// שלח בקשה להמרה
using var client = new HttpClient();
var response = await client.PostAsJsonAsync(
    "http://localhost:5000/api/pdfconversion/convert-from-bytes",
    request);

// קבל תשובה
var result = await response.Content.ReadFromJsonAsync<ByteConversionResponse>();

if (result.Success)
{
    // המר מ-Base64 חזרה ל-byte array
    byte[] pdfBytes = Convert.FromBase64String(result.PdfBytes);
    
    // שמור ל-disk
    File.WriteAllBytes(@"C:\Temp\output.pdf", pdfBytes);
    
    Console.WriteLine($"PDF נוצר בהצלחה: {result.PdfSizeBytes} bytes");
}
else
{
    Console.WriteLine($"שגיאה: {result.ErrorMessage}");
}
```

---

### C# - הורדה ישירה

```csharp
// קרא קובץ
byte[] fileBytes = File.ReadAllBytes(@"C:\Temp\document.docx");

// הכן בקשה
var request = new
{
    FileBytes = fileBytes,
    OriginalFileName = "document.docx",
    OutputFileName = "converted"
};

// שלח ל-endpoint שמחזיר קובץ ישירות
using var client = new HttpClient();
var response = await client.PostAsJsonAsync(
    "http://localhost:5000/api/pdfconversion/convert-from-bytes-and-download",
    request);

// קבל את ה-PDF ושמור
byte[] pdfBytes = await response.Content.ReadAsByteArrayAsync();
File.WriteAllBytes(@"C:\Temp\output.pdf", pdfBytes);
```

---

### PowerShell - המרה פשוטה

```powershell
# קרא קובץ
$fileBytes = [System.IO.File]::ReadAllBytes("C:\Temp\document.docx")

# הכן בקשה
$body = @{
    FileBytes = $fileBytes
    OriginalFileName = "document.docx"
    OutputFileName = "converted_doc"
} | ConvertTo-Json

# שלח בקשה
$response = Invoke-RestMethod `
    -Uri "http://localhost:5000/api/pdfconversion/convert-from-bytes" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body

# בדוק תוצאה
if ($response.success) {
    Write-Host "הומר בהצלחה! גודל: $($response.pdfSizeBytes) bytes"
    Write-Host "סוג קובץ שזוהה: $($response.detectedFileType)"
    
    # שמור את ה-PDF
    $pdfBytes = [Convert]::FromBase64String($response.pdfBytes)
    [System.IO.File]::WriteAllBytes("C:\Temp\output.pdf", $pdfBytes)
} else {
    Write-Host "שגיאה: $($response.errorMessage)"
}
```

---

### PowerShell - הורדה ישירה

```powershell
# קרא קובץ
$fileBytes = [System.IO.File]::ReadAllBytes("C:\Temp\image.jpg")

# הכן בקשה
$body = @{
    FileBytes = $fileBytes
    OriginalFileName = "image.jpg"
} | ConvertTo-Json

# שלח והורד ישירות
Invoke-RestMethod `
    -Uri "http://localhost:5000/api/pdfconversion/convert-from-bytes-and-download" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body `
    -OutFile "C:\Temp\output.pdf"

Write-Host "PDF נשמר בהצלחה!"
```

---

## תהליך ההמרה הפנימי

1. **קבלת byte array** - הקונטרולר מקבל את הנתונים
2. **ולידציה** - בדיקת גודל (max 50MB)
3. **זיהוי סוג קובץ** - Magic bytes → שם קובץ → ניתוח טקסט
4. **בדיקת תמיכה** - האם הסוג נתמך?
5. **שמירה זמנית** - שמירת byte array לקובץ temp
6. **המרה** - PDFTron מבצע המרה
7. **קריאה חזרה** - קריאת ה-PDF לזיכרון
8. **ניקוי** - מחיקת קבצים זמניים
9. **החזרת תוצאה** - JSON או קובץ ישירות

---

## לוגים

כל שלב בתהליך מתועד:

```
[Information] Starting byte array conversion (Size: 245678 bytes, OriginalFileName: document.docx)
[Information] Detected file type: .docx
[Information] Saved byte array to temporary file: C:\Users\...\Temp\input_guid.docx
[Information] Converting .docx to PDF...
[Debug] Using OfficeToPDF conversion for Office document
[Debug] PDFTron conversion completed successfully
[Information] PDF conversion completed. Output size: 198765 bytes
[Information] Byte array conversion completed successfully: document.pdf (Duration: 2134ms)
[Debug] Deleted temporary input file: C:\Users\...\Temp\input_guid.docx
[Debug] Deleted temporary output file: C:\Users\...\Temp\output_guid.pdf
```

---

## טיפול בשגיאות

### שגיאות נפוצות:

**1. קובץ גדול מדי:**
```json
{
  "success": false,
  "errorMessage": "File size too large (65.23MB). Maximum allowed: 50MB"
}
```

**2. לא הצליח לזהות סוג קובץ:**
```json
{
  "success": false,
  "errorMessage": "Could not detect file type. Please provide OriginalFileName parameter."
}
```

**3. סוג קובץ לא נתמך:**
```json
{
  "success": false,
  "errorMessage": "File type '.exe' is not supported. Allowed extensions: .doc, .docx, ..."
}
```

**4. שגיאת המרה:**
```json
{
  "success": false,
  "errorMessage": "Byte array conversion failed",
  "errorDetails": "pdftron.Common.PDFNetException: Invalid document format"
}
```

---

## Best Practices

### 1. תמיד ספק `OriginalFileName` אם אפשר
```csharp
// טוב ✓
var request = new
{
    FileBytes = bytes,
    OriginalFileName = "document.docx"  // עוזר לזיהוי מדויק
};

// פחות טוב ✗
var request = new
{
    FileBytes = bytes  // תלוי בזיהוי אוטומטי בלבד
};
```

### 2. בדוק גודל קובץ לפני שליחה
```csharp
if (fileBytes.Length > 50 * 1024 * 1024)  // 50MB
{
    throw new ArgumentException("File too large");
}
```

### 3. טפל בשגיאות בצורה נכונה
```csharp
try
{
    var response = await client.PostAsJsonAsync(url, request);
    response.EnsureSuccessStatusCode();
    
    var result = await response.Content.ReadFromJsonAsync<ByteConversionResponse>();
    
    if (!result.Success)
    {
        _logger.LogWarning("Conversion failed: {Error}", result.ErrorMessage);
        // טיפול בשגיאה
    }
}
catch (HttpRequestException ex)
{
    _logger.LogError(ex, "HTTP request failed");
}
```

### 4. נקה זיכרון אחרי שימוש
```csharp
byte[] largeBytes = GetLargeFile();

try
{
    // השתמש ב-bytes
    await ConvertToPdf(largeBytes);
}
finally
{
    largeBytes = null;  // אפשר ל-GC לפנות
    GC.Collect();
}
```

---

## השוואה: Byte Array vs. Upload vs. File Path

| קריטריון | Byte Array | Upload | File Path |
|----------|------------|--------|-----------|
| **מהירות** | ⚡⚡⚡ הכי מהיר | ⚡⚡ בינוני | ⚡ הכי איטי |
| **גישה לדיסק** | ❌ לא דורש | ✅ דורש (temp) | ✅ דורש |
| **בטיחות** | ✅ לא חושף paths | ✅ מבודד | ⚠️ חושף structure |
| **שימוש בזיכרון** | ⚠️ גבוה | ⚡ נמוך | ⚡ נמוך |
| **גמישות** | ✅✅✅ מלא | ✅✅ טוב | ✅ בסיסי |

**מתי להשתמש בכל אחד:**

- **Byte Array:** כשהקובץ כבר בזיכרון, צריך מהירות מקסימלית
- **Upload:** כשהמשתמש מעלה קובץ מדפדפן
- **File Path:** כשעובדים עם קבצים קיימים בשרת

---

## סיכום

המרת byte array ל-PDF מספקת:
- ✅ גמישות מרבית - עבודה עם כל מקור נתונים
- ✅ ביצועים גבוהים - ללא I/O מיותר
- ✅ בטיחות - לא חושף מבנה קבצים
- ✅ זיהוי אוטומטי - עם fallback חכם
- ✅ לוגים מפורטים - מעקב מלא אחרי התהליך
- ✅ הגבלת גודל - הגנה מפני עומס

---

**נוצר:** {{DATE}}  
**גרסה:** 1.0  
**מחבר:** PDF Conversion Service Team
