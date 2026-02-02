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
                    validate = "/api/pdfconversion/validate",
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

            // Save the uploaded file to a temporary location
            var tempInputPath = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString() + Path.GetExtension(file.FileName));
            
            using (var stream = new FileStream(tempInputPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
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
}
