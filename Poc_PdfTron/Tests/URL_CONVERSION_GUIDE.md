# 🔗 המרת URL ל-PDF - הוראות הפעלה

## דרישות
1. השרת רץ (ראה בלוג: `[info]: Application started`)
2. מודול HTML2PDF מותקן (ראה README עיקרי)

---

## 🚀 הפעלה מהירה

### שלב 1: הפעל את השרת
```powershell
cd Poc_PdfTron
dotnet run
```

**המתן להודעה:** `Now listening on: http://localhost:5063`

---

### שלב 2: הרץ את סקריפט הבדיקה
**בטרמינל חדש:**
```powershell
.\Tests\test-url-conversion.ps1
```

---

### שלב 3: הזן URL
הסקריפט יבקש ממך:
1. **כתובת URL** (לדוגמה: `https://www.ynet.co.il`)
2. **שם קובץ** (אופציונלי - לחץ Enter לדלג)

---

### שלב 4: קבל את ה-PDF
- הקובץ יישמר אוטומטית ב-`OutputFolder`
- הסקריפט ישאל אם לפתוח את הקובץ

---

## ✅ דוגמאות URL לבדיקה

```
https://www.example.com
https://www.wikipedia.org
https://www.ynet.co.il
https://www.google.com
```

---

## 🔧 שימוש ידני (ללא סקריפט)

### PowerShell
```powershell
$body = @{
    url = "https://www.example.com"
    outputFileName = "example_page"
} | ConvertTo-Json

$response = Invoke-WebRequest `
    -Uri "http://localhost:5063/api/pdfconversion/convert-from-url" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

[System.IO.File]::WriteAllBytes("output.pdf", $response.Content)
```

### cURL
```bash
curl -X POST http://localhost:5063/api/pdfconversion/convert-from-url \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"https://www.example.com\"}" \
  --output output.pdf
```

---

## ⚠️ הערות חשובות

1. **URL חייב להיות תקין** - להתחיל ב-`http://` או `https://`
2. **מודול HTML2PDF נדרש** - אם קיבלת שגיאה, התקן את המודול
3. **זמן המרה** - תלוי במהירות הרשת וגודל הדף (5-30 שניות)
4. **תמיכה בעברית** - HTML עם UTF-8 encoding יומר בצורה מושלמת

---

## 🐛 פתרון בעיות

**שגיאה: "השרת לא פעיל"**
- ✅ הפעל את השרת: `dotnet run --project Poc_PdfTron`

**שגיאה: "HTML2PDF module not found"**
- ✅ התקן את מודול HTML2PDF (ראה README עיקרי)

**שגיאה: "Failed to download HTML from URL"**
- ✅ בדוק את חיבור האינטרנט
- ✅ ודא שה-URL נגיש (נסה לפתוח בדפדפן)

**תוכן עברי לא מוצג נכון**
- ✅ ודא שהדף המקורי משתמש ב-UTF-8 encoding
- ✅ בדוק שיש `<meta charset="UTF-8">` ב-HTML
