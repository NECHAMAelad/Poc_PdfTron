using System.ComponentModel.DataAnnotations;

namespace Poc_PdfTron.Models;

/// <summary>
/// Request model for file to PDF conversion
/// </summary>
public class ConversionRequest
{
    /// <summary>
    /// Full path to the source file (must be within InputDirectory)
    /// Example: C:\Temp\Input\document.docm
    /// </summary>
    [Required(ErrorMessage = "Source file path is required")]
    public string SourceFilePath { get; set; } = string.Empty;

    /// <summary>
    /// Optional custom name for the output file (without extension)
    /// If not provided - will use the source file name
    /// </summary>
    public string? OutputFileName { get; set; }
}
