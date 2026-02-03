# Merge Multiple Files to PDF - Documentation

## Overview
אפשרות חדשה לאיחוד מספר קבצים לקובץ PDF אחד. המערכת ממירה כל קובץ ל-PDF ולאחר מכן מאחדת את כל ה-PDFs לקובץ אחד לפי הסדר שצוין.

## API Endpoints

### 1. Merge Files (מחזיר מידע)
**Endpoint:** `POST /api/pdfconversion/merge`

**תיאור:** מאחד מספר קבצים ל-PDF אחד ומחזיר מידע על התוצאה

**Request Body:**
```json
{
  "sourceFiles": "document1.docx,presentation.pptx,spreadsheet.xlsx",
  "outputFileName": "myMergedFile"
}
```

**Parameters:**
- `sourceFiles` (required): רשימה של שמות קבצים מופרדת בפסיקים. הקבצים חייבים להיות בתיקיית `InputFolder`
- `outputFileName` (optional): שם לקובץ הפלט (ללא סיומת). אם לא מסופק, יהיה `mergePDF_YYYYMMDD_HHmmss`

**Response (Success):**
```json
{
  "success": true,
  "outputFilePath": "C:\\Output\\mergePDF_20250122_143052.pdf",
  "outputFileName": "mergePDF_20250122_143052.pdf",
  "filesProcessed": 3,
  "totalFiles": 3,
  "successfulFiles": [
    "document1.docx",
    "presentation.pptx",
    "spreadsheet.xlsx"
  ],
  "failedFiles": [],
  "duration": "00:00:05.1234567"
}
```

**Response (Partial Success):**
```json
{
  "success": true,
  "outputFilePath": "C:\\Output\\mergePDF_20250122_143052.pdf",
  "outputFileName": "mergePDF_20250122_143052.pdf",
  "filesProcessed": 2,
  "totalFiles": 3,
  "successfulFiles": [
    "document1.docx",
    "spreadsheet.xlsx"
  ],
  "failedFiles": [
    {
      "fileName": "presentation.pptx",
      "errorMessage": "File not found"
    }
  ],
  "duration": "00:00:03.5678901"
}
```

**PowerShell Example:**
```powershell
$body = @{
    sourceFiles = "document1.docx,presentation.pptx,report.xlsx"
    outputFileName = "quarterlyReport"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:5000/api/pdfconversion/merge" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

Write-Host "Merge completed!"
Write-Host "Output: $($response.outputFilePath)"
Write-Host "Files processed: $($response.filesProcessed) of $($response.totalFiles)"
```

---

### 2. Merge and Download (מחזיר את הקובץ ישירות)
**Endpoint:** `POST /api/pdfconversion/merge-and-download`

**תיאור:** מאחד מספר קבצים ל-PDF אחד ומחזיר את קובץ ה-PDF ישירות להורדה

**Request Body:**
```json
{
  "sourceFiles": "document1.docx,presentation.pptx,spreadsheet.xlsx",
  "outputFileName": "myMergedFile"
}
```

**Parameters:**
- זהה ל-endpoint הקודם

**Response:**
- קובץ PDF בינארי (`application/pdf`)
- Content-Disposition header עם שם הקובץ

**PowerShell Example (Download File):**
```powershell
$body = @{
    sourceFiles = "document1.docx,presentation.pptx,report.xlsx"
    outputFileName = "quarterlyReport"
} | ConvertTo-Json

$outputPath = "C:\Downloads\merged.pdf"

Invoke-RestMethod -Uri "http://localhost:5000/api/pdfconversion/merge-and-download" `
    -Method Post `
    -Body $body `
    -ContentType "application/json" `
    -OutFile $outputPath

Write-Host "PDF downloaded to: $outputPath"
```

---

## Features

