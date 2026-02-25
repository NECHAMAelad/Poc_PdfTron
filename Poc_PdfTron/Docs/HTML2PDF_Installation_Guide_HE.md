# 📦 מדריך התקנת מודול HTML2PDF - תמיכה מלאה בעברית

## 🎯 סקירה
מדריך זה מסביר כיצד להתקין את מודול HTML2PDF של PDFTron כדי לאפשר המרת קבצי HTML (עם תוכן עברי) ל-PDF.

---

## ⚠️ בעיה נוכחית
הקוד מנסה להשתמש ב-`HTML2PDF` אבל המודול חסר:
```
Failed to find html2pdf.dll or html2pdf_chromium.dll modules
```

**ללא המודול**: אי אפשר להמיר קבצי HTML ל-PDF.  
**עם המודול + הקוד המעודכן**: תמיכה מלאה בעברית, RTL, UTF-8, גופנים מיוחדים.

---

## 📥 שלב 1: הורדת מודול HTML2PDF

### דרך א': הורדה מאתר PDFTron (מומלץ)

1. **פתחי דפדפן וגשי לדף ההורדות**:
   ```
   https://www.pdftron.com/download-center/windows/
   ```
   או חפשי: "PDFTron HTML2PDF module download"

2. **גללי למטה למודולים (Modules)**:
   - חפשי את **"HTML2PDF Conversion Module"**
   - בחרי **Windows x64** (תואם ל-.NET 6)
   - לחצי **Download**

3. **מה יהיה בקובץ שהורדת?**
   קובץ ZIP שמכיל:
   ```
   html2pdf.dll              (הקובץ העיקרי)
   html2pdf_chromium.dll     (אופציונלי - גרסת Chromium)
   + קבצים נוספים (תלויים)
   ```

### דרך ב': בדיקה אם המודול כבר קיים במערכת

הריצי את הפקודה הבאה ב-PowerShell:
```powershell
Get-ChildItem -Path "C:\Program Files" -Recurse -Filter "html2pdf.dll" -ErrorAction SilentlyContinue | Select-Object FullName
```

אם המודול נמצא, העתיקי אותו לפרויקט שלך.

---

## 📂 שלב 2: העתקת הקבצים לפרויקט

לאחר שהורדת את המודול:

### 1. חלצי את הקבצים מ-ZIP
חלצי את כל התוכן לתיקייה זמנית

### 2. העתיקי את הקבצים לפרויקט

**יעד מומלץ**: לתיקיית `native\win-x64\` (ליד PDFNetC.dll)

```powershell
# פתחי PowerShell והריצי:
cd C:\Users\NechamaO\Documents\finals\Poc_PdfTron\Poc_PdfTron

# צרי את התיקייה אם היא לא קיימת
New-Item -ItemType Directory -Path "native\win-x64" -Force

# העתיקי את הקבצים מתיקיית ההורדה
# החליפי <PATH_TO_EXTRACTED_ZIP> בנתיב בו חילצת את הקבצים
Copy-Item "<PATH_TO_EXTRACTED_ZIP>\html2pdf.dll" -Destination "native\win-x64\"
Copy-Item "<PATH_TO_EXTRACTED_ZIP>\html2pdf_chromium.dll" -Destination "native\win-x64\" -ErrorAction SilentlyContinue

# העתיקי גם קבצי תמיכה נוספים (אם יש)
Copy-Item "<PATH_TO_EXTRACTED_ZIP>\*.dll" -Destination "native\win-x64\" -ErrorAction SilentlyContinue
```

### 3. אימות - בדקי שהקבצים הועתקו:
```powershell
Get-ChildItem "native\win-x64\*html2pdf*.dll"
```

אמורים להופיע:
```
✅ native\win-x64\html2pdf.dll
✅ native\win-x64\html2pdf_chromium.dll (אופציונלי)
```

---

## 🔨 שלב 3: Build הפרויקט

לאחר העתקת הקבצים:

```powershell
cd C:\Users\NechamaO\Documents\finals\Poc_PdfTron\Poc_PdfTron

