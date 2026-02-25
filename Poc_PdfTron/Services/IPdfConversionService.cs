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
    /// Convert a byte array to PDF format
    /// </summary>
    /// <param name="fileBytes">Byte array of the source file</param>
    /// <param name="originalFileName">Optional original file name (for file type detection)</param>
    /// <param name="outputFileName">Optional custom output file name (without extension)</param>
    /// <returns>Byte conversion response with PDF bytes or error details</returns>
    Task<ByteConversionResponse> ConvertBytesToPdfAsync(
        byte[] fileBytes, 
        string? originalFileName = null, 
        string? outputFileName = null);

    /// <summary>
    /// Merge multiple files into a single PDF
    /// </summary>
    /// <param name="sourceFileNames">List of file names (not full paths) from InputDirectory</param>
    /// <param name="outputFileName">Optional custom output file name (without extension)</param>
    /// <returns>Merge response with result details</returns>
    Task<MergeResponse> MergeFilesToPdfAsync(List<string> sourceFileNames, string? outputFileName = null);

    /// <summary>
    /// Convert HTML from URL to PDF
    /// </summary>
    /// <param name="url">URL of the HTML page to convert</param>
    /// <param name="outputFileName">Optional custom output file name (without extension)</param>
    /// <returns>Conversion response with result details</returns>
    Task<ConversionResponse> ConvertUrlToPdfAsync(string url, string? outputFileName = null);

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