### ✅ תכונות עיקריות
1. **איחוד מספר קבצים** - תמיכה בכל סוגי הקבצים הנתמכים (Word, Excel, PowerPoint, תמונות, טקסט וכו')
2. **שמירת סדר** - הקבצים מאוחדים לפי הסדר שצוין ברשימה
3. **Partial Success** - אם חלק מהקבצים נכשלים, התהליך ממשיך עם השאר
4. **שם קובץ חכם** - שם אוטומטי עם תאריך ושעה או שם מותאם אישית
5. **Logging מלא** - כל שלב מתועד ב-logs
6. **Clean-up אוטומטי** - קבצי temp נמחקים אוטומטית

### ⚠️ התנהגות במקרה של כשלון
- אם קובץ אחד נכשל - התהליך ממשיך עם השאר
- אם **כל** הקבצים נכשלו - מוחזרת שגיאה 400
- כל קובץ שנכשל מתועד ב-`failedFiles` array

---

## Complete Example

### סקריפט מלא לבדיקה:

```powershell
# הגדרות
$baseUrl = "http://localhost:5000/api/pdfconversion"
$inputFolder = "C:\Temp\Input"
$outputFolder = "C:\Downloads"

# צור קבצים לדוגמה (אם לא קיימים)
# ... העתק קבצים ל-InputFolder ...

# דוגמה 1: Merge עם מידע
Write-Host "`n=== Example 1: Merge Files ===" -ForegroundColor Cyan

$mergeRequest = @{
    sourceFiles = "document1.docx,image.jpg,spreadsheet.xlsx"
    outputFileName = "combined_report"
} | ConvertTo-Json

$result = Invoke-RestMethod -Uri "$baseUrl/merge" `
    -Method Post `
    -Body $mergeRequest `
    -ContentType "application/json"

Write-Host "`nMerge Result:" -ForegroundColor Green
Write-Host "  Success: $($result.success)"
Write-Host "  Output: $($result.outputFileName)"
Write-Host "  Files Processed: $($result.filesProcessed)/$($result.totalFiles)"
Write-Host "  Duration: $($result.duration)"

if ($result.failedFiles.Count -gt 0) {
    Write-Host "`nFailed Files:" -ForegroundColor Yellow
    $result.failedFiles | ForEach-Object {
        Write-Host "  - $($_.fileName): $($_.errorMessage)"
    }
}

# דוגמה 2: Merge והורדה ישירה
Write-Host "`n=== Example 2: Merge and Download ===" -ForegroundColor Cyan

$downloadRequest = @{
    sourceFiles = "file1.docx,file2.txt,file3.png"
} | ConvertTo-Json

$downloadPath = Join-Path $outputFolder "merged_$(Get-Date -Format 'yyyyMMdd_HHmmss').pdf"

Invoke-RestMethod -Uri "$baseUrl/merge-and-download" `
    -Method Post `
    -Body $downloadRequest `
    -ContentType "application/json" `
    -OutFile $downloadPath

Write-Host "PDF downloaded to: $downloadPath" -ForegroundColor Green

# פתח את הקובץ
Start-Process $downloadPath
```

---

## Error Handling

### שגיאות נפוצות:

**400 Bad Request - No files provided**
```json
{
  "status": 400,
  "title": "No files provided",
  "detail": "Please provide at least one file name in the SourceFiles field"
}
```

**400 Bad Request - Merge failed**
```json
{
  "status": 400,
  "title": "Merge failed",
  "detail": "No files were successfully converted to PDF"
}
```

**500 Internal Server Error**
```json
{
  "status": 500,
  "title": "Internal server error",
  "detail": "An unexpected error occurred during file merge. Please try again."
}
```

---

## Notes

### דברים חשובים לזכור:
1. כל הקבצים חייבים להיות בתיקיית `InputFolder` (מוגדר ב-appsettings.json)
2. הקובץ המאוחד נשמר בתיקיית `OutputFolder`
3. קבצים זהים לא יוחלפו - יתווסף timestamp לשם הקובץ
4. סדר הקבצים ברשימה קובע את סדרם ב-PDF המאוחד
5. המערכת תומכת בכל סוגי הקבצים הנתמכים בהמרה בודדת

### גבולות ומגבלות:
- גודל קובץ מקסימלי: כהגדרת `MaxFileSizeMB` ב-configuration
- סוגי קבצים נתמכים: כהגדרת `AllowedExtensions` ב-configuration
- אין הגבלה על מספר הקבצים לאיחוד (מעבר למגבלות המערכת)

---

# 📖 PDF Merge API - Complete Guide

## Overview

The PDF Merge API allows you to merge multiple files of **any supported format** into a single PDF document. This includes:
- Microsoft Office documents (Word, Excel, PowerPoint)
- Images (JPG, PNG, etc.)
- **🆕 Existing PDF files**
- Text files
- And 43 more formats!

### 🚀 Key Features

- ✅ **43 supported file formats** (including PDF!)
- ✅ **Mix any file types** - Word + Excel + Images + PDFs
- ✅ **Smart processing** - PDFs are copied directly (3x faster!)
- ✅ **Partial success** - Continues even if some files fail
- ✅ **Order preservation** - Files merged in specified order
- ✅ **Automatic page sizing** - All pages normalized to A4
- ✅ **Detailed reporting** - Success/failure for each file

---

## 🎯 Common Use Cases

### 1. Merge PDF Documents Only
```json
{
  "sourceFiles": "invoice1.pdf,invoice2.pdf,invoice3.pdf",
  "outputFileName": "combined_invoices"
}
```
**Result:** All PDFs combined into one - **Fast!** (No conversion needed)

### 2. Create Comprehensive Report
```json
{
  "sourceFiles": "cover.pdf,summary.docx,data.xlsx,chart.jpg,appendix.pdf",
  "outputFileName": "quarterly_report"
}
```
**Result:** Professional report with title page, content, data, charts, and appendices

### 3. Merge Invoices with Summary
```json
{
  "sourceFiles": "summary.docx,jan.pdf,feb.pdf,mar.pdf",
  "outputFileName": "q1_invoices"
}
```

### 4. Mixed Document Types
```json
{
  "sourceFiles": "letter.docx,contract.pdf,pricing.xlsx,signature.jpg",
  "outputFileName": "complete_proposal"
}
