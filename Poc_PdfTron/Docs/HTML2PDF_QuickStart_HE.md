# 📘 מדריך מהיר - המרת HTML ל-PDF

## 🎯 מה השתנה?

הפרויקט **Poc_PdfTron** כעת תומך בהמרת קבצי HTML מורכבים ל-PDF באמצעות **PDFTron HTML2PDF**!

### ✅ יכולות חדשות:
- ✔️ המרת HTML מורכב עם CSS מתקדם
- ✔️ תמיכה מלאה בעברית וישור RTL
- ✔️ שמירה על כל העיצוב: צבעים, גופנים, טבלאות
- ✔️ תמיכה ב-JavaScript Rendering
- ✔️ הגדרות מתקדמות: גודל דף, שוליים, רזולוציה
- ✔️ **אין צורך ב-Microsoft Word!**

---

## 🚀 התחלה מהירה

### שלב 1: הכנת קובץ HTML

צור קובץ HTML (למשל `myDocument.html`):

```html
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>המסמך שלי</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            direction: rtl;
            text-align: right;
        }
        h1 { 
            color: #2c3e50; 
            font-size: 28px;
        }
        .highlight {
            background: yellow;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h1>שלום עולם!</h1>
    <p>זהו מסמך <span class="highlight">HTML פשוט</span> בעברית.</p>
    <p>הוא יומר ל-PDF בשמירה מלאה על העיצוב!</p>
</body>
</html>
```

### שלב 2: העתק את הקובץ לתיקייה

```powershell
Copy-Item "myDocument.html" -Destination "C:\Temp\Input\"
```

### שלב 3: הפעל את השרת

```powershell
cd C:\Users\NechamaO\Documents\finals\Poc_PdfTron\Poc_PdfTron
dotnet run
```

השרת יפעל בכתובת: `http://localhost:5063`

### שלב 4: המר את הקובץ

#### אפשרות א': דרך Swagger UI

1. פתח דפדפן: `http://localhost:5063/swagger`
2. בחר ב-endpoint: `POST /api/pdfconversion/convert`
3. לחץ "Try it out"
4. הזן:
```json
{
  "sourceFilePath": "C:\\Temp\\Input\\myDocument.html",
  "outputFileName": "myDocument_output"
}
```
5. לחץ "Execute"

#### אפשרות ב': דרך PowerShell

```powershell
$body = @{
    sourceFilePath = "C:\Temp\Input\myDocument.html"
    outputFileName = "myDocument_output"
} | ConvertTo-Json

$result = Invoke-RestMethod `
    -Uri "http://localhost:5063/api/pdfconversion/convert" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

# פתח את ה-PDF
Start-Process $result.outputFilePath
```

#### אפשרות ג': דרך הממשק הגרפי

1. פתח דפדפן: `http://localhost:5063/pdf-viewer.html`
2. בחר את קובץ ה-HTML
3. לחץ "Convert & Show PDF"
4. הקובץ יוצג מיד בדפדפן!

---

## 🧪 בדיקה מהירה עם קובץ הדוגמה

הפרויקט כולל קובץ HTML מורכב לבדיקה:

```powershell
cd C:\Users\NechamaO\Documents\finals\Poc_PdfTron\Poc_PdfTron\Tests
.\test-html-conversion.ps1
```

הסקריפט יבצע:
1. ✅ בדיקת קיום קובץ HTML הדוגמה
2. ✅ בדיקת פעילות השרת
3. ✅ בדיקת תקינות הקובץ
4. ✅ המרה ל-PDF
5. ✅ בדיקת המרה דרך Byte Array
6. ✅ פתיחת ה-PDF אוטומטית

---

## 🎨 קובץ הדוגמה המורכב

הקובץ `test-complex-hebrew.html` כולל:

- ✅ **גופנים שונים**: Arial, Times New Roman, Courier, David
- ✅ **גדלים שונים**: 12px, 14px, 18px, 24px
- ✅ **צבעים**: כחול, אדום, ירוק, כתום, סגול
- ✅ **עיצובים**: מודגש, נטוי, קו תחתון
- ✅ **ישורים**: RTL (ימין לשמאל) ו-LTR (שמאל לימין)
- ✅ **טבלאות** עם עיצוב מלא
- ✅ **רשימות**: ממוספרות וממוקדות
- ✅ **תיבות מידע** צבעוניות
- ✅ **שילוב עברית ואנגלית**

---

## ⚙️ הגדרות והתאמה אישית

### הגדרות בסיסיות (ברירת מחדל)

המערכת משתמשת בהגדרות ברירת המחדל של PDFTron HTML2PDF:
- **גודל דף**: A4 (595x842 נקודות)
- **כיוון**: Portrait (אורך)
- **שוליים**: 0.5 אינץ' מכל צד
- **רזולוציה**: 96 DPI
- **JavaScript**: מופעל אוטומטית
- **CSS**: תמיכה מלאה ב-CSS3

