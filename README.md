# 📄 PDF Conversion API

ASP.NET Core 6.0 Web API for converting **42+ file formats** to PDF using PDFTron SDK.

**✨ Features:**
- Convert documents (Word, Excel, PowerPoint)
- Convert images (JPG, PNG, SVG, etc.)
- Convert HTML to PDF with full Hebrew/RTL support
- Merge multiple files into single PDF
- Convert from byte arrays (no file system needed)

---

## ⚡ Quick Start (3 Steps)

### 1️⃣ Clone Repository
```powershell
git clone https://github.com/NECHAMAelad/Poc_PdfTron.git
cd Poc_PdfTron\Poc_PdfTron
```

### 2️⃣ Restore & Build
```powershell
dotnet restore
dotnet build
```
**Note:** This downloads PDFTron libraries (~240MB) automatically from NuGet.

### 3️⃣ Run
```powershell
dotnet run
```

### ✅ Open Browser
- **Web UI**: http://localhost:5063/pdf-viewer.html
- **API Docs**: http://localhost:5063/swagger

---

## 📋 Prerequisites

- **.NET 6.0 SDK** - [Download](https://dotnet.microsoft.com/download/dotnet/6.0)
- **Visual Studio 2019 (16.11+)** or **VS 2022**
- **Windows OS** (for native libraries)

---

## 🔧 Configuration

Edit `appsettings.json`:
```json
{
  "PdfConversion": {
    "InputDirectory": "C:/Temp/Input",
    "OutputDirectory": "C:/Temp/Output",
    "MaxFileSizeMB": 50,
    "LicenseKey": "demo:1234567890"
  }
}
```

---

## 🔍 Troubleshooting

### Problem: "PDFNetC.dll not found"
```powershell
dotnet clean
dotnet restore --force
dotnet build
```

### Problem: "Unable to load DLL 'PDFNetC'"
Install Visual C++ Redistributable:
https://aka.ms/vs/17/release/vc_redist.x64.exe

### Problem: Build fails
```powershell
dotnet nuget locals all --clear
dotnet restore --force
```

---

## 📚 Full Documentation

See `Poc_PdfTron/README.md` for:
- Complete API reference
- All supported file formats
- PowerShell test scripts
- Hebrew/RTL support details
- Advanced features

---

## 🧪 Quick Test

```powershell
# Run quick test
.\Tests\quick-test.ps1

# Or test with specific file
.\Tests\testPdfTron.ps1 -FileName "document.docx"
```

---

## ⚠️ Important Notes

### Native DLL Files
The following files (~240MB total) are **NOT included in Git**:
- `Poc_PdfTron/native/win-x64/PDFNetC.dll`
- `Poc_PdfTron/native/win-x64/html2pdf.dll`
- `Poc_PdfTron/native/win-x64/html2pdf_chromium.dll`

**Why?** They're too large for Git and are provided by the PDFTron.NET.x64 NuGet package.

**Solution:** Just run `dotnet restore && dotnet build` - they'll be downloaded automatically! ✨

---

## 📞 Support

- **Full Documentation**: `Poc_PdfTron/README.md`
- **Issues**: Report on GitHub
- **PDFTron Support**: https://www.pdftron.com/support

---

## 🎉 That's It!

Your API is ready. Happy coding! 🚀

**Quick Commands:**
```powershell
dotnet run                    # Start server
.\Tests\quick-test.ps1        # Test conversion
Get-Content Logs\log-*.txt    # View logs
```
