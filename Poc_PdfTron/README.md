# 📄 PDF Conversion API - Complete Guide

A production-ready ASP.NET Core **6.0** Web API for converting **42+ file formats** to PDF using PDFTron SDK.

**🆕 NEW: Compatible with Visual Studio 2019!**  
**🆕 NEW: Merge multiple files into a single PDF!**  
**🆕 NEW: Convert byte arrays to PDF - No file system required!**  
**🆕 NEW: Full Hebrew/RTL support for HTML to PDF conversion!**

---

## 🚀 Quick Start Guide

**👉 For new users, see the simple guide in the root folder: [`../README.md`](../README.md)**

This document contains the complete technical documentation. If you're setting up for the first time, start with the quick guide above!

---

## 🌍 Hebrew & RTL Language Support

### ✨ HTML to PDF with Perfect Hebrew Support
This project includes **full UTF-8 encoding support** for HTML to PDF conversion:

- ✅ **Hebrew characters** displayed correctly (not `???`)
- ✅ **RTL (Right-to-Left)** direction preserved
- ✅ **Nikud (vowel points)** supported
- ✅ **Mixed Hebrew + English** content
- ✅ **Custom fonts** (Arial, Tahoma, David, etc.)
- ✅ **Complex CSS** with colors, styles, tables

#### 📦 Required: HTML2PDF Module
To convert HTML files, you need to install the **HTML2PDF module**:

```powershell
# Quick setup (after downloading module)
.\Tests\install-html2pdf-module.ps1 -ModulePath "C:\Downloads\html2pdf.dll"

# Or see detailed guide
# Hebrew: Docs\HTML2PDF_Installation_Guide_HE.md
# English: Docs\HTML2PDF_QUICK_INSTALL_HE.md
```

#### 🧪 Test Hebrew Conversion
```powershell
# Run diagnostic and setup
.\Tests\setup-html2pdf.ps1

# Test HTML to PDF with Hebrew
.\Tests\test-html-hebrew.ps1
```

#### 📝 Example - Hebrew HTML
```html
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: Arial; 
            direction: rtl; 
            text-align: right; 
        }
    </style>
</head>
<body>
    <h1>שלום עולם!</h1>
    <p>טקסט בעברית עם <strong>הדגשות</strong>.</p>
</body>
</html>
```

**Result**: Perfect PDF with Hebrew text, RTL layout, and all styles preserved! 🎉

**See:** `HEBREW_ENCODING_FIX.md` for technical details

---

## 🎯 Visual Studio Compatibility

This project is now **fully compatible with Visual Studio 2019** (version 16.11+).

### Supported Visual Studio Versions
- ✅ **Visual Studio 2022** (all versions)
- ✅ **Visual Studio 2019** (version 16.11 and above)

### .NET Version
- **Target Framework**: **.NET 6.0 LTS**
- **Language**: C# 10.0

📘 **For detailed VS2019 setup instructions, see:** `VS2019_COMPATIBILITY.md`

---

## 🚀 Quick Start