# נקה ובנה מחדש
dotnet clean
dotnet build

# בדוק שהקבצים הועתקו ל-bin
Get-ChildItem "bin\Debug\net6.0\*html2pdf*.dll"
```

אמור להופיע:
```
✅ bin\Debug\net6.0\html2pdf.dll
✅ bin\Debug\net6.0\native\win-x64\html2pdf.dll
```

---

## ✅ שלב 4: בדיקה - המרת HTML עם עברית

### צור קובץ בדיקה עברי פשוט:

צרי קובץ `C:\Temp\Input\test-hebrew.html`:
```html
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>בדיקת עברית</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            direction: rtl;
            text-align: right;
            padding: 20px;
        }
        h1 { color: blue; }
        p { font-size: 16px; }
    </style>
</head>
<body>
    <h1>שלום עולם! 🌍</h1>
    <p>זהו טקסט בעברית עם <strong>מילים מודגשות</strong> ו<em>נטויות</em>.</p>
    <p>תמיכה מלאה ב-UTF-8 ובכיוון RTL.</p>
</body>
</html>
```

### הרץ המרה:
```powershell
# הפעל את השרת
cd C:\Users\NechamaO\Documents\finals\Poc_PdfTron\Poc_PdfTron
dotnet run

# בחלון אחר - בדוק המרה
$body = @{
    SourceFilePath = "C:\Temp\Input\test-hebrew.html"
    OutputFileName = "test-hebrew-output"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5063/api/pdfconversion/convert" `
    -Method POST `
    -Body $body `
    -ContentType "application/json; charset=utf-8"
```

### בדוק את ה-PDF:
```powershell
# פתח את ה-PDF שנוצר
Start-Process "C:\Temp\Output\test-hebrew-output.pdf"
```

**תוצאה צפויה**:
- ✅ העברית מוצגת כהלכה (לא סימני שאלה)
- ✅ כיוון RTL נכון
- ✅ גופנים מוצגים נכון
- ✅ עיצוב CSS נשמר

---

## 🔍 פתרון בעיות

### בעיה 1: "html2pdf.dll not found"
**פתרון**:
```powershell
# ודא שהקובץ קיים
Test-Path "native\win-x64\html2pdf.dll"

# אם FALSE - הקובץ לא קיים, העתק אותו מחדש
# אם TRUE - הרץ dotnet build מחדש
```

### בעיה 2: "העברית עדיין מוצגת כסימני שאלה"
**סיבות אפשריות**:
1. ✅ **קובץ ה-HTML לא שמור ב-UTF-8** - שמרי מחדש עם UTF-8 encoding
2. ✅ **חסר `<meta charset="UTF-8">`** - הוסיפי לתוך `<head>`
3. ✅ **הגופן לא תומך בעברית** - השתמשי ב-Arial או Tahoma

**בדיקה**:
```powershell
# בדוק קידוד של קובץ HTML
Get-Content "C:\Temp\Input\test-hebrew.html" -Raw | Format-Hex | Select-Object -First 5
```
אמור להתחיל ב-`EF BB BF` (UTF-8 BOM) או תווים עבריים תקינים.

### בעיה 3: "הכיוון לא נכון (LTR במקום RTL)"
**פתרון**: ודאי שב-HTML יש:
```html
<html lang="he" dir="rtl">
```
וגם ב-CSS:
```css
body {
    direction: rtl;
    text-align: right;
}
```

### בעיה 4: "המודול לא נטען אפילו אחרי ההעתקה"
**פתרון**: נסי להגדיר את הנתיב ידנית בקוד:
```csharp
// הוסיפי לפני html2Pdf.InsertFromHtmlString():
pdftron.PDF.HTML2PDF.SetModulePath("C:\\full\\path\\to\\html2pdf.dll");
```

---

## 🎨 שלב 5: טיפים להמרת HTML מורכב עם עברית

### 1. תבנית HTML מומלצת לעברית:
```html
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>מסמך בעברית</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: Arial, 'David', 'Narkisim', Tahoma, sans-serif;
            direction: rtl;
            text-align: right;
            font-size: 14px;
            line-height: 1.6;
            color: #333;
        }
        .ltr {
            direction: ltr;
            text-align: left;
        }
    </style>
