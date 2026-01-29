using Poc_PdfTron.Models;

namespace Poc_PdfTron.Services;

/// <summary>
/// Service interface for converting files to PDF using PDFTron
/// </summary>
public interface IPdfConversionService
{
    /// <summary>
    /// Convert a file to PDF format
    /// </summary>
    /// <param name="sourceFilePath">Full path to the source file</param>
    /// <param name="outputFileName">Optional custom output file name (without extension)</param>
    /// <returns>Conversion response with result details</returns>
    Task<ConversionResponse> ConvertToPdfAsync(string sourceFilePath, string? outputFileName = null);

    /// <summary>
    /// Convert an uploaded file to PDF format (bypasses directory validation)
    /// </summary>
    /// <param name="sourceFilePath">Full path to the uploaded file (can be anywhere)</param>
    /// <param name="outputFileName">Optional custom output file name (without extension)</param>
    /// <returns>Conversion response with result details</returns>
    Task<ConversionResponse> ConvertUploadedFileToPdfAsync(string sourceFilePath, string? outputFileName = null);

    /// <summary>
    /// Validate if a file is suitable for conversion
    /// </summary>
    /// <param name="filePath">Path to the file</param>
    /// <returns>Tuple indicating validation result and error message if invalid</returns>
    Task<(bool IsValid, string? ErrorMessage)> ValidateFileAsync(string filePath);

    /// <summary>
    /// Initialize PDFTron with license key (called once at startup)
    /// </summary>
    void InitializePdfTron();
}
