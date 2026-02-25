namespace Poc_PdfTron.Models;

/// <summary>
/// Response model for byte array to PDF conversion
/// </summary>
public class ByteConversionResponse
{
    /// <summary>
    /// Indicates if the conversion was successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// PDF content as byte array (only populated on success)
    /// </summary>
    public byte[]? PdfBytes { get; set; }

    /// <summary>
    /// Output file name with .pdf extension
    /// </summary>
    public string? OutputFileName { get; set; }

    /// <summary>
    /// Size of the PDF in bytes
    /// </summary>
    public long PdfSizeBytes { get; set; }

    /// <summary>
    /// Detected or provided file type/extension
    /// </summary>
    public string? DetectedFileType { get; set; }

    /// <summary>
    /// Time taken for the conversion
    /// </summary>
    public TimeSpan ConversionDuration { get; set; }

    /// <summary>
    /// Error message if conversion failed
    /// </summary>
    public string? ErrorMessage { get; set; }

    /// <summary>
    /// Detailed error information (only included when detailed errors are enabled)
    /// </summary>
    public string? ErrorDetails { get; set; }

    /// <summary>
    /// Create a successful response
    /// </summary>
    public static ByteConversionResponse CreateSuccess(
        byte[] pdfBytes, 
        string outputFileName, 
        string detectedFileType,
        TimeSpan duration)
    {
        return new ByteConversionResponse
        {
            Success = true,
            PdfBytes = pdfBytes,
            OutputFileName = outputFileName,
            PdfSizeBytes = pdfBytes.Length,
            DetectedFileType = detectedFileType,
            ConversionDuration = duration
        };
    }

    /// <summary>
    /// Create an error response
    /// </summary>
    public static ByteConversionResponse CreateError(string errorMessage, string? errorDetails = null)
    {
        return new ByteConversionResponse
        {
            Success = false,
            ErrorMessage = errorMessage,
            ErrorDetails = errorDetails
        };
    }
}