### Prerequisites
- **.NET 6.0 SDK** - [Download](https://dotnet.microsoft.com/download/dotnet/6.0)
- **Visual Studio 2019 (16.11+)** or **Visual Studio 2022**
- **PDFTron SDK** (included via NuGet)
- **Windows** (for native libraries)

### ⚡ First-Time Installation

**📘 For detailed setup instructions, see:** `SETUP_GUIDE.md`

#### Quick Setup (3 steps):

1. **Clone** the repository:
```powershell
git clone https://github.com/NECHAMAelad/Poc_PdfTron.git
cd Poc_PdfTron
```

2. **Restore & Build** (this downloads PDFTron native libraries):
```powershell
cd Poc_PdfTron
dotnet restore
dotnet build
```

3. **Run** the application:
```powershell
dotnet run
```

The API will start on `http://localhost:5063`

**✅ That's it!** The PDFTron native DLL files (~240MB) are automatically downloaded from NuGet during build.

**Note:** Native DLL files are NOT included in the Git repository due to their large size. They are provided by the PDFTron.NET.x64 NuGet package.

---

## 📦 Supported File Formats (43 types)

### Microsoft Office (21 formats)
- **Word**: `.doc`, `.docx`, `.docm`, `.dot`, `.dotx`, `.dotm`
- **Excel**: `.xls`, `.xlsx`, `.xlsm`, `.xlt`, `.xltx`, `.xltm`
- **PowerPoint**: `.ppt`, `.pptx`, `.pptm`, `.pot`, `.potx`, `.potm`, `.pps`, `.ppsx`, `.ppsm`

### Images (12 formats)
- **Raster**: `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.tif`, `.tiff`, `.webp`
- **Vector**: `.svg`, `.emf`, `.wmf`, `.eps`

### Text Files (6 formats)
`.txt`, `.rtf`, `.html`, `.htm`, `.xml`, `.md`

### 🆕 PDF (1 format)
`.pdf` - **Merge existing PDF files directly!**

### Other (3 formats)
`.xps`, `.oxps`, `.pcl`

---

## 🎯 Features

### Single File Conversion
Convert any supported file format to PDF

### 🆕 Byte Array to PDF Conversion (NEW!)
Convert files directly from memory (byte arrays) to PDF:
- ✅ No file system access required
- ✅ Automatic file type detection from magic bytes
- ✅ Maximum flexibility - works with any data source
- ✅ 50MB size limit for safety
- ✅ Support for all file formats
- ✅ Fast: Minimal disk I/O

**Perfect for:**
- Files already in memory
- API integrations
- Database-stored files
- Dynamic content generation

**See full documentation:** `Docs/ByteArrayConversion_Guide.md`

### 🆕 Multiple File Merging
Merge multiple files (of any supported format) into a single PDF document:
- ✅ Mix different file types (Word, Excel, images, **PDF**, etc.)
- ✅ **Merge existing PDF files directly** (no conversion needed!)
- ✅ Files are merged in the order specified
- ✅ Continues processing even if some files fail
- ✅ Detailed success/failure reporting
- ✅ Auto-generated or custom output names
- ✅ **Fast: PDF files are copied directly, not converted**

**Examples:**
- Merge PDFs only: `report1.pdf + report2.pdf + report3.pdf`
- Mix everything: `cover.pdf + document.docx + chart.xlsx + logo.jpg`

**See full merge documentation:** `Tests/MERGE_API_GUIDE.md`  
**PDF merge guide:** `PDF_MERGE_SUPPORT.md`

---

## 🎯 Usage Examples

### Web UI (Built-in)

1. Start the application: `dotnet run`
2. Open browser: `http://localhost:5063/pdf-viewer.html`
3. Upload any supported file
4. View converted PDF instantly!

### API Endpoints

#### Convert Single File
```http
POST /api/pdfconversion/upload-and-convert
Content-Type: multipart/form-data

FormData:
  - file: [your file]
  - outputFileName: "optional_name"

Response: application/pdf (binary)
```

#### 🆕 Convert HTML from URL
```http
POST /api/pdfconversion/convert-from-url
Content-Type: application/json

{
  "url": "https://www.example.com",
  "outputFileName": "optional_name"
}

Response: application/pdf (binary)
```

#### 🆕 Convert from Byte Array
```http
POST /api/pdfconversion/convert-from-bytes
Content-Type: application/json

{
  "fileBytes": [77, 90, 144, ...],
  "originalFileName": "document.docx",
  "outputFileName": "converted"
}

Response: JSON with PDF as Base64
```

#### 🆕 Convert from Byte Array and Download
```http
POST /api/pdfconversion/convert-from-bytes-and-download
Content-Type: application/json

{
  "fileBytes": [77, 90, 144, ...],
  "originalFileName": "document.docx"
}

Response: application/pdf (binary)
```

#### 🆕 Merge Multiple Files
```http
POST /api/pdfconversion/merge
Content-Type: application/json

{
  "sourceFiles": "document1.docx,image.jpg,spreadsheet.xlsx",
  "outputFileName": "combined_report"
}

Response: JSON with merge results
```

#### 🆕 Merge and Download
```http
POST /api/pdfconversion/merge-and-download
Content-Type: application/json

{
  "sourceFiles": "file1.docx,file2.pdf,file3.jpg"
}

Response: application/pdf (binary)
```

#### PowerShell Example - Single File
```powershell
# Upload and convert a Word document
$file = Get-Item "C:\path\to\document.docx"
$form = @{
    file = $file
    outputFileName = "converted_doc"
}

$response = Invoke-WebRequest ``
    -Uri "http://localhost:5063/api/pdfconversion/upload-and-convert" ``
    -Method POST ``
    -Form $form

# Save PDF
[System.IO.File]::WriteAllBytes("output.pdf", $response.Content)
```

#### 🆕 PowerShell Example - Convert URL
```powershell
# Convert HTML from URL to PDF
$body = @{
    url = "https://www.example.com"
    outputFileName = "example_page"
} | ConvertTo-Json

$response = Invoke-WebRequest ``
    -Uri "http://localhost:5063/api/pdfconversion/convert-from-url" ``
    -Method Post ``
    -Body $body ``
    -ContentType "application/json"

# Save PDF
[System.IO.File]::WriteAllBytes("output.pdf", $response.Content)
Write-Host "PDF saved: output.pdf ($($response.Content.Length) bytes)"
```

#### 🆕 PowerShell Example - Merge Files
```powershell
# Merge multiple files into one PDF
$body = @{
    sourceFiles = "document1.docx,presentation.pptx,report.xlsx"
    outputFileName = "quarterlyReport"
} | ConvertTo-Json

$response = Invoke-RestMethod ``
    -Uri "http://localhost:5063/api/pdfconversion/merge" ``
    -Method Post ``
    -Body $body ``
    -ContentType "application/json"

Write-Host "Merged PDF: $($response.outputFilePath)"
Write-Host "Files processed: $($response.filesProcessed) of $($response.totalFiles)"
```

#### C# Example
```csharp
using var client = new HttpClient();
using var content = new MultipartFormDataContent();

var fileContent = new ByteArrayContent(File.ReadAllBytes("document.docx"));
content.Add(fileContent, "file", "document.docx");

var response = await client.PostAsync(
    "http://localhost:5063/api/pdfconversion/upload-and-convert", 
    content);

var pdfBytes = await response.Content.ReadAsByteArrayAsync();
await File.WriteAllBytesAsync("output.pdf", pdfBytes);
```

#### 🆕 C# Example - Byte Array Conversion
```csharp
using var client = new HttpClient();

// Read file into byte array
byte[] fileBytes = File.ReadAllBytes("document.docx");

// Prepare request
var request = new
{
    FileBytes = fileBytes,
    OriginalFileName = "document.docx",
    OutputFileName = "converted_doc"
};

// Send request
var response = await client.PostAsJsonAsync(
    "http://localhost:5063/api/pdfconversion/convert-from-bytes",
    request);

var result = await response.Content.ReadFromJsonAsync<ByteConversionResponse>();

if (result.Success)
{
    // Convert from Base64 and save
    byte[] pdfBytes = Convert.FromBase64String(result.PdfBytes);
    await File.WriteAllBytesAsync("output.pdf", pdfBytes);
    Console.WriteLine($"PDF created: {result.PdfSizeBytes} bytes");
}
```

---

## 🧪 Testing

The project includes comprehensive test scripts in the `Tests/` folder.

### ⭐ Simplest Way - One Command! (NEW)

**Perfect for non-technical users:**

```powershell
# Just provide your filename - everything is automatic!
Tests\testPdfTron.ps1 -FileName "document.docx"
```

This does **EVERYTHING** automatically:
- ✅ Validates file
- ✅ Starts server
- ✅ Converts to PDF
- ✅ Opens the PDF
- ✅ Cleans up

**Hebrew quick guide available:** `Tests/מדריך_מהיר.md`

---

### 🆕 Test File Merging

```powershell
# Interactive merge testing
Tests\testMerge.ps1
```

This script will:
- List available files in InputFolder
- Let you select files to merge (comma-separated)
- Test both merge endpoints
- Open the resulting PDF

---

### 🆕 Test Byte Array Conversion

```powershell
# Test byte array conversion
Tests\test-byte-conversion.ps1
```

This script tests:
- ✅ Conversion from byte arrays (DOCX, images, Excel)
- ✅ Auto-detection of file types
- ✅ File size limits (50MB)
- ✅ Unsupported file type handling
- ✅ Both response types (JSON and direct download)

---

### Quick Commands

```powershell
# Quick start - open web UI
Tests\start-viewer.ps1

# Start API + interactive test menu
Tests\start-both.ps1

# Quick smoke test
Tests\quick-test.ps1

# Test merge functionality
Tests\testMerge.ps1
```



### Key Settings
- **InputDirectory**: Default location for input files
- **OutputDirectory**: Where converted PDFs are saved
- **MaxFileSizeMB**: Maximum file size limit (default: 50MB)
- **LicenseKey**: PDFTron license key ([Get a demo key](https://www.pdftron.com/pws/get-key))

---

## 🏗️ Project Structure

```
Poc_PdfTron/
├── Controllers/
│   └── PdfConversionController.cs    # API endpoints
├── Services/
│   ├── IPdfConversionService.cs      # Service interface
│   └── PdfConversionService.cs       # Conversion logic
├── Models/
│   ├── ConversionOptions.cs          # Configuration model
│   ├── ConversionRequest.cs          # Request model
│   └── ConversionResponse.cs         # Response model
├── Middleware/
│   └── GlobalExceptionMiddleware.cs  # Error handling
├── Tests/                            # PowerShell test scripts
│   ├── test-all-types.ps1
│   ├── quick-test.ps1
│   ├── test-concurrent-load.ps1
│   └── ...
├── wwwroot/
│   ├── index.html                    # Landing page
│   └── pdf-viewer.html               # Upload & view UI
├── Program.cs                        # Application entry point
├── appsettings.json                  # Configuration
└── Poc_PdfTron.csproj               # Project file
```

---

## 📝 Logging System

This application uses **Serilog** for comprehensive logging:

### Features
- ✅ **Console Logging**: Real-time logs during development
- ✅ **File Logging**: Persistent logs saved to `Logs/` directory
- ✅ **Daily Rotation**: New log file created automatically each day
- ✅ **Auto-Cleanup**: Keeps last 31 days of logs
- ✅ **Structured Logging**: Easy to parse and analyze
- ✅ **Size Limits**: Automatic file splitting at 10MB

### Log Locations

**Log Files**: `Logs/log-yyyyMMdd.txt`  
Example: `Logs/log-20240315.txt`

**What's Logged:**
- 🔍 All API requests and responses
- ⚠️ Validation errors and warnings
- ❌ Exceptions and error details
- ✅ Successful conversions with timing
- 📊 Performance metrics
- 🔧 PDFTron initialization status

### View Logs in Real-Time

```powershell
# Watch today's logs
Get-Content -Path "Logs\log-$(Get-Date -Format 'yyyyMMdd').txt" -Wait -Tail 50

# Search for errors
Select-String -Path "Logs\*.txt" -Pattern "error" -CaseSensitive:$false
```

📘 **For complete logging documentation, see:** `Logs/README.md`

---

## 🔌 API Reference

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/pdfconversion/upload-and-convert` | Upload file and get PDF |
| POST | `/api/pdfconversion/convert-and-download` | Convert by file path |
| **POST** | **`/api/pdfconversion/convert-from-url`** | **🆕 Convert HTML from URL to PDF** |
| **POST** | **`/api/pdfconversion/convert-from-bytes`** | **🆕 Convert byte array (returns JSON)** |
| **POST** | **`/api/pdfconversion/convert-from-bytes-and-download`** | **🆕 Convert byte array (returns PDF)** |
| **POST** | **`/api/pdfconversion/merge`** | **🆕 Merge multiple files (returns info)** |
| **POST** | **`/api/pdfconversion/merge-and-download`** | **🆕 Merge multiple files (returns PDF)** |
| GET | `/api/pdfconversion/validate` | Validate file |
| GET | `/health` | Health check |
| GET | `/swagger` | API documentation |


## 📊 Performance

Based on load testing (see `Tests/` folder for scripts):

- **Speed**: ~0.5 files/second with 10 parallel conversions
- **Success Rate**: 100% (with proper configuration)
- **Memory Usage**: Efficient, no leaks detected
- **CPU Usage**: 5-7% average (low overhead)
- **Max File Size**: Configurable, default 50MB
- **Optimal Concurrency**: 10-20 parallel conversions

### For Production
1. Obtain a production PDFTron license
2. Implement authentication (API key or JWT)
3. Add rate limiting
4. Configure HTTPS
5. Implement input sanitization
6. Set up proper logging and monitoring

