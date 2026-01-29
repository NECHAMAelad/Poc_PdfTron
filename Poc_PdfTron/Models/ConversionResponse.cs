namespace Poc_PdfTron.Models;

/// <summary>
/// Response model for conversion operations
/// </summary>
public class ConversionResponse
{
    /// <summary>
    /// Indicates whether the conversion was successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Full path to the converted PDF file
    /// </summary>
    public string? OutputFilePath { get; set; }

    /// <summary>
    /// Output file name only (without path)
    /// </summary>
    public string? OutputFileName { get; set; }

    /// <summary>
    /// Size of the output file in bytes
    /// </summary>
    public long? OutputFileSizeBytes { get; set; }

    /// <summary>
    /// Time taken for the conversion
    /// </summary>
    public TimeSpan? ConversionDuration { get; set; }

    /// <summary>
    /// Error message (if conversion failed)
    /// </summary>
    public string? ErrorMessage { get; set; }

    /// <summary>
    /// Additional error details
    /// </summary>
    public string? ErrorDetails { get; set; }

    /// <summary>
    /// Creates a success response with file information
    /// </summary>
    public static ConversionResponse CreateSuccess(string outputPath, TimeSpan duration)
    {
        var fileInfo = new FileInfo(outputPath);
        return new ConversionResponse
        {
            Success = true,
            OutputFilePath = outputPath,
            OutputFileName = fileInfo.Name,
            OutputFileSizeBytes = fileInfo.Length,
            ConversionDuration = duration
        };
    }

    /// <summary>
    /// Creates an error response with error information
    /// </summary>
    public static ConversionResponse CreateError(string errorMessage, string? errorDetails = null)
    {
        return new ConversionResponse
        {
            Success = false,
            ErrorMessage = errorMessage,
            ErrorDetails = errorDetails
        };
    }
}
