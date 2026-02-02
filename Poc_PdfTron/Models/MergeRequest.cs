using System.ComponentModel.DataAnnotations;

namespace Poc_PdfTron.Models;

/// <summary>
/// Request model for merging multiple files into a single PDF
/// </summary>
public class MergeRequest
{
    /// <summary>
    /// Comma-separated list of file names (not full paths)
    /// Files must be in the InputDirectory
    /// Example: "document1.docx,presentation.pptx,report.xlsx"
    /// </summary>
    [Required(ErrorMessage = "Source files list is required")]
    public string SourceFiles { get; set; } = string.Empty;

    /// <summary>
    /// Optional custom name for the output file (without extension)
    /// If not provided - will use "mergePDF" with timestamp
    /// </summary>
    public string? OutputFileName { get; set; }
}
