# ?? Test Scripts

This folder contains all test and utility scripts for the PDF Conversion API.

---

## ? NEW: Simple One-Click Test

### `testPdfTron.ps1` ? **RECOMMENDED FOR MANAGERS**
**Convert any file with ONE command - everything automatic!**
```powershell
# Just provide the filename - the script does EVERYTHING:
.\testPdfTron.ps1 -FileName "document.docx"
```

**What it does automatically:**
1. ? Validates your file exists
2. ? Starts the API server
3. ? Waits for server to be ready
4. ? Converts your file to PDF
5. ? Opens the PDF for you
6. ? Gives you options to continue or stop

**Perfect for non-technical users!** ??

### ?? Encoding Fixed!

**If you see garbled text** (Chinese/strange characters):
- The script has been updated to use plain English text only
- No special fonts or encoding needed
- Works on any console

**Optional:** If issues persist, run `.\fix-encoding.ps1` first

See `ENCODING_FIX.md` for details

---

## ?? Quick Start Scripts

### `start-viewer.ps1`
**Start the API and open the web UI**
```powershell
.\start-viewer.ps1
```
- Starts the API server
- Waits for it to be ready
- Opens browser to http://localhost:5063

### `start-both.ps1`
**Start API and Test Runner in separate windows**
```powershell
.\start-both.ps1
```
- Opens Window 1: API Server
- Opens Window 2: Interactive Test Menu
- Perfect for development workflow

---

## ?? Test Scripts

### `quick-test.ps1`
**Fast smoke test (2-3 files)**
```powershell
.\quick-test.ps1
```
Tests basic functionality with a few files. Good for quick validation.

### `test-all-types.ps1`
**Comprehensive test of all 42 file formats**
```powershell
# Create sample files first
.\test-all-types.ps1 -CreateSamples "true"

# Run all tests
.\test-all-types.ps1
```
Tests every supported file format. Takes 5-10 minutes.

### `test-api.ps1`
**Test API endpoints**
```powershell
.\test-api.ps1
```
Validates all API endpoints are working correctly.

### `test-concurrent-load.ps1`
**Performance and load testing**
```powershell
# Default: 10 parallel conversions
.\test-concurrent-load.ps1

# Custom parallelism
.\test-concurrent-load.ps1 -MaxParallel 20
```
Tests concurrent conversions with resource monitoring.

### `test-multiple-configs.ps1`
**Find optimal concurrency level**
```powershell
.\test-multiple-configs.ps1
```
Tests multiple parallelism levels (1, 5, 10, 20, 30) and compares performance.

---

## ?? Utility Scripts

### `check-api-status.ps1`
**Check if API is running**
```powershell
.\check-api-status.ps1
```

### `restart-api.ps1`
**Restart the API**
```powershell
.\restart-api.ps1
```

### `stop-api.ps1`
**Stop the API**
```powershell
.\stop-api.ps1
```

---

## ?? Analysis Scripts

### `analyze-results.ps1`
**Analyze load test results**
```powershell
.\analyze-results.ps1
```
Provides grading (A+, A, B, C) for:
- Success rate
- CPU usage
- Memory usage
- Conversion speed

### `show-load-test-results.ps1`
**Display formatted test results**
```powershell
.\show-load-test-results.ps1
```

### `show-performance-summary.ps1`
**Show performance summary**
```powershell
.\show-performance-summary.ps1
```

---

## ?? Measurement Scripts

### `measure-conversion-times.ps1`
**Measure individual file conversion times**
```powershell
.\measure-conversion-times.ps1
```

### `measure-performance.ps1`
**Detailed performance metrics**
```powershell
.\measure-performance.ps1
```

---

## ?? Diagnostic Scripts

### `check-license.ps1`
**Verify PDFTron license**
```powershell
.\check-license.ps1
```

### `show-file-size-limits.ps1`
**Display file size configuration**
```powershell
.\show-file-size-limits.ps1
```

---

## ?? Common Workflows

### First Time Setup
```powershell
# 1. Create test files
.\test-all-types.ps1 -CreateSamples "true"

# 2. Run quick test
.\quick-test.ps1
```

### Development Workflow
```powershell
# Start both API and tests
.\start-both.ps1
```

### Performance Testing
```powershell
# Find optimal settings
.\test-multiple-configs.ps1

# Or test specific parallelism
.\test-concurrent-load.ps1 -MaxParallel 15

# Analyze results
.\analyze-results.ps1
```

### CI/CD Testing
```powershell
# Run all tests
.\test-all-types.ps1

# Check API health
.\check-api-status.ps1
```

---

## ?? Notes

- All scripts automatically detect the API URL (tries multiple ports)
- Tests create files in `C:\Temp\Input` and output to `C:\Temp\Output`
- Load test results are saved as `LOAD_TEST_REPORT_[timestamp].md` in the parent directory
- Scripts are designed to work from the `Tests/` subfolder

---

## ?? Troubleshooting

### "API not found"
Make sure the API is running:
```powershell
cd ..
dotnet run
```

### "Files not found"
Create sample files:
```powershell
.\test-all-types.ps1 -CreateSamples "true"
```

### "Port already in use"
Stop existing API:
```powershell
.\stop-api.ps1
```

---

**For main documentation, see `../README.md`**
