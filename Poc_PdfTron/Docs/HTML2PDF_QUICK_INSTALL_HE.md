# 🚀 התקנה מהירה - HTML2PDF עם תמיכה בעברית

## בעיה: העברית הופכת לסימני שאלה (???)

### פתרון במהירות:

---

## 📥 שלב 1: הורד את מודול HTML2PDF

### אופציה א' - הורדה ידנית
1. גש ל: **https://www.pdftron.com/download-center/windows/**
2. חפש: **"HTML2PDF Conversion Module"** (Windows x64)
3. הורד את הקובץ

### אופציה ב' - אם יש לך את הקובץ במקום אחר
```powershell
# חפש במחשב
Get-ChildItem -Path "C:\" -Recurse -Filter "html2pdf.dll" -ErrorAction SilentlyContinue | Select-Object FullName
```

---

## 📂 שלב 2: העתק את הקבצים

```powershell
# פתח PowerShell והריץ:
cd C:\Users\NechamaO\Documents\finals\Poc_PdfTron\Poc_PdfTron

# צור תיקייה
New-Item -ItemType Directory -Path "native\win-x64" -Force

# העתק את html2pdf.dll (שנוי את הנתיב למיקום שבו הורדת)
Copy-Item "C:\Downloads\html2pdf.dll" -Destination "native\win-x64\"

# בדוק שהועתק
Get-ChildItem "native\win-x64\html2pdf.dll"
```

---

## 🔨 שלב 3: Build

```powershell
dotnet clean
dotnet build
```

---

## ✅ שלב 4: בדיקה

```powershell
# הפעל את השרת
dotnet run

# בחלון נפרד - הרץ בדיקה
cd Tests
.\test-html-hebrew.ps1
```

---

## 🎯 מה קורה מאחורי הקלעים?

הקוד עודכן ל:

### 1. קריאת HTML עם UTF-8:
```csharp
using (var reader = new StreamReader(sourceFilePath, Encoding.UTF8))
{
    htmlContent = reader.ReadToEnd();
}
```

### 2. הגדרת קידוד מפורש:
```csharp
var settings = new HTML2PDF.WebPageSettings();
settings.SetDefaultEncoding("UTF-8");  // ⭐ קריטי!
```

### 3. שימוש ב-InsertFromHtmlString:
```csharp
html2Pdf.InsertFromHtmlString(htmlContent);  // במקום InsertFromURL
```

---

## 📋 צ'קליסט - האם הכל תקין?

- [ ] הורדתי את `html2pdf.dll`
- [ ] העתקתי ל-`native\win-x64\`
- [ ] הרצתי `dotnet build`
- [ ] הקובץ קיים ב-`bin\Debug\net6.0\html2pdf.dll`
- [ ] השרת רץ (`dotnet run`)
- [ ] הרצתי את סקריפט הבדיקה
- [ ] ה-PDF מציג עברית נכון (לא ???)

---

## 🆘 אם זה לא עובד

### הרץ את סקריפט האבחון:
```powershell
cd Tests
.\setup-html2pdf.ps1
```

הסקריפט יבדוק:
- ✓ האם המודול קיים
- ✓ האם הוא הועתק ל-bin
- ✓ האם השרת רץ
- ✓ יתן הוראות מדויקות

---

## 📖 למידע מפורט

ראה: `Docs\HTML2PDF_Installation_Guide_HE.md`

---

**זהו זה! עם המודול והקוד המעודכן, העברית תוצג מושלם ב-PDF!** ✨
