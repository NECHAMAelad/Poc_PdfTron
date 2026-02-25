using Microsoft.Extensions.Options;
using pdftron.PDF;
using pdftron.SDF;
using Poc_PdfTron.Models;
using System.Diagnostics;

namespace Poc_PdfTron.Services;

/// <summary>
/// Service for converting files to PDF using PDFTron
/// </summary>
public class PdfConversionService : IPdfConversionService
{
    private readonly PdfConversionOptions _options;
    private readonly ILogger<PdfConversionService> _logger;
    private static bool _isPdfTronInitialized = false;
    private static readonly object _initLock = new object();

    // Office file extensions that require OfficeToPDF conversion
    private static readonly HashSet<string> OfficeExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".doc", ".docx", ".docm", ".dot", ".dotx", ".dotm",
        ".xls", ".xlsx", ".xlsm", ".xlt", ".xltx", ".xltm",
        ".ppt", ".pptx", ".pptm", ".pot", ".potx", ".potm", ".pps", ".ppsx", ".ppsm"
    };

    // Image file extensions (includes standard and vector graphics)
    private static readonly HashSet<string> ImageExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".bmp", ".gif", ".tif", ".tiff", ".webp",
        ".svg", ".emf", ".wmf", ".eps"
    };

    // HTML/Web file extensions that need special handling
    private static readonly HashSet<string> HtmlExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".html", ".htm"
    };

    // Magic bytes for file type detection
    private static readonly Dictionary<string, byte[][]> FileMagicBytes = new()
    {
        // PDF
        { ".pdf", new[] { new byte[] { 0x25, 0x50, 0x44, 0x46 } } }, // %PDF

        // Microsoft Office (ZIP-based: DOCX, XLSX, PPTX)
        { ".docx", new[] { new byte[] { 0x50, 0x4B, 0x03, 0x04 } } }, // PK (ZIP)
        { ".xlsx", new[] { new byte[] { 0x50, 0x4B, 0x03, 0x04 } } },
        { ".pptx", new[] { new byte[] { 0x50, 0x4B, 0x03, 0x04 } } },

        // Legacy Office formats
        { ".doc", new[] { new byte[] { 0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1 } } }, // OLE
        { ".xls", new[] { new byte[] { 0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1 } } },
        { ".ppt", new[] { new byte[] { 0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1 } } },

        // Images
        { ".jpg", new[] { new byte[] { 0xFF, 0xD8, 0xFF } } }, // JPEG
        { ".jpeg", new[] { new byte[] { 0xFF, 0xD8, 0xFF } } },
        { ".png", new[] { new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A } } }, // PNG
        { ".gif", new[] { new byte[] { 0x47, 0x49, 0x46, 0x38 } } }, // GIF
        { ".bmp", new[] { new byte[] { 0x42, 0x4D } } }, // BMP
        { ".tif", new[] { new byte[] { 0x49, 0x49, 0x2A, 0x00 }, new byte[] { 0x4D, 0x4D, 0x00, 0x2A } } }, // TIFF
        { ".tiff", new[] { new byte[] { 0x49, 0x49, 0x2A, 0x00 }, new byte[] { 0x4D, 0x4D, 0x00, 0x2A } } },
        { ".webp", new[] { new byte[] { 0x52, 0x49, 0x46, 0x46 } } }, // RIFF (WebP)
    };

    public PdfConversionService(
        IOptions<PdfConversionOptions> options,
        ILogger<PdfConversionService> logger)
    {
        _options = options.Value;
        _logger = logger;

        // Ensure directories exist on service creation
        EnsureDirectoriesExist();
    }

    /// <summary>
    /// Initialize PDFTron (called once for the entire application)
    /// </summary>
    public void InitializePdfTron()
    {
        if (_isPdfTronInitialized)
        {
            _logger.LogDebug("PDFTron already initialized");
            return;
        }

        lock (_initLock)
        {
            if (_isPdfTronInitialized)
                return;

            try
            {
                _logger.LogInformation("Initializing PDFTron...");

                // Initialize PDFTron with or without license key
                if (!string.IsNullOrWhiteSpace(_options.LicenseKey))
                {
                    _logger.LogInformation("Initializing PDFTron with license key");
                    pdftron.PDFNet.Initialize(_options.LicenseKey);
                }
                else
                {
                    _logger.LogWarning("Initializing PDFTron in Trial mode (no license key provided)");
                    pdftron.PDFNet.Initialize();
                }

                _isPdfTronInitialized = true;
                _logger.LogInformation("PDFTron initialized successfully");
            }
            catch (pdftron.Common.PDFNetException pdfEx) when (pdfEx.Message.Contains("valid key"))
            {
                _logger.LogWarning("PDFTron license key is not valid or missing");
                _logger.LogWarning("Get a demo key at: https://www.pdftron.com/pws/get-key");
                _logger.LogWarning("Add the key to appsettings.json under PdfConversion:LicenseKey");
                // Re-throw exception - initialization failed
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to initialize PDFTron");
                throw new InvalidOperationException("PDFTron initialization failed", ex);
            }
        }
    }

    /// <summary>
    /// Convert a file to PDF
    /// </summary>
    public async Task<ConversionResponse> ConvertToPdfAsync(string sourceFilePath, string? outputFileName = null)
    {
        var stopwatch = Stopwatch.StartNew();
        
        try
        {
            _logger.LogInformation("Starting conversion for file: {SourceFile}", sourceFilePath);

            // Ensure PDFTron is initialized before conversion
            InitializePdfTron();

            // Step 1: Validate the source file
            var (isValid, validationError) = await ValidateFileAsync(sourceFilePath);
            if (!isValid)
            {
                _logger.LogWarning("File validation failed for {SourceFile}: {Error}", sourceFilePath, validationError);
                return ConversionResponse.CreateError(validationError ?? "File validation failed");
            }

            // Step 2: Prepare output path
            var outputPath = PrepareOutputPath(sourceFilePath, outputFileName);
            _logger.LogInformation("Output path: {OutputPath}", outputPath);

            // Step 3: Perform conversion based on file type
            var fileExtension = Path.GetExtension(sourceFilePath).ToLowerInvariant();
            await Task.Run(() => PerformConversionByType(sourceFilePath, outputPath, fileExtension));

            stopwatch.Stop();
            _logger.LogInformation(
                "Conversion completed successfully: {OutputPath} (Duration: {Duration}ms)",
                outputPath,
                stopwatch.ElapsedMilliseconds);

            return ConversionResponse.CreateSuccess(outputPath, stopwatch.Elapsed);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, "Conversion failed for file: {SourceFile}", sourceFilePath);
            
            return ConversionResponse.CreateError(
                "File conversion failed",
                $"{ex.GetType().Name}: {ex.Message}");
        }
    }

    /// <summary>
    /// Convert an uploaded file to PDF (bypasses directory validation)
    /// </summary>
    public async Task<ConversionResponse> ConvertUploadedFileToPdfAsync(string sourceFilePath, string? outputFileName = null)
    {
        var stopwatch = Stopwatch.StartNew();
        
        try
        {
            _logger.LogInformation("Starting conversion for uploaded file: {SourceFile}", sourceFilePath);

            // Ensure PDFTron is initialized before conversion
            InitializePdfTron();

            // Step 1: Basic validation (without directory check)
            var (isValid, validationError) = await ValidateUploadedFileAsync(sourceFilePath);
            if (!isValid)
            {
                _logger.LogWarning("File validation failed for {SourceFile}: {Error}", sourceFilePath, validationError);
                return ConversionResponse.CreateError(validationError ?? "File validation failed");
            }

            // Step 2: Prepare output path
            var outputPath = PrepareOutputPath(sourceFilePath, outputFileName);
            _logger.LogInformation("Output path: {OutputPath}", outputPath);

            // Step 3: Perform conversion based on file type
            var fileExtension = Path.GetExtension(sourceFilePath).ToLowerInvariant();
            await Task.Run(() => PerformConversionByType(sourceFilePath, outputPath, fileExtension));

            stopwatch.Stop();
            _logger.LogInformation(
                "Conversion completed successfully: {OutputPath} (Duration: {Duration}ms)",
                outputPath,
                stopwatch.ElapsedMilliseconds);

            return ConversionResponse.CreateSuccess(outputPath, stopwatch.Elapsed);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, "Conversion failed for uploaded file: {SourceFile}", sourceFilePath);
            
            return ConversionResponse.CreateError(
                "File conversion failed",
                $"{ex.GetType().Name}: {ex.Message}");
        }
    }

    /// <summary>
    /// Validate input file
    /// </summary>
    public async Task<(bool IsValid, string? ErrorMessage)> ValidateFileAsync(string filePath)
    {
        return await Task.Run(() =>
        {
            try
            {
                // Check 1: File exists
                if (!File.Exists(filePath))
                {
                    _logger.LogWarning("File not found: {FilePath}", filePath);
                    return (false, $"File not found: {filePath}");
                }

                // Check 2: File must be within Input directory
                var fullInputPath = Path.GetFullPath(_options.InputDirectory);
                var fullFilePath = Path.GetFullPath(filePath);
                
                if (!fullFilePath.StartsWith(fullInputPath, StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogWarning("File is outside the Input directory: {FilePath}", filePath);
                    return (false, $"File must be within the allowed directory: {_options.InputDirectory}");
                }

                // Check 3: File extension validation
                var extension = Path.GetExtension(filePath).ToLowerInvariant();
                if (!_options.AllowedExtensions.Contains(extension))
                {
                    _logger.LogWarning("File extension not allowed: {Extension}", extension);
                    return (false, $"File extension not allowed. Allowed extensions: {string.Join(", ", _options.AllowedExtensions)}");
                }

                // Check 4: File size validation
                var fileInfo = new FileInfo(filePath);
                var fileSizeMB = fileInfo.Length / (1024.0 * 1024.0);
                
                if (fileSizeMB > _options.MaxFileSizeMB)
                {
                    _logger.LogWarning("File size too large: {Size}MB (Maximum: {Max}MB)", 
                        fileSizeMB, _options.MaxFileSizeMB);
                    return (false, $"File size too large ({fileSizeMB:F2}MB). Maximum allowed: {_options.MaxFileSizeMB}MB");
                }

                // Check 5: File is not locked
                try
                {
                    using var stream = File.Open(filePath, FileMode.Open, FileAccess.Read, FileShare.Read);
                }
                catch (IOException)
                {
                    _logger.LogWarning("File is locked or inaccessible: {FilePath}", filePath);
                    return (false, "File is locked or in use by another process");
                }

                _logger.LogDebug("File validation passed successfully for: {FilePath}", filePath);
                return (true, null);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during file validation: {FilePath}", filePath);
                return (false, $"Validation error: {ex.Message}");
            }
        });
    }

    /// <summary>
    /// Validate uploaded file (without directory check)
    /// </summary>
    private async Task<(bool IsValid, string? ErrorMessage)> ValidateUploadedFileAsync(string filePath)
    {
        return await Task.Run(() =>
        {
            try
            {
                // Check 1: File exists
                if (!File.Exists(filePath))
                {
                    _logger.LogWarning("File not found: {FilePath}", filePath);
                    return (false, $"File not found: {filePath}");
                }

                // Check 2: File extension validation
                var extension = Path.GetExtension(filePath).ToLowerInvariant();
                if (!_options.AllowedExtensions.Contains(extension))
                {
                    _logger.LogWarning("File extension not allowed: {Extension}", extension);
                    return (false, $"File extension not allowed. Allowed extensions: {string.Join(", ", _options.AllowedExtensions)}");
                }

                // Check 3: File size validation
                var fileInfo = new FileInfo(filePath);
                var fileSizeMB = fileInfo.Length / (1024.0 * 1024.0);
                
                if (fileSizeMB > _options.MaxFileSizeMB)
                {
                    _logger.LogWarning("File size too large: {Size}MB (Maximum: {Max}MB)", 
                        fileSizeMB, _options.MaxFileSizeMB);
                    return (false, $"File size too large ({fileSizeMB:F2}MB). Maximum allowed: {_options.MaxFileSizeMB}MB");
                }

                // Check 4: File is not locked
                try
                {
                    using var stream = File.Open(filePath, FileMode.Open, FileAccess.Read, FileShare.Read);
                }
                catch (IOException)
                {
                    _logger.LogWarning("File is locked or inaccessible: {FilePath}", filePath);
                    return (false, "File is locked or in use by another process");
                }

                _logger.LogDebug("Uploaded file validation passed successfully for: {FilePath}", filePath);
                return (true, null);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during uploaded file validation: {FilePath}", filePath);
                return (false, $"Validation error: {ex.Message}");
            }
        });
    }

    /// <summary>
    /// Perform conversion based on file type
    /// </summary>
    private void PerformConversionByType(string sourceFilePath, string outputPath, string fileExtension)
    {
        try
        {
            _logger.LogDebug("Converting {Extension} file: {Source} -> {Output}", 
                fileExtension, sourceFilePath, outputPath);

            using (var pdfDoc = new PDFDoc())
            {
                if (OfficeExtensions.Contains(fileExtension))
                {
                    // Microsoft Office documents (Word, Excel, PowerPoint)
                    _logger.LogDebug("Using OfficeToPDF conversion for Office document");
                    pdftron.PDF.Convert.OfficeToPDF(pdfDoc, sourceFilePath, null);
                }
                else if (HtmlExtensions.Contains(fileExtension))
                {
                    // HTML files - Use PDFTron's HTML2PDF module (native support, no MS Word needed)
                    _logger.LogDebug("Using HTML2PDF conversion for HTML document");
                    
                    // Set module path - either configured or auto-detect from bin directory
                    string modulePath;
                    if (!string.IsNullOrWhiteSpace(_options.Html2PdfModulePath))
                    {
                        modulePath = _options.Html2PdfModulePath;
                        _logger.LogInformation("Using configured HTML2PDF module path: {Path}", modulePath);
                    }
                    else
                    {
                        // Auto-detect: look for html2pdf.dll in the bin directory
                        var appDirectory = AppDomain.CurrentDomain.BaseDirectory;
                        var possiblePaths = new[]
                        {
                            Path.Combine(appDirectory, "html2pdf.dll"),
                            Path.Combine(appDirectory, "html2pdf_chromium.dll"),
                            Path.Combine(appDirectory, "native", "win-x64", "html2pdf.dll"),
                            Path.Combine(appDirectory, "native", "win-x64", "html2pdf_chromium.dll")
                        };

                        modulePath = possiblePaths.FirstOrDefault(File.Exists);
                        
                        if (modulePath != null)
                        {
                            _logger.LogInformation("Auto-detected HTML2PDF module at: {Path}", modulePath);
                        }
                        else
                        {
                            _logger.LogError("HTML2PDF module not found in any of the expected locations:");
                            foreach (var path in possiblePaths)
                            {
                                _logger.LogError("  - {Path}", path);
                            }
                            throw new InvalidOperationException(
                                "HTML2PDF module (html2pdf.dll) not found. " +
                                "Download from https://www.pdftron.com/download-center/windows/ " +
                                "and place in bin directory or native\\win-x64\\ folder");
                        }
                    }
                    
                    // Set the module path
                    pdftron.PDF.HTML2PDF.SetModulePath(Path.GetDirectoryName(modulePath));
                    _logger.LogDebug("Set HTML2PDF module directory: {Dir}", Path.GetDirectoryName(modulePath));
                    
                    // Create HTML2PDF converter
                    var html2Pdf = new pdftron.PDF.HTML2PDF();
                    
                    // Read HTML content with UTF-8 encoding to preserve Hebrew text
                    string htmlContent;
                    using (var reader = new System.IO.StreamReader(sourceFilePath, System.Text.Encoding.UTF8, detectEncodingFromByteOrderMarks: true))
                    {
                        htmlContent = reader.ReadToEnd();
                    }
                    
                    _logger.LogDebug("Read HTML content with UTF-8 encoding ({Length} characters)", htmlContent.Length);
                    
                    // Log first 200 characters for debugging encoding issues
                    if (htmlContent.Length > 0)
                    {
                        var preview = htmlContent.Substring(0, Math.Min(200, htmlContent.Length));
                        _logger.LogDebug("HTML content preview: {Preview}...", preview);
                    }
                    
                    // Ensure HTML has proper UTF-8 meta tag and encoding declaration
                    if (!htmlContent.Contains("charset", StringComparison.OrdinalIgnoreCase))
                    {
                        _logger.LogInformation("Adding UTF-8 charset meta tag to HTML content");
                        
                        // Add charset meta tag if missing
                        if (htmlContent.Contains("<head>", StringComparison.OrdinalIgnoreCase))
                        {
                            htmlContent = htmlContent.Replace("<head>", 
                                "<head>\n    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n    <meta charset=\"UTF-8\">", 
                                StringComparison.OrdinalIgnoreCase);
                        }
                        else if (htmlContent.Contains("<html", StringComparison.OrdinalIgnoreCase))
                        {
                            htmlContent = htmlContent.Replace("<html", 
                                "<html>\n<head>\n    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n    <meta charset=\"UTF-8\">\n</head>", 
                                StringComparison.OrdinalIgnoreCase);
                        }
                    }
                    
                    try
                    {
                        // CRITICAL FIX: Use InsertFromHtmlString instead of InsertFromURL
                        // This allows us to pass the HTML content directly with proper encoding
                        // instead of relying on PDFTron to read the file
                        _logger.LogDebug("Converting HTML to PDF using InsertFromHtmlString with UTF-8 encoding");
                        
                        // Insert HTML content directly as string with UTF-8 encoding
                        // The null parameter means use default WebPageSettings
                        html2Pdf.InsertFromHtmlString(htmlContent);
                        
                        // Convert to PDF
                        if (html2Pdf.Convert(pdfDoc))
                        {
                            _logger.LogDebug("HTML2PDF conversion completed successfully with UTF-8 encoding");
                        }
                        else
                        {
                            _logger.LogWarning("HTML2PDF conversion completed with warnings");
                        }
                    }
                    catch (Exception htmlEx)
                    {
                        _logger.LogError(htmlEx, "HTML2PDF conversion using InsertFromHtmlString failed, attempting fallback method");
                        
                        // Fallback: Save to temporary file with UTF-8 BOM and use file:// URL
                        var tempHtmlPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.html");
                        var utf8WithBom = new System.Text.UTF8Encoding(encoderShouldEmitUTF8Identifier: true);
                        
                        using (var writer = new System.IO.StreamWriter(tempHtmlPath, false, utf8WithBom))
                        {
                            writer.Write(htmlContent);
                        }
                        
                        _logger.LogDebug("Saved HTML to temporary file with UTF-8 BOM: {Path}", tempHtmlPath);
                        
                        try
                        {
                            // Use file:// URL protocol for better encoding support
                            var fileUrl = new Uri(tempHtmlPath).AbsoluteUri;
                            _logger.LogDebug("Using file URL: {Url}", fileUrl);
                            
                            html2Pdf.InsertFromURL(fileUrl);
                            
                            if (html2Pdf.Convert(pdfDoc))
                            {
                                _logger.LogDebug("HTML2PDF fallback conversion completed successfully");
                            }
                            else
                            {
                                _logger.LogWarning("HTML2PDF fallback conversion completed with warnings");
                            }
                        }
                        finally
                        {
                            // Clean up temporary file
                            try
                            {
                                if (File.Exists(tempHtmlPath))
                                {
                                    File.Delete(tempHtmlPath);
                                }
                            }
                            catch (Exception cleanupEx)
                            {
                                _logger.LogWarning(cleanupEx, "Failed to delete temporary HTML file: {Path}", tempHtmlPath);
                            }
                        }
                    }
                }
                else if (ImageExtensions.Contains(fileExtension))
                {
                    // Image files - use ToPdf with image-specific conversion
                    _logger.LogDebug("Using ToPdf conversion for image file");
                    pdftron.PDF.Convert.ToPdf(pdfDoc, sourceFilePath);
                }
                else
                {
                    // Generic conversion for all other formats (TXT, RTF, XML, XPS, etc.)
                    _logger.LogDebug("Using generic ToPdf conversion");
                    pdftron.PDF.Convert.ToPdf(pdfDoc, sourceFilePath);
                }

                // Save to PDF with linearization (fast web view)
                pdfDoc.Save(outputPath, SDFDoc.SaveOptions.e_linearized);
                
                _logger.LogDebug("PDFTron conversion completed successfully");
            }
        }
        catch (pdftron.Common.PDFNetException pdfEx) when (pdfEx.Message.Contains("html2pdf"))
        {
            _logger.LogError(pdfEx, "HTML2PDF module not found for: {Source}", sourceFilePath);
            _logger.LogError("==========================================================================");
            _logger.LogError("HTML2PDF MODULE MISSING - Required for HTML to PDF conversion");
            _logger.LogError("Download from: https://www.pdftron.com/download-center/windows/");
            _logger.LogError("Place html2pdf.dll in: native\\win-x64\\ folder");
            _logger.LogError("==========================================================================");
            throw new InvalidOperationException(
                "HTML2PDF module not found. Download from https://www.pdftron.com/download-center/windows/ and place html2pdf.dll in native\\win-x64\\ folder", 
                pdfEx);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PDFTron conversion failed for: {Source}", sourceFilePath);
            throw new InvalidOperationException($"PDFTron conversion failed: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Prepare output file path
    /// </summary>
    private string PrepareOutputPath(string sourceFilePath, string? outputFileName)
    {
        try
        {
            // Determine file name
            var fileName = !string.IsNullOrWhiteSpace(outputFileName)
                ? outputFileName
                : Path.GetFileNameWithoutExtension(sourceFilePath);

            // Add PDF extension
            var pdfFileName = $"{fileName}.pdf";

            // Build full output path
            var outputPath = Path.Combine(_options.OutputDirectory, pdfFileName);

            // If file already exists - add timestamp
            if (File.Exists(outputPath))
            {
                var timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                pdfFileName = $"{fileName}_{timestamp}.pdf";
                outputPath = Path.Combine(_options.OutputDirectory, pdfFileName);
                
                _logger.LogInformation("File already exists - added timestamp: {FileName}", pdfFileName);
            }

            return outputPath;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error preparing output path");
            throw new InvalidOperationException("Failed to prepare output path", ex);
        }
    }

    /// <summary>
    /// Ensure Input and Output directories exist
    /// </summary>
    private void EnsureDirectoriesExist()
    {
        try
        {
            if (!Directory.Exists(_options.InputDirectory))
            {
                Directory.CreateDirectory(_options.InputDirectory);
                _logger.LogInformation("Created Input directory: {Path}", _options.InputDirectory);
            }

            if (!Directory.Exists(_options.OutputDirectory))
            {
                Directory.CreateDirectory(_options.OutputDirectory);
                _logger.LogInformation("Created Output directory: {Path}", _options.OutputDirectory);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating directories");
            throw new InvalidOperationException("Failed to create required directories", ex);
        }
    }

    /// <summary>
    /// Merge multiple files into a single PDF
    /// </summary>
    public async Task<MergeResponse> MergeFilesToPdfAsync(List<string> sourceFileNames, string? outputFileName = null)
    {
        var stopwatch = Stopwatch.StartNew();
        var successfulFiles = new List<string>();
        var failedFiles = new List<FileError>();
        var tempPdfFiles = new List<string>();

        try
        {
            _logger.LogInformation("Starting merge operation for {Count} files", sourceFileNames.Count);

            // Ensure PDFTron is initialized
            InitializePdfTron();

            // Validate input
            if (sourceFileNames == null || sourceFileNames.Count == 0)
            {
                return MergeResponse.CreateError("No files provided for merging");
            }

            // Step 1: Convert each file to PDF (to temp location) OR copy if already PDF
            _logger.LogInformation("Step 1: Preparing PDF files...");
            
            foreach (var fileName in sourceFileNames)
            {
                try
                {
                    var sourceFilePath = Path.Combine(_options.InputDirectory, fileName.Trim());
                    
                    // Validate file
                    var (isValid, validationError) = await ValidateFileAsync(sourceFilePath);
                    if (!isValid)
                    {
                        _logger.LogWarning("File validation failed for {FileName}: {Error}", fileName, validationError);
                        failedFiles.Add(new FileError 
                        { 
                            FileName = fileName, 
                            ErrorMessage = validationError ?? "Validation failed" 
                        });
                        continue;
                    }

                    var fileExtension = Path.GetExtension(sourceFilePath).ToLowerInvariant();
                    var tempPdfPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.pdf");
                    
                    // Check if file is already a PDF
                    if (fileExtension == ".pdf")
                    {
                        // File is already PDF - just copy it
                        _logger.LogInformation("File {FileName} is already PDF - copying directly", fileName);
                        File.Copy(sourceFilePath, tempPdfPath, overwrite: true);
                    }
                    else
                    {
                        // Convert to PDF
                        _logger.LogInformation("Converting {FileName} to PDF", fileName);
                        await Task.Run(() => PerformConversionByType(sourceFilePath, tempPdfPath, fileExtension));
                    }
                    
                    tempPdfFiles.Add(tempPdfPath);
                    successfulFiles.Add(fileName);
                    
                    _logger.LogInformation("Successfully prepared {FileName} for merging", fileName);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to prepare {FileName}", fileName);
                    failedFiles.Add(new FileError 
                    { 
                        FileName = fileName, 
                        ErrorMessage = $"{ex.GetType().Name}: {ex.Message}" 
                    });
                }
            }

            // Check if we have any files to merge
            if (tempPdfFiles.Count == 0)
            {
                stopwatch.Stop();
                return MergeResponse.CreateError(
                    "No files were successfully prepared for merging",
                    $"Failed to prepare all {sourceFileNames.Count} files");
            }

            // Step 2: Merge all PDF files
            _logger.LogInformation("Step 2: Merging {Count} PDF files...", tempPdfFiles.Count);
            
            var finalOutputPath = PrepareMergeOutputPath(outputFileName);
            await Task.Run(() => MergePdfFiles(tempPdfFiles, finalOutputPath));

            stopwatch.Stop();
            
            _logger.LogInformation(
                "Merge operation completed: {OutputPath} ({SuccessCount}/{TotalCount} files, Duration: {Duration}ms)",
                finalOutputPath,
                successfulFiles.Count,
                sourceFileNames.Count,
                stopwatch.ElapsedMilliseconds);

            return MergeResponse.CreateSuccess(
                finalOutputPath,
                sourceFileNames.Count,
                successfulFiles.Count,
                successfulFiles,
                failedFiles,
                stopwatch.Elapsed);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, "Merge operation failed");
            
            return MergeResponse.CreateError(
                "Merge operation failed",
                $"{ex.GetType().Name}: {ex.Message}");
        }
        finally
        {
            // Clean up temporary PDF files
            foreach (var tempFile in tempPdfFiles)
            {
                try
                {
                    if (File.Exists(tempFile))
                    {
                        File.Delete(tempFile);
                        _logger.LogDebug("Deleted temporary file: {TempFile}", tempFile);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to delete temporary file: {TempFile}", tempFile);
                }
            }
        }
    }

    /// <summary>
    /// Convert HTML from URL to PDF
    /// </summary>
    public async Task<ConversionResponse> ConvertUrlToPdfAsync(string url, string? outputFileName = null)
    {
        var stopwatch = Stopwatch.StartNew();
        string? tempHtmlPath = null;

        try
        {
            _logger.LogInformation("Starting URL to PDF conversion: {Url}", url);

            // Ensure PDFTron is initialized
            InitializePdfTron();

            // Step 1: Download HTML from URL
            _logger.LogInformation("Downloading HTML from URL...");
            string htmlContent;
            
            using (var httpClient = new HttpClient())
            {
                httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36");
                httpClient.Timeout = TimeSpan.FromSeconds(30);

                var response = await httpClient.GetAsync(url);
                
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Failed to download URL: {StatusCode}", response.StatusCode);
                    return ConversionResponse.CreateError(
                        "Failed to download HTML from URL",
                        $"HTTP Status: {response.StatusCode}");
                }

                htmlContent = await response.Content.ReadAsStringAsync();
                _logger.LogInformation("Downloaded HTML content: {Length} characters", htmlContent.Length);
            }

            // Step 2: Save HTML to temporary file with UTF-8 encoding
            tempHtmlPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.html");
            var utf8WithBom = new System.Text.UTF8Encoding(encoderShouldEmitUTF8Identifier: true);
            await File.WriteAllTextAsync(tempHtmlPath, htmlContent, utf8WithBom);
            
            _logger.LogInformation("Saved HTML to temporary file: {TempPath}", tempHtmlPath);

            // Step 3: Prepare output path
            var finalOutputFileName = !string.IsNullOrWhiteSpace(outputFileName)
                ? outputFileName
                : $"url_conversion_{DateTime.Now:yyyyMMdd_HHmmss}";
            
            var outputPath = Path.Combine(_options.OutputDirectory, $"{finalOutputFileName}.pdf");

            // Add timestamp if file exists
            if (File.Exists(outputPath))
            {
                var timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss_fff");
                finalOutputFileName = $"{finalOutputFileName}_{timestamp}";
                outputPath = Path.Combine(_options.OutputDirectory, $"{finalOutputFileName}.pdf");
            }

            // Step 4: Convert HTML to PDF
            _logger.LogInformation("Converting HTML to PDF...");
            await Task.Run(() => PerformConversionByType(tempHtmlPath, outputPath, ".html"));

            stopwatch.Stop();

            _logger.LogInformation(
                "URL to PDF conversion completed: {OutputPath} (Duration: {Duration}ms)",
                outputPath,
                stopwatch.ElapsedMilliseconds);

            return ConversionResponse.CreateSuccess(outputPath, stopwatch.Elapsed);
        }
        catch (HttpRequestException httpEx)
        {
            stopwatch.Stop();
            _logger.LogError(httpEx, "Failed to download HTML from URL: {Url}", url);
            
            return ConversionResponse.CreateError(
                "Failed to download HTML from URL",
                $"Network error: {httpEx.Message}");
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, "URL to PDF conversion failed for: {Url}", url);
            
            return ConversionResponse.CreateError(
                "URL to PDF conversion failed",
                $"{ex.GetType().Name}: {ex.Message}");
        }
        finally
        {
            // Clean up temporary HTML file
            if (tempHtmlPath != null && File.Exists(tempHtmlPath))
            {
                try
                {
                    File.Delete(tempHtmlPath);
                    _logger.LogDebug("Deleted temporary HTML file: {Path}", tempHtmlPath);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to delete temporary HTML file: {Path}", tempHtmlPath);
                }
            }
        }
    }

    /// <summary>
    /// Merge multiple PDF files into a single PDF with normalized page sizes
    /// </summary>
    private void MergePdfFiles(List<string> pdfFiles, string outputPath)
    {
        try
        {
            _logger.LogDebug("Merging {Count} PDF files into {Output}", pdfFiles.Count, outputPath);

            using (var mergedDoc = new PDFDoc())
            {
                // Standard page size - A4 in points (595 x 842)
                const double standardWidth = 595.0;
                const double standardHeight = 842.0;
                
                // Add each PDF to the merged document
                foreach (var pdfFile in pdfFiles)
                {
                    try
                    {
                        using (var currentDoc = new PDFDoc(pdfFile))
                        {
                            // Get page count
                            int pageCount = currentDoc.GetPageCount();
                            
                            // Check and normalize each page
                            for (int i = 1; i <= pageCount; i++)
                            {
                                var page = currentDoc.GetPage(i);
                                var pageRect = page.GetCropBox();
                                double pageWidth = pageRect.Width();
                                double pageHeight = pageRect.Height();
                                
                                // Check if page needs resizing (images are often huge)
                                if (pageWidth > (standardWidth * 1.5) || 
                                    pageHeight > (standardHeight * 1.5) ||
                                    pageWidth < (standardWidth * 0.5) ||
                                    pageHeight < (standardHeight * 0.5))
                                {
                                    _logger.LogInformation("Normalizing page {Page} from {Width}x{Height} to A4", 
                                        i, pageWidth, pageHeight);
                                    
                                    // Calculate scaling to fit within A4
                                    double scaleX = standardWidth / pageWidth;
                                    double scaleY = standardHeight / pageHeight;
                                    double scale = Math.Min(scaleX, scaleY);
                                    
                                    // Scale content
                                    page.Scale(scale);
                                    
                                    // Update page boxes to A4 after scaling
                                    page.SetMediaBox(new pdftron.PDF.Rect(0, 0, standardWidth, standardHeight));
                                    page.SetCropBox(new pdftron.PDF.Rect(0, 0, standardWidth, standardHeight));
                                }
                            }
                            
                            // Import all pages (now normalized)
                            mergedDoc.InsertPages(
                                mergedDoc.GetPageCount() + 1,
                                currentDoc,
                                1,
                                pageCount,
                                PDFDoc.InsertFlag.e_none);
                            
                            _logger.LogDebug("Added {Count} pages from {PdfFile}", 
                                pageCount, Path.GetFileName(pdfFile));
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to add PDF file to merge: {PdfFile}", pdfFile);
                        throw;
                    }
                }

                // Save merged document with linearization
                mergedDoc.Save(outputPath, SDFDoc.SaveOptions.e_linearized);
                
                _logger.LogDebug("Merged PDF saved successfully: {OutputPath}", outputPath);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PDF merge failed");
            throw new InvalidOperationException($"Failed to merge PDF files: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Prepare output file path for merged PDF
    /// </summary>
    private string PrepareMergeOutputPath(string? outputFileName)
    {
        try
        {
            // Determine file name
            var fileName = !string.IsNullOrWhiteSpace(outputFileName)
                ? outputFileName
                : "mergePDF";

            // Add timestamp
            var timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            var pdfFileName = $"{fileName}_{timestamp}.pdf";

            // Build full output path
            var outputPath = Path.Combine(_options.OutputDirectory, pdfFileName);

            _logger.LogInformation("Merge output path prepared: {OutputPath}", outputPath);

            return outputPath;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error preparing merge output path");
            throw new InvalidOperationException("Failed to prepare merge output path", ex);
        }
    }

    /// <summary>
    /// Convert byte array to PDF
    /// </summary>
    public async Task<ByteConversionResponse> ConvertBytesToPdfAsync(
        byte[] fileBytes, 
        string? originalFileName = null, 
        string? outputFileName = null)
    {
        var stopwatch = Stopwatch.StartNew();
        string? tempInputPath = null;
        string? tempOutputPath = null;

        try
        {
            _logger.LogInformation(
                "Starting byte array conversion (Size: {Size} bytes, OriginalFileName: {FileName})", 
                fileBytes.Length, 
                originalFileName ?? "Not provided");

            // Step 1: Validate byte array size (50MB limit)
            var fileSizeMB = fileBytes.Length / (1024.0 * 1024.0);
            if (fileSizeMB > _options.MaxFileSizeMB)
            {
                _logger.LogWarning("Byte array size too large: {Size}MB (Maximum: {Max}MB)", 
                    fileSizeMB, _options.MaxFileSizeMB);
                return ByteConversionResponse.CreateError(
                    $"File size too large ({fileSizeMB:F2}MB). Maximum allowed: {_options.MaxFileSizeMB}MB");
            }

            // Ensure PDFTron is initialized
            InitializePdfTron();

            // Step 2: Detect file type from magic bytes or file name
            var detectedExtension = DetectFileTypeFromBytes(fileBytes, originalFileName);
            
            if (detectedExtension == null)
            {
                _logger.LogWarning("Could not detect file type from byte array");
                return ByteConversionResponse.CreateError(
                    "Could not detect file type. Please provide OriginalFileName parameter.");
            }

            _logger.LogInformation("Detected file type: {Extension}", detectedExtension);

            // Step 3: Validate file type is supported
            if (!_options.AllowedExtensions.Contains(detectedExtension))
            {
                _logger.LogWarning("File type not supported: {Extension}", detectedExtension);
                return ByteConversionResponse.CreateError(
                    $"File type '{detectedExtension}' is not supported. " +
                    $"Allowed extensions: {string.Join(", ", _options.AllowedExtensions)}");
            }

            // Step 4: Save byte array to temporary file
            tempInputPath = Path.Combine(
                Path.GetTempPath(), 
                $"input_{Guid.NewGuid()}{detectedExtension}");
            
            await File.WriteAllBytesAsync(tempInputPath, fileBytes);
            _logger.LogInformation("Saved byte array to temporary file: {TempPath}", tempInputPath);

            // Step 5: Prepare temporary output path
            tempOutputPath = Path.Combine(
                Path.GetTempPath(), 
                $"output_{Guid.NewGuid()}.pdf");

            // Step 6: Perform conversion
            _logger.LogInformation("Converting {Extension} to PDF...", detectedExtension);
            await Task.Run(() => PerformConversionByType(tempInputPath, tempOutputPath, detectedExtension));

            // Step 7: Read converted PDF back to byte array
            var pdfBytes = await File.ReadAllBytesAsync(tempOutputPath);
            _logger.LogInformation("PDF conversion completed. Output size: {Size} bytes", pdfBytes.Length);

            // Step 8: Prepare output file name
            var finalOutputFileName = !string.IsNullOrWhiteSpace(outputFileName)
                ? $"{outputFileName}.pdf"
                : !string.IsNullOrWhiteSpace(originalFileName)
                    ? $"{Path.GetFileNameWithoutExtension(originalFileName)}.pdf"
                    : "converted.pdf";

            stopwatch.Stop();

            _logger.LogInformation(
                "Byte array conversion completed successfully: {FileName} (Duration: {Duration}ms)",
                finalOutputFileName,
                stopwatch.ElapsedMilliseconds);

            return ByteConversionResponse.CreateSuccess(
                pdfBytes, 
                finalOutputFileName, 
                detectedExtension,
                stopwatch.Elapsed);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, "Byte array conversion failed");
            
            return ByteConversionResponse.CreateError(
                "Byte array conversion failed",
                $"{ex.GetType().Name}: {ex.Message}");
        }
        finally
        {
            // Clean up temporary files
            if (tempInputPath != null && File.Exists(tempInputPath))
            {
                try
                {
                    File.Delete(tempInputPath);
                    _logger.LogDebug("Deleted temporary input file: {Path}", tempInputPath);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to delete temporary input file: {Path}", tempInputPath);
                }
            }

            if (tempOutputPath != null && File.Exists(tempOutputPath))
            {
                try
                {
                    File.Delete(tempOutputPath);
                    _logger.LogDebug("Deleted temporary output file: {Path}", tempOutputPath);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to delete temporary output file: {Path}", tempOutputPath);
                }
            }
        }
    }

    /// <summary>
    /// Detect file type from byte array magic bytes or file name
    /// </summary>
    private string? DetectFileTypeFromBytes(byte[] fileBytes, string? originalFileName)
    {
        try
        {
            // Priority 1: Try to detect from magic bytes
            if (fileBytes.Length >= 8)
            {
                foreach (var kvp in FileMagicBytes)
                {
                    var extension = kvp.Key;
                    var magicBytesList = kvp.Value;

                    foreach (var magicBytes in magicBytesList)
                    {
                        if (fileBytes.Length >= magicBytes.Length)
                        {
                            bool matches = true;
                            for (int i = 0; i < magicBytes.Length; i++)
                            {
                                if (fileBytes[i] != magicBytes[i])
                                {
                                    matches = false;
                                    break;
                                }
                            }

                            if (matches)
                            {
                                _logger.LogInformation(
                                    "Detected file type from magic bytes: {Extension}", 
                                    extension);
                                return extension;
                            }
                        }
                    }
                }
            }

            // Priority 2: Try to detect from file name if provided
            if (!string.IsNullOrWhiteSpace(originalFileName))
            {
                var extension = Path.GetExtension(originalFileName).ToLowerInvariant();
                if (!string.IsNullOrEmpty(extension))
                {
                    _logger.LogInformation(
                        "Detected file type from file name: {Extension}", 
                        extension);
                    return extension;
                }
            }

            // Priority 3: Check if it's a text file (all bytes are printable ASCII)
            if (fileBytes.Length > 0 && IsTextFile(fileBytes))
            {
                _logger.LogInformation("Detected as text file based on content analysis");
                return ".txt";
            }

            _logger.LogWarning("Could not detect file type from byte array or file name");
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error detecting file type from bytes");
            return null;
        }
    }

    /// <summary>
    /// Check if byte array represents a text file
    /// </summary>
    private bool IsTextFile(byte[] fileBytes)
    {
        try
        {
            // Check first 1000 bytes (or less if file is smaller)
            int checkLength = Math.Min(1000, fileBytes.Length);
            int textCharCount = 0;

            for (int i = 0; i < checkLength; i++)
            {
                byte b = fileBytes[i];
                
                // Check if byte is printable ASCII, whitespace, or common control characters
                if ((b >= 0x20 && b <= 0x7E) || // Printable ASCII
                    b == 0x09 || // Tab
                    b == 0x0A || // Line Feed
                    b == 0x0D)   // Carriage Return
                {
                    textCharCount++;
                }
            }

            // If more than 95% of bytes are text characters, consider it a text file
            double textRatio = (double)textCharCount / checkLength;
            return textRatio > 0.95;
        }
        catch
        {
            return false;
        }
    }
}

