namespace Poc_PdfTron.Models;

/// <summary>
/// Configuration options for PDF conversion - loaded from appsettings.json
/// </summary>
public class PdfConversionOptions
{
    /// <summary>
    /// Section name in appsettings.json
    /// </summary>
    public const string SectionName = "PdfConversion";

    /// <summary>
    /// Directory path for input files (source files)
    /// </summary>
    public string InputDirectory { get; set; } = @"C:\Temp\Input";

    /// <summary>
    /// Directory path for output files (converted PDFs)
    /// </summary>
    public string OutputDirectory { get; set; } = @"C:\Temp\Output";

    /// <summary>
    /// PDFTron license key (optional - will use Trial mode if not provided)
    /// </summary>
    public string? LicenseKey { get; set; }

    /// <summary>
    /// Allowed file extensions for conversion (loaded from appsettings.json)
    /// Supports 43 different formats including:
    /// - Office: Word (.doc, .docx, .docm, .dot, .dotx, .dotm)
    /// - Office: Excel (.xls, .xlsx, .xlsm, .xlt, .xltx, .xltm)
    /// - Office: PowerPoint (.ppt, .pptx, .pptm, .pot, .potx, .potm, .pps, .ppsx, .ppsm)
    /// - Images (.jpg, .jpeg, .png, .bmp, .gif, .tif, .tiff, .webp, .svg, .emf, .wmf, .eps)
    /// - Text (.txt, .rtf, .xml, .md)
    /// - PDF (.pdf) - for merging existing PDFs
    /// - Other (.xps, .oxps, .pcl)
    /// Note: HTML requires Microsoft Word to be installed
    /// </summary>
    public string[] AllowedExtensions { get; set; } =
    [
        // Microsoft Office Documents (21 formats)
        ".doc", ".docx", ".docm", ".dot", ".dotx", ".dotm",
        ".xls", ".xlsx", ".xlsm", ".xlt", ".xltx", ".xltm",
        ".ppt", ".pptx", ".pptm", ".pot", ".potx", ".potm", ".pps", ".ppsx", ".ppsm",

        // Images (12 formats)
        ".jpg", ".jpeg", ".png", ".bmp", ".gif", ".tif", ".tiff", ".webp",
        ".svg", ".emf", ".wmf", ".eps",

        // Text & Markup (4 formats) - HTML removed, requires MS Word
        ".txt", ".rtf", ".xml", ".md",

        // PDF (1 format) - for merging existing PDFs
        ".pdf",

        // Other formats (3 formats)
        ".xps", ".oxps", ".pcl"
    ];

    /// <summary>
    /// Maximum allowed file size in megabytes (MB)
    /// </summary>
    public int MaxFileSizeMB { get; set; } = 50;
}
