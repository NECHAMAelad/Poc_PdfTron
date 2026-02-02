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
                    // HTML files - PDFTron requires MS Word for HTML conversion
                    // For now, throw a more helpful error
                    _logger.LogWarning("HTML conversion requires Microsoft Word to be installed");
                    throw new NotSupportedException(
                        "HTML to PDF conversion requires Microsoft Word to be installed on the server. " +
                        "Please install Microsoft Word or use a different file format.");
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

            // Step 1: Convert each file to PDF (to temp location)
            _logger.LogInformation("Step 1: Converting files to PDF format...");
            
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

                    // Convert to PDF (to temp location)
                    var tempPdfPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.pdf");
                    
                    var fileExtension = Path.GetExtension(sourceFilePath).ToLowerInvariant();
                    await Task.Run(() => PerformConversionByType(sourceFilePath, tempPdfPath, fileExtension));
                    
                    tempPdfFiles.Add(tempPdfPath);
                    successfulFiles.Add(fileName);
                    
                    _logger.LogInformation("Successfully converted {FileName} to PDF", fileName);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to convert {FileName}", fileName);
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
                    "No files were successfully converted to PDF",
                    $"Failed to convert all {sourceFileNames.Count} files");
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
}
