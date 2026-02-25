using Microsoft.AspNetCore.Mvc;
using Poc_PdfTron.Models;
using Poc_PdfTron.Services;

namespace Poc_PdfTron.Controllers;

/// <summary>
/// API Controller for PDF conversion operations
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class PdfConversionController : ControllerBase
{
    private readonly IPdfConversionService _conversionService;
    private readonly ILogger<PdfConversionController> _logger;

    public PdfConversionController(
        IPdfConversionService conversionService,
        ILogger<PdfConversionController> logger)
    {
        _conversionService = conversionService;
        _logger = logger;
    }

    /// <summary>
    /// Convert a file to PDF
    /// </summary>
    /// <param name="request">Conversion request containing source file path and options</param>
    /// <returns>Conversion response with output file path or error details</returns>
    /// <response code="200">Conversion successful</response>
    /// <response code="400">Invalid request or file validation failed</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("convert")]
    [ProducesResponseType(typeof(ConversionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
    public async Task<ActionResult<ConversionResponse>> ConvertToPdf([FromBody] ConversionRequest request)
    {
        try
        {
            _logger.LogInformation("Received conversion request for file: {FilePath}", request.SourceFilePath);

            // Validate model state
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Invalid model state: {Errors}", ModelState);
                return BadRequest(ModelState);
            }

            // Perform conversion
            var result = await _conversionService.ConvertToPdfAsync(
                request.SourceFilePath,
                request.OutputFileName);

            // Check result
            if (!result.Success)
            {
                _logger.LogWarning("Conversion failed: {Error}", result.ErrorMessage);
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Conversion failed",
                    Detail = result.ErrorMessage,
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation("Conversion successful: {OutputPath}", result.OutputFilePath);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing conversion request for file: {FilePath}", request.SourceFilePath);
            
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = "An unexpected error occurred during file conversion. Please try again.",
                Instance = HttpContext.Request.Path
            });
        }
    }

    /// <summary>
    /// Validate if a file can be converted
    /// </summary>
    /// <param name="filePath">Path to the file to validate</param>
    /// <returns>Validation result indicating if file is valid for conversion</returns>
    /// <response code="200">File is valid</response>
    /// <response code="400">File is not valid</response>
    [HttpGet("validate")]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult> ValidateFile([FromQuery] string filePath)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(filePath))
            {
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Missing parameter",
                    Detail = "File path is required",
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation("Validating file: {FilePath}", filePath);

            var (isValid, errorMessage) = await _conversionService.ValidateFileAsync(filePath);

            if (!isValid)
            {
                _logger.LogWarning("File validation failed: {Error}", errorMessage);
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "File validation failed",
                    Detail = errorMessage,
                    Instance = HttpContext.Request.Path
                });
            }

            return Ok(new
            {
                isValid = true,
                message = "File is valid and ready for conversion",
                filePath
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during file validation: {FilePath}", filePath);
            
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = "An unexpected error occurred during file validation",
                Instance = HttpContext.Request.Path
            });
        }
    }

    /// <summary>
    /// Get service settings and initialization status
    /// </summary>
    /// <returns>Service configuration details</returns>
    [HttpGet("settings")]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    public ActionResult GetSettings()
    {
        // Call InitializePdfTron to ensure it's initialized
        try
        {
            _conversionService.InitializePdfTron();
            
            return Ok(new
            {
                pdfTronInitialized = true,
                message = "PDFTron service is initialized and ready",
                endpoints = new
                {
                    convert = "/api/pdfconversion/convert",
                    convertAndDownload = "/api/pdfconversion/convert-and-download",
                    uploadAndConvert = "/api/pdfconversion/upload-and-convert",
                    convertFromUrl = "/api/pdfconversion/convert-from-url",
                    convertFromBytes = "/api/pdfconversion/convert-from-bytes",
                    convertFromBytesAndDownload = "/api/pdfconversion/convert-from-bytes-and-download",
                    validate = "/api/pdfconversion/validate",
                    merge = "/api/pdfconversion/merge",
                    mergeAndDownload = "/api/pdfconversion/merge-and-download",
                    settings = "/api/pdfconversion/settings"
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to initialize PDFTron");
            
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                pdfTronInitialized = false,
                error = "PDFTron initialization failed",
                details = ex.Message
            });
        }
    }

    /// <summary>
    /// Convert a file to PDF and return the PDF file directly
    /// </summary>
    /// <param name="request">Conversion request containing source file path and options</param>
    /// <returns>PDF file as byte stream</returns>
    /// <response code="200">PDF file returned successfully</response>
    /// <response code="400">Invalid request or file validation failed</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("convert-and-download")]
    [ProducesResponseType(typeof(FileResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ConvertAndDownload([FromBody] ConversionRequest request)
    {
        try
        {
            _logger.LogInformation("Received convert-and-download request for file: {FilePath}", request.SourceFilePath);

            // Validate model state
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Invalid model state: {Errors}", ModelState);
                return BadRequest(ModelState);
            }

            // Perform conversion
            var result = await _conversionService.ConvertToPdfAsync(
                request.SourceFilePath,
                request.OutputFileName);

            // Check result
            if (!result.Success)
            {
                _logger.LogWarning("Conversion failed: {Error}", result.ErrorMessage);
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Conversion failed",
                    Detail = result.ErrorMessage,
                    Instance = HttpContext.Request.Path
                });
            }

            // Read the PDF file and return it
            var pdfBytes = await System.IO.File.ReadAllBytesAsync(result.OutputFilePath!);
            
            _logger.LogInformation("Returning PDF file: {OutputPath} ({Size} bytes)", 
                result.OutputFilePath, pdfBytes.Length);

            return File(pdfBytes, "application/pdf", result.OutputFileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing convert-and-download request for file: {FilePath}", 
                request.SourceFilePath);
            
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = "An unexpected error occurred during file conversion. Please try again.",
                Instance = HttpContext.Request.Path
            });
        }
    }

    /// <summary>
    /// Upload a file, convert it to PDF, and return the PDF file directly
    /// </summary>
    /// <param name="file">The file to convert</param>
    /// <param name="outputFileName">Optional output file name (without extension)</param>
    /// <returns>PDF file as byte stream</returns>
    /// <response code="200">PDF file returned successfully</response>
    /// <response code="400">Invalid file or conversion failed</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("upload-and-convert")]
    [ProducesResponseType(typeof(FileResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> UploadAndConvert(
        IFormFile file, 
        [FromForm] string? outputFileName = null)
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "No file provided",
                    Detail = "Please select a file to convert",
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation("Received file upload: {FileName} ({Size} bytes)", 
                file.FileName, file.Length);

            // Save the uploaded file to a temporary location with proper UTF-8 encoding
            var tempInputPath = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString() + Path.GetExtension(file.FileName));
            
            // CRITICAL FIX: For HTML files, we need to preserve UTF-8 encoding
            // Read the uploaded file content and save it with explicit UTF-8 encoding
            if (Path.GetExtension(file.FileName).Equals(".html", StringComparison.OrdinalIgnoreCase) || 
                Path.GetExtension(file.FileName).Equals(".htm", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogDebug("Detected HTML file - saving with explicit UTF-8 encoding");
                
                // Read content as UTF-8
                string htmlContent;
                using (var reader = new System.IO.StreamReader(file.OpenReadStream(), System.Text.Encoding.UTF8, detectEncodingFromByteOrderMarks: true))
                {
                    htmlContent = await reader.ReadToEndAsync();
                }
                
                // Log first 200 characters for debugging
                if (htmlContent.Length > 0)
                {
                    var preview = htmlContent.Substring(0, Math.Min(200, htmlContent.Length));
                    _logger.LogDebug("Uploaded HTML content preview: {Preview}...", preview);
                }
                
                // Save with UTF-8 encoding (with BOM for better compatibility)
                var utf8WithBom = new System.Text.UTF8Encoding(encoderShouldEmitUTF8Identifier: true);
                await System.IO.File.WriteAllTextAsync(tempInputPath, htmlContent, utf8WithBom);
                
                _logger.LogDebug("Saved HTML file with UTF-8 BOM encoding to: {Path}", tempInputPath);
            }
            else
            {
                // For non-HTML files, use regular binary copy
                using (var stream = new FileStream(tempInputPath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }
            }

            try
            {
                // Convert the file using the uploaded file method (no directory validation)
                var result = await _conversionService.ConvertUploadedFileToPdfAsync(
                    tempInputPath,
                    outputFileName ?? Path.GetFileNameWithoutExtension(file.FileName));

                // Check result
                if (!result.Success)
                {
                    _logger.LogWarning("Conversion failed: {Error}", result.ErrorMessage);
                    return BadRequest(new ProblemDetails
                    {
                        Status = StatusCodes.Status400BadRequest,
                        Title = "Conversion failed",
                        Detail = result.ErrorMessage,
                        Instance = HttpContext.Request.Path
                    });
                }

                // Read the PDF file
                var pdfBytes = await System.IO.File.ReadAllBytesAsync(result.OutputFilePath!);
                
                _logger.LogInformation("Returning PDF file: {OutputFileName} ({Size} bytes)", 
                    result.OutputFileName, pdfBytes.Length);

                // Clean up temporary files
                try
                {
                    if (System.IO.File.Exists(tempInputPath))
                        System.IO.File.Delete(tempInputPath);
                }
                catch (Exception cleanupEx)
                {
                    _logger.LogWarning(cleanupEx, "Failed to delete temporary input file: {Path}", tempInputPath);
                }

                return File(pdfBytes, "application/pdf", result.OutputFileName);
            }
            finally
            {
                // Ensure temp file is deleted even if conversion fails
                try
                {
                    if (System.IO.File.Exists(tempInputPath))
                        System.IO.File.Delete(tempInputPath);
                }
                catch { /* Ignore cleanup errors */ }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing file upload");
            
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = "An unexpected error occurred during file conversion. Please try again.",
                Instance = HttpContext.Request.Path
            });
        }
    }

    /// <summary>
    /// Merge multiple files into a single PDF
    /// </summary>
    /// <param name="request">Merge request containing comma-separated file names</param>
    /// <returns>Merge response with output file path and details</returns>
    /// <response code="200">Merge successful</response>
    /// <response code="400">Invalid request or no files could be merged</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("merge")]
    [ProducesResponseType(typeof(MergeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
    public async Task<ActionResult<MergeResponse>> MergeFiles([FromBody] MergeRequest request)
    {
        try
        {
            _logger.LogInformation("Received merge request for files: {Files}", request.SourceFiles);

            // Validate model state
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Invalid model state: {Errors}", ModelState);
                return BadRequest(ModelState);
            }

            // Parse comma-separated file names
            var fileNames = request.SourceFiles
                .Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(f => f.Trim())
                .Where(f => !string.IsNullOrWhiteSpace(f))
                .ToList();

            if (fileNames.Count == 0)
            {
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "No files provided",
                    Detail = "Please provide at least one file name in the SourceFiles field",
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation("Parsed {Count} file names from request", fileNames.Count);

            // Perform merge
            var result = await _conversionService.MergeFilesToPdfAsync(fileNames, request.OutputFileName);

            // Check result
            if (!result.Success)
            {
                _logger.LogWarning("Merge failed: {Error}", result.ErrorMessage);
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Merge failed",
                    Detail = result.ErrorMessage,
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation("Merge successful: {OutputPath}", result.OutputFilePath);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing merge request");
            
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = "An unexpected error occurred during file merge. Please try again.",
                Instance = HttpContext.Request.Path
            });
        }
    }

    /// <summary>
    /// Merge multiple files into a single PDF and return the PDF file directly
    /// </summary>
    /// <param name="request">Merge request containing comma-separated file names</param>
    /// <returns>PDF file as byte stream</returns>
    /// <response code="200">PDF file returned successfully</response>
    /// <response code="400">Invalid request or no files could be merged</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("merge-and-download")]
    [ProducesResponseType(typeof(FileResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> MergeAndDownload([FromBody] MergeRequest request)
    {
        try
        {
            _logger.LogInformation("Received merge-and-download request for files: {Files}", request.SourceFiles);

            // Validate model state
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Invalid model state: {Errors}", ModelState);
                return BadRequest(ModelState);
            }

            // Parse comma-separated file names
            var fileNames = request.SourceFiles
                .Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(f => f.Trim())
                .Where(f => !string.IsNullOrWhiteSpace(f))
                .ToList();

            if (fileNames.Count == 0)
            {
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "No files provided",
                    Detail = "Please provide at least one file name in the SourceFiles field",
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation("Parsed {Count} file names from request", fileNames.Count);

            // Perform merge
            var result = await _conversionService.MergeFilesToPdfAsync(fileNames, request.OutputFileName);

            // Check result
            if (!result.Success)
            {
                _logger.LogWarning("Merge failed: {Error}", result.ErrorMessage);
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Merge failed",
                    Detail = result.ErrorMessage,
                    Instance = HttpContext.Request.Path
                });
            }

            // Read the PDF file and return it
            var pdfBytes = await System.IO.File.ReadAllBytesAsync(result.OutputFilePath!);
            
            _logger.LogInformation("Returning merged PDF file: {OutputPath} ({Size} bytes)", 
                result.OutputFilePath, pdfBytes.Length);

            return File(pdfBytes, "application/pdf", result.OutputFileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing merge-and-download request");
            
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = "An unexpected error occurred during file merge. Please try again.",
                Instance = HttpContext.Request.Path
            });
        }
    }

    /// <summary>
    /// Convert HTML from URL to PDF
    /// </summary>
    /// <param name="request">URL conversion request containing the URL and optional output file name</param>
    /// <returns>PDF file as byte stream</returns>
    /// <response code="200">PDF file returned successfully</response>
    /// <response code="400">Invalid URL or conversion failed</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("convert-from-url")]
    [ProducesResponseType(typeof(FileResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ConvertFromUrl([FromBody] UrlConversionRequest request)
    {
        try
        {
            _logger.LogInformation("Received URL conversion request: {Url}", request.Url);

            // Validate model state
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Invalid model state: {Errors}", ModelState);
                return BadRequest(ModelState);
            }

            // Perform conversion
            var result = await _conversionService.ConvertUrlToPdfAsync(
                request.Url,
                request.OutputFileName);

            // Check result
            if (!result.Success)
            {
                _logger.LogWarning("URL conversion failed: {Error}", result.ErrorMessage);
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Conversion failed",
                    Detail = result.ErrorMessage,
                    Instance = HttpContext.Request.Path
                });
            }

            // Read the PDF file and return it
            var pdfBytes = await System.IO.File.ReadAllBytesAsync(result.OutputFilePath!);
            
            _logger.LogInformation("Returning PDF file: {OutputPath} ({Size} bytes)", 
                result.OutputFilePath, pdfBytes.Length);

            return File(pdfBytes, "application/pdf", result.OutputFileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing URL conversion request");
            
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = "An unexpected error occurred during URL conversion. Please try again.",
                Instance = HttpContext.Request.Path
            });
        }
    }

    /// <summary>
    /// Convert a byte array to PDF and return the PDF bytes
    /// </summary>
    /// <param name="request">Byte conversion request containing file bytes and optional metadata</param>
    /// <returns>Byte conversion response with PDF bytes or error details</returns>
    /// <response code="200">Conversion successful, returns PDF as byte array in JSON response</response>
    /// <response code="400">Invalid request or conversion failed</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("convert-from-bytes")]
    [ProducesResponseType(typeof(ByteConversionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
    public async Task<ActionResult<ByteConversionResponse>> ConvertFromBytes([FromBody] ByteConversionRequest request)
    {
        try
        {
            _logger.LogInformation(
                "Received byte conversion request (OriginalFileName: {FileName})", 
                request.OriginalFileName ?? "Not provided");

            // Validate model state
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Invalid model state: {Errors}", ModelState);
                return BadRequest(ModelState);
            }

            // Validate Base64 string
            if (string.IsNullOrWhiteSpace(request.FileBytes))
            {
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "No file data provided",
                    Detail = "FileBytes string is empty or null",
                    Instance = HttpContext.Request.Path
                });
            }

            // Decode Base64 to byte array
            byte[] fileBytes;
            try
            {
                fileBytes = Convert.FromBase64String(request.FileBytes);
            }
            catch (FormatException)
            {
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Invalid file data",
                    Detail = "FileBytes must be a valid Base64 encoded string",
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation("Decoded Base64 to {Size} bytes", fileBytes.Length);

            // Perform conversion
            var result = await _conversionService.ConvertBytesToPdfAsync(
                fileBytes,
                request.OriginalFileName,
                request.OutputFileName);

            // Check result
            if (!result.Success)
            {
                _logger.LogWarning("Byte conversion failed: {Error}", result.ErrorMessage);
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Conversion failed",
                    Detail = result.ErrorMessage,
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation(
                "Byte conversion completed successfully: {FileName} ({Size} bytes, Duration: {Duration}ms)",
                result.OutputFileName,
                result.PdfSizeBytes,
                result.ConversionDuration.TotalMilliseconds);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing byte conversion request");
            
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = "An unexpected error occurred during byte array conversion. Please try again.",
                Instance = HttpContext.Request.Path
            });
        }
    }

    /// <summary>
    /// Convert a byte array to PDF and return the PDF file directly for download
    /// </summary>
    /// <param name="request">Byte conversion request containing file bytes and optional metadata</param>
    /// <returns>PDF file as byte stream</returns>
    /// <response code="200">PDF file returned successfully</response>
    /// <response code="400">Invalid request or conversion failed</response>
    /// <response code="500">Internal server error</response>
    [HttpPost("convert-from-bytes-and-download")]
    [ProducesResponseType(typeof(FileResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ConvertFromBytesAndDownload([FromBody] ByteConversionRequest request)
    {
        try
        {
            _logger.LogInformation(
                "Received byte conversion-and-download request (OriginalFileName: {FileName})", 
                request.OriginalFileName ?? "Not provided");

            // Validate model state
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Invalid model state: {Errors}", ModelState);
                return BadRequest(ModelState);
            }

            // Validate Base64 string
            if (string.IsNullOrWhiteSpace(request.FileBytes))
            {
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "No file data provided",
                    Detail = "FileBytes string is empty or null",
                    Instance = HttpContext.Request.Path
                });
            }

            // Decode Base64 to byte array
            byte[] fileBytes;
            try
            {
                fileBytes = Convert.FromBase64String(request.FileBytes);
            }
            catch (FormatException)
            {
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Invalid file data",
                    Detail = "FileBytes must be a valid Base64 encoded string",
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation("Decoded Base64 to {Size} bytes", fileBytes.Length);

            // Perform conversion
            var result = await _conversionService.ConvertBytesToPdfAsync(
                fileBytes,
                request.OriginalFileName,
                request.OutputFileName);

            // Check result
            if (!result.Success)
            {
                _logger.LogWarning("Byte conversion failed: {Error}", result.ErrorMessage);
                return BadRequest(new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Conversion failed",
                    Detail = result.ErrorMessage,
                    Instance = HttpContext.Request.Path
                });
            }

            _logger.LogInformation(
                "Returning PDF file: {FileName} ({Size} bytes, Duration: {Duration}ms)",
                result.OutputFileName,
                result.PdfSizeBytes,
                result.ConversionDuration.TotalMilliseconds);

            return File(result.PdfBytes!, "application/pdf", result.OutputFileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing byte conversion-and-download request");
            
            return StatusCode(StatusCodes.Status500InternalServerError, new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = "An unexpected error occurred during byte array conversion. Please try again.",
                Instance = HttpContext.Request.Path
            });
        }
    }
}