### התאמה אישית מתקדמת

אם תרצה להתאים את ההגדרות, יש לערוך את `PdfConversionService.cs` (שורות 373-389):

```csharp
var html2Pdf = new pdftron.PDF.HTML2PDF();

// כאן אפשר להוסיף הגדרות מתקדמות
// (תלוי בגרסת PDFTron SDK שלך)

html2Pdf.InsertFromURL(sourceFilePath);
html2Pdf.Convert(pdfDoc);
```

**הערה חשובה**: ה-API של PDFTron עשוי להשתנות בין גרסאות. לתיעוד המלא, ראה:
- [PDFTron HTML2PDF Documentation](https://www.pdftron.com/documentation/core/info/modules/html2pdf/)

### טיפים לשיפור איכות

1. **CSS פנימי**: שמור את כל ה-CSS בתוך תג `<style>` ב-`<head>`
2. **גופנים**: השתמש בגופנים סטנדרטיים (Arial, Tahoma, David) לתמיכה טובה יותר בעברית
3. **תמונות**: השתמש ב-Base64 encoded images או נתיבים מוחלטים
4. **טבלאות**: השתמש ב-`border-collapse: collapse` לטבלאות מעוצבות
5. **כיוון עברית**: הוסף תמיד `dir="rtl"` ל-HTML או לאלמנטים ספציפיים

---

## 📊 המרה דרך Byte Array

אם ה-HTML שלך כבר בזיכרון (למשל מ-database), אפשר להמיר ישירות:

```powershell
# קרא HTML
$htmlContent = Get-Content "myDocument.html" -Raw -Encoding UTF8
$htmlBytes = [System.Text.Encoding]::UTF8.GetBytes($htmlContent)
$base64Html = [Convert]::ToBase64String($htmlBytes)

# שלח ל-API
$body = @{
    FileBytes = $base64Html
    OriginalFileName = "myDocument.html"
    OutputFileName = "converted_output"
} | ConvertTo-Json

$result = Invoke-RestMethod `
    -Uri "http://localhost:5063/api/pdfconversion/convert-from-bytes" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

# שמור את ה-PDF
$pdfBytes = [Convert]::FromBase64String($result.pdfBytes)
[System.IO.File]::WriteAllBytes("output.pdf", $pdfBytes)
```

---

## 🛠️ פתרון בעיות נפוצות

### בעיה: "HTML conversion requires Microsoft Word"
**פתרון**: ודא שהקוד עודכן כראוי. בדוק ב-`PdfConversionService.cs` שורות 237-267.

### בעיה: עברית לא מוצגת נכון
**פתרון**: 
1. ודא שה-HTML כולל: `<meta charset="UTF-8">`
2. ודא שה-HTML כולל: `<html lang="he" dir="rtl">`
3. שמור את קובץ ה-HTML בקידוד UTF-8

### בעיה: CSS לא מיושם
**פתרון**:
1. שים את כל ה-CSS בתוך תג `<style>` בתוך `<head>`
2. או השתמש ב-inline CSS (בתוך התגים עצמם)
3. אל תשתמש בקישורים חיצוניים ל-CSS

### בעיה: תמונות לא מוצגות
**פתרון**:
1. השתמש ב-Base64 encoded images:
```html
<img src="data:image/png;base64,iVBORw0KG..." />
```
2. או שמור את התמונות בנתיב מוחלט

---

## 📝 טיפים חשובים

1. **קידוד UTF-8**: תמיד שמור HTML בקידוד UTF-8 (עם או בלי BOM)
2. **CSS פנימי**: העדף CSS פנימי על פני קישורים חיצוניים
3. **גופנים**: השתמש בגופנים סטנדרטיים (Arial, Tahoma, David)
4. **גודל קובץ**: שמור על גודל HTML סביר (מתחת ל-50MB)
5. **בדיקה**: תמיד פתח את ה-HTML בדפדפן לפני המרה

---

## 📚 משאבים נוספים

- **תיעוד PDFTron HTML2PDF**: [https://www.pdftron.com/documentation/](https://www.pdftron.com/documentation/)
- **קובץ הדוגמה**: `Poc_PdfTron/Tests/test-complex-hebrew.html`
- **סקריפט בדיקה**: `Poc_PdfTron/Tests/test-html-conversion.ps1`
- **Swagger UI**: `http://localhost:5063/swagger`
- **ממשק גרפי**: `http://localhost:5063/pdf-viewer.html`

---

## 🎉 סיום

כעת הפרויקט שלך תומך ב-45 פורמטים שונים, כולל **HTML מורכב**!

**יש שאלות?** בדוק את הלוגים ב-`Poc_PdfTron/Logs/` או הפעל את סקריפט הבדיקה.

**בהצלחה!** 🚀
