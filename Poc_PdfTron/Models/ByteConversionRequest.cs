using System.ComponentModel.DataAnnotations;

namespace Poc_PdfTron.Models;

/// <summary>
/// Request model for byte array to PDF conversion
/// </summary>
public class ByteConversionRequest
{
    /// <summary>
    /// File content as Base64 encoded string
    /// </summary>
    [Required(ErrorMessage = "File bytes are required")]
    public string FileBytes { get; set; } = string.Empty;

    /// <summary>
    /// Optional original file name (used for file type detection)
    /// Example: "document.docx", "image.jpg"
    /// If not provided, file type will be detected from magic bytes
    /// </summary>
    public string? OriginalFileName { get; set; }

    /// <summary>
    /// Optional custom name for the output PDF file (without extension)
    /// If not provided - will use "converted" as default name
    /// </summary>
    public string? OutputFileName { get; set; }
}
