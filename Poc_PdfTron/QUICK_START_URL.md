# 🚀 המרת URL ל-PDF - הוראות הפעלה

## ✅ השינויים בוצעו בהצלחה!

תכונה חדשה: המרת דפי HTML מאינטרנט (URL) ל-PDF עם תמיכה מלאה בעברית.

---

## 📋 הוראות הפעלה - 3 שלבים פשוטים

### **שלב 1: הפעל את השרת**

פתח PowerShell/Terminal בתיקיית הפרויקט והרץ:

```powershell
cd Poc_PdfTron
dotnet run
```

**המתן להודעה:**
```
========================================
  PDF Conversion API is ready!
========================================
  Listening on: http://localhost:5063
```

**אל תסגור את החלון הזה!** השרת צריך להישאר פועל.

---

### **שלב 2: הרץ את סקריפט הבדיקה**

פתח **PowerShell חדש** (חלון נוסף) והרץ:

```powershell
.\Tests\test-url-conversion.ps1
```

---

### **שלב 3: הזן URL**

הסקריפט ישאל אותך:

```
========================================
  המרת HTML מ-URL ל-PDF - בדיקה
========================================

הזן כתובת URL של דף HTML להמרה:
דוגמאות:
  https://www.example.com
  https://www.wikipedia.org
  https://www.ynet.co.il

URL: 
```

**הזן URL** (לדוגמה: `https://www.ynet.co.il`) ולחץ Enter.

הסקריפט ישאל:
```
שם קובץ פלט (אופציונלי, Enter לדלג):
```

לחץ Enter או הזן שם כמו `ynet_homepage`.

---

### **שלב 4: קבל את התוצאה**

```
✓ המרה הצליחה!
משך זמן: 8.45 שניות

✓ PDF נשמר בהצלחה!
מיקום: OutputFolder\url_conversion_20260222_153045.pdf
גודל: 234.5 KB

לפתוח את ה-PDF? (y/n): 
```

הקש **y** והקובץ ייפתח אוטומטית!

---

## ✨ דוגמאות URL לבדיקה

| URL | תיאור |
|-----|-------|
| `https://www.example.com` | דף פשוט באנגלית |
| `https://www.ynet.co.il` | אתר חדשות בעברית |
| `https://he.wikipedia.org` | ויקיפדיה עברית |
| `https://www.google.com` | גוגל |

---

## 🎯 איך זה עובד?

1. **הסקריפט שולח** את ה-URL ל-API
2. **השרת מוריד** את ה-HTML מהאינטרנט
3. **השרת שומר** את ה-HTML בקובץ זמני (UTF-8)
4. **PDFTron ממיר** את ה-HTML ל-PDF
5. **ה-PDF נשמר** ב-`OutputFolder`
6. **קובץ זמני נמחק** אוטומטית

---

## 🔧 שימוש ידני (ללא סקריפט)

אם אתה רוצה לבדוק ישירות עם PowerShell:

```powershell
# הכן את הבקשה
$body = @{
    url = "https://www.example.com"
    outputFileName = "my_page"
} | ConvertTo-Json

# שלח את הבקשה
$response = Invoke-WebRequest `
    -Uri "http://localhost:5063/api/pdfconversion/convert-from-url" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

# שמור את ה-PDF
[System.IO.File]::WriteAllBytes("output.pdf", $response.Content)
Write-Host "PDF נשמר: output.pdf ($($response.Content.Length) bytes)"
```

---

## ⚠️ פתרון בעיות

### בעיה: "השרת לא פעיל"
**פתרון:** הפעל את השרת:
```powershell
dotnet run --project Poc_PdfTron
```

---

### בעיה: "HTML2PDF module not found"
**פתרון:** התקן את מודול HTML2PDF:
```powershell
.\Tests\install-html2pdf-module.ps1 -ModulePath "C:\Downloads\html2pdf.dll"
```

ראה: `Docs\HTML2PDF_Installation_Guide_HE.md`

---

### בעיה: "Failed to download HTML from URL"
**פתרונות:**
- ✅ בדוק חיבור אינטרנט
- ✅ ודא שה-URL נגיש (נסה לפתוח בדפדפן)
- ✅ ודא שה-URL מתחיל ב-`http://` או `https://`

---

### בעיה: תוכן עברי לא מוצג נכון
**הפתרון כבר מובנה!** 
- ✅ UTF-8 encoding אוטומטי
- ✅ RTL support מובנה
- ✅ Hebrew fonts נתמכים

אם עדיין יש בעיה:
- ודא שהדף המקורי משתמש ב-`<meta charset="UTF-8">`
- בדוק ב-`Logs\log-yyyyMMdd.txt` לפרטים

---

## 📊 מה השתנה בקוד?

### קבצים חדשים:
- ✅ `Models\UrlConversionRequest.cs` - מודל לבקשת URL
- ✅ `Tests\test-url-conversion.ps1` - סקריפט בדיקה
- ✅ `Tests\URL_CONVERSION_GUIDE.md` - מדריך זה

### קבצים שעודכנו:
- ✅ `IPdfConversionService.cs` - נוספה מתודה `ConvertUrlToPdfAsync`
- ✅ `PdfConversionService.cs` - מימוש הורדת HTML והמרה
- ✅ `PdfConversionController.cs` - endpoint חדש `/convert-from-url`
- ✅ `README.md` - עודכן עם התיעוד

---

## 🎉 זהו! הכל מוכן לשימוש

**הרץ את הסקריפט והתחל להמיר דפים לPDF! 🚀**

```powershell
.\Tests\test-url-conversion.ps1
```