</head>
<body>
    <h1>כותרת ראשית</h1>
    <p>פסקה בעברית</p>
    <p class="ltr">English paragraph</p>
</body>
</html>
```

### 2. גופנים מומלצים לעברית:
```css
font-family: Arial, 'David', 'Narkisim', 'Miriam', Tahoma, sans-serif;
```
- **Arial** - הכי אמין, תמיד עובד
- **Tahoma** - חלופה טובה
- **David/Narkisim** - גופנים עבריים ספציפיים

### 3. טיפול בתוכן מעורב (עברית + אנגלית):
```html
<p class="rtl">
    טקסט בעברית <span class="ltr">English text</span> המשך בעברית
</p>
```

### 4. ודאי שה-CSS נמצא בתוך ה-HTML:
- ✅ **כן**: `<style>` בתוך `<head>`
- ❌ **לא**: קובץ CSS חיצוני (`<link>`) - עלול לא להיטען

---

## 🧪 שלב 6: סקריפט בדיקה מהיר

צרי קובץ `test-html-hebrew.ps1`:
```powershell
Write-Host "🧪 Testing HTML to PDF with Hebrew..." -ForegroundColor Cyan

# יצירת HTML עם עברית
$htmlContent = @"
<!DOCTYPE html>
<html lang='he' dir='rtl'>
<head>
    <meta charset='UTF-8'>
    <title>בדיקה</title>
    <style>
        body { font-family: Arial; direction: rtl; text-align: right; padding: 20px; }
        h1 { color: #2c3e50; font-size: 24px; }
        p { font-size: 16px; line-height: 1.6; }
        .highlight { background: yellow; font-weight: bold; }
    </style>
</head>
<body>
    <h1>🎉 בדיקת המרה לעברית</h1>
    <p>זהו טקסט בעברית עם <span class='highlight'>הדגשות</span> ועיצוב.</p>
    <p>אותיות: א ב ג ד ה ו ז ח ט י כ ל מ נ ס ע פ צ ק ר ש ת</p>
    <p>ניקוד: אָ בְּ גִ דֵ הֶ וֹ</p>
    <p>מספרים: 1234567890</p>
</body>
</html>
"@

# שמירה עם UTF-8
$htmlPath = "C:\Temp\Input\test-hebrew.html"
[System.IO.File]::WriteAllText($htmlPath, $htmlContent, [System.Text.Encoding]::UTF8)

Write-Host "✅ Created HTML file: $htmlPath" -ForegroundColor Green

# המרה
$body = @{
    SourceFilePath = $htmlPath
    OutputFileName = "hebrew-test"
} | ConvertTo-Json -Depth 10

Write-Host "🔄 Converting to PDF..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5063/api/pdfconversion/convert" `
        -Method POST `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
        -ContentType "application/json; charset=utf-8"

    if ($response.success) {
        Write-Host "✅ SUCCESS! PDF created: $($response.outputFilePath)" -ForegroundColor Green
        Write-Host "📄 Opening PDF..." -ForegroundColor Cyan
        Start-Process $response.outputFilePath
    } else {
        Write-Host "❌ FAILED: $($response.errorMessage)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
```

---

## 🎓 הסבר על השיפורים בקוד

### שיפור 1: קידוד UTF-8 מפורש
```csharp
// קודם (BAD - גורם לסימני שאלה):
html2Pdf.InsertFromURL(sourceFilePath);

// אחרי (GOOD - תמיכה מלאה ב-UTF-8):
string htmlContent;
using (var reader = new StreamReader(sourceFilePath, System.Text.Encoding.UTF8))
{
    htmlContent = reader.ReadToEnd();
}
html2Pdf.InsertFromHtmlString(htmlContent);
```

**למה זה עוזר?**
- `InsertFromURL()` - PDFTron מנסה לנחש את הקידוד → כישלון בעברית
- `InsertFromHtmlString()` - מקבל string שכבר ב-UTF-8 → מושלם לעברית

### שיפור 2: הגדרות מפורשות
```csharp
var settings = new HTML2PDF.WebPageSettings();
settings.SetDefaultEncoding("UTF-8");       // ⭐ קריטי לעברית
settings.SetJavaScriptOn(true);            // אם יש JS בדף
settings.SetLoadImages(true);              // טעינת תמונות
settings.SetPrintBackground(true);         // רקעים ב-CSS
settings.SetDPI(96);                       // איכות טובה
```

### שיפור 3: גודל עמוד ושוליים
```csharp
html2Pdf.SetPaperSize(PrinterMode.PaperSize.e_11x17);  // A4
html2Pdf.SetMargins("0.5in", "0.5in", "0.5in", "0.5in");
```

---

## 📝 דוגמת HTML מורכבת עם עברית

הקובץ `test-complex-hebrew.html` שלך כבר מצוין! הוא כולל:
- ✅ `<meta charset="UTF-8">` ✅ `lang="he" dir="rtl"`
- ✅ גופנים מרובים
- ✅ צבעים ועיצוב CSS
- ✅ טבלאות
- ✅ שילוב עברית + אנגלית

אחרי התקנת המודול והקוד המעודכן, הוא אמור להמיר **בצורה מושלמת**.

---

## ⚡ בדיקה מהירה - האם המודול עובד?

```powershell
# הפעל את השרת
cd C:\Users\NechamaO\Documents\finals\Poc_PdfTron\Poc_PdfTron
dotnet run

# בחלון נפרד - המר את הקובץ המורכב שלך
$body = @{
    SourceFilePath = "C:\Temp\Input\test-complex-hebrew.html"
    OutputFileName = "hebrew-complex-test"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5063/api/pdfconversion/convert" `
    -Method POST `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
    -ContentType "application/json; charset=utf-8"

# פתח את התוצאה
Start-Process "C:\Temp\Output\hebrew-complex-test.pdf"
```

---

## 📊 השוואה: לפני ואחרי

| פיצ'ר | ❌ לפני | ✅ אחרי |
|-------|---------|---------|
| תווים עבריים | `???` | `שלום` |
| כיוון RTL | שמאל לימין | ימין לשמאל ✓ |
| CSS מורכב | לא נתמך | נתמך מלא |
| גופנים | ברירת מחדל | Arial/Tahoma/Custom |
| טבלאות | ✓ | ✓ |
| תמונות | ✓ | ✓ |
| קידוד | ASCII/Default | **UTF-8** ⭐ |

---

## 🆘 עזרה נוספת

### אם המודול לא זמין להורדה:
אם אין לך גישה למודול, אפשר להשתמש בספרייה חלופית:

**חלופה 1**: להשתמש ב-Playwright/Puppeteer להדפסת HTML ל-PDF
**חלופה 2**: להשתמש ב-SelectPdf או IronPDF (בתשלום)
**חלופה 3**: להמיר HTML ל-DOCX ואז ל-PDF (שומר עברית אבל עיצוב פחות מדויק)

### צור קשר עם PDFTron:
אם אתה לקוח משלם:
- 📧 support@pdftron.com
- 🌐 https://www.pdftron.com/contact

---

## ✨ סיכום

1. ✅ הורדת `html2pdf.dll` מאתר PDFTron
2. ✅ העתקה ל-`native\win-x64\`
3. ✅ `dotnet build`
4. ✅ הקוד עודכן לתמיכה ב-UTF-8
5. ✅ בדיקה עם קובץ עברי

**התוצאה**: המרת HTML ל-PDF עם תמיכה מלאה בעברית! 🎉

---

📅 **עודכן**: 21/02/2026  
👨‍💻 **גרסה**: 2.0 - תמיכה מלאה ב-UTF-8 ועברית
