using System.ComponentModel.DataAnnotations;

namespace Poc_PdfTron.Models;

/// <summary>
/// Request model for converting HTML from URL to PDF
/// </summary>
public class UrlConversionRequest
{
    /// <summary>
    /// URL of the HTML page to convert
    /// Example: https://www.example.com/page.html
    /// </summary>
    [Required(ErrorMessage = "URL is required")]
    [Url(ErrorMessage = "Invalid URL format")]
    public string Url { get; set; } = string.Empty;

    /// <summary>
    /// Optional custom name for the output file (without extension)
    /// If not provided - will use a generated name based on timestamp
    /// </summary>
    public string? OutputFileName { get; set; }
}
