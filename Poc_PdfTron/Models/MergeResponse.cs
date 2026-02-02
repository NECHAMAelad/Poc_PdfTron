namespace Poc_PdfTron.Models;

/// <summary>
/// Response model for merge operations
/// </summary>
public class MergeResponse
{
    /// <summary>
    /// Indicates if the merge operation was successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Path to the merged output PDF file
    /// </summary>
    public string? OutputFilePath { get; set; }

    /// <summary>
    /// Name of the merged output PDF file
    /// </summary>
    public string? OutputFileName { get; set; }

    /// <summary>
    /// Number of files successfully merged
    /// </summary>
    public int FilesProcessed { get; set; }

    /// <summary>
    /// Total number of files requested to merge
    /// </summary>
    public int TotalFiles { get; set; }

    /// <summary>
    /// List of files that were successfully converted and merged
    /// </summary>
    public List<string> SuccessfulFiles { get; set; } = new();

    /// <summary>
    /// List of files that failed with error messages
    /// </summary>
    public List<FileError> FailedFiles { get; set; } = new();

    /// <summary>
    /// Duration of the entire merge operation
    /// </summary>
    public TimeSpan Duration { get; set; }

    /// <summary>
    /// Error message if the entire operation failed
    /// </summary>
    public string? ErrorMessage { get; set; }

    /// <summary>
    /// Additional details about the error
    /// </summary>
    public string? ErrorDetails { get; set; }

    /// <summary>
    /// Create a successful merge response
    /// </summary>
    public static MergeResponse CreateSuccess(
        string outputPath, 
        int totalFiles,
        int processedFiles,
        List<string> successfulFiles,
        List<FileError> failedFiles,
        TimeSpan duration)
    {
        return new MergeResponse
        {
            Success = true,
            OutputFilePath = outputPath,
            OutputFileName = Path.GetFileName(outputPath),
            TotalFiles = totalFiles,
            FilesProcessed = processedFiles,
            SuccessfulFiles = successfulFiles,
            FailedFiles = failedFiles,
            Duration = duration
        };
    }

    /// <summary>
    /// Create an error merge response
    /// </summary>
    public static MergeResponse CreateError(string errorMessage, string? errorDetails = null)
    {
        return new MergeResponse
        {
            Success = false,
            ErrorMessage = errorMessage,
            ErrorDetails = errorDetails
        };
    }
}

/// <summary>
/// Represents a file that failed during merge operation
/// </summary>
public class FileError
{
    /// <summary>
    /// Name of the file that failed
    /// </summary>
    public string FileName { get; set; } = string.Empty;

    /// <summary>
    /// Error message
    /// </summary>
    public string ErrorMessage { get; set; } = string.Empty;
}
