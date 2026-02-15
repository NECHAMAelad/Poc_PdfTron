using pdftron;
using System.Runtime.InteropServices;
using Poc_PdfTron.Models;
using Poc_PdfTron.Services;
using Poc_PdfTron.Middleware;

var builder = WebApplication.CreateBuilder(args);

// =====================================================
// Configure Services
// =====================================================

// Configure PdfConversionOptions from appsettings.json
builder.Services.Configure<PdfConversionOptions>(
    builder.Configuration.GetSection(PdfConversionOptions.SectionName));

// Register conversion service
builder.Services.AddSingleton<IPdfConversionService, PdfConversionService>();

builder.Services.AddControllers();

// Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "PDF Conversion API",
        Version = "v1",
        Description = "API for converting various file formats to PDF using PDFTron"
    });
});

// Add CORS policy for browser access
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// =====================================================
// Configure Pipeline
// =====================================================

// Global exception handling middleware (must be first!)
app.UseMiddleware<GlobalExceptionMiddleware>();

// Enable default files BEFORE static files (order matters!)
app.UseDefaultFiles();

// Enable static files (for serving HTML, CSS, JS)
app.UseStaticFiles();

// Enable CORS
app.UseCors();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "PDF Conversion API v1");
        options.RoutePrefix = "swagger"; // Set Swagger UI at /swagger instead of root
    });
    
    // In development, redirect HTTP to HTTPS can be optional
    // app.UseHttpsRedirection();
}
else
{
    app.UseHttpsRedirection();
}

app.UseAuthorization();

app.MapControllers();

// =====================================================
// Health Check Endpoints
// =====================================================

app.MapGet("/health", () => Results.Ok(new 
{ 
    status = "Healthy",
    timestamp = DateTime.UtcNow,
    message = "API is running successfully"
}))
    .WithName("HealthCheck")
    .WithTags("Health");

app.MapGet("/health/pdfnetc", () =>
{
    const string libName = "PDFNetC";

    try
    {
        IntPtr handle = NativeLibrary.Load(libName);
        NativeLibrary.Free(handle);

        return Results.Ok(new
        {
            status = "Healthy",
            library = libName,
            message = "Native PDFNetC library loaded successfully"
        });
    }
    catch (Exception ex)
    {
        return Results.Problem(
            detail: $"Failed to load PDFNetC library: {ex.Message}",
            statusCode: 500,
            title: "PDFNetC Library Error"
        );
    }
})
.WithName("PDFNetCHealthCheck")
.WithTags("Health");

// =====================================================
// Initialize PDFTron at Startup
// =====================================================
try
{
    var conversionService = app.Services.GetRequiredService<IPdfConversionService>();
    conversionService.InitializePdfTron();
    
    app.Logger.LogInformation("? PDFTron initialized successfully at application startup");
}
catch (pdftron.Common.PDFNetException pdfEx) when (pdfEx.Message.Contains("valid key"))
{
    app.Logger.LogWarning("? PDFTron license key is not valid or missing");
    app.Logger.LogWarning("  Get a demo key at: https://www.pdftron.com/pws/get-key");
    app.Logger.LogWarning("  The application will continue running but conversions will fail without a valid license");
    app.Logger.LogWarning("  For testing purposes, you can use PDFTron in trial mode with limited functionality");
}
catch (Exception ex)
{
    app.Logger.LogError(ex, "? Failed to initialize PDFTron at application startup");
    app.Logger.LogError("  Check that PDFNetC.dll is present in the bin directory");
}

// Log application URLs
app.Lifetime.ApplicationStarted.Register(() =>
{
    var addresses = app.Urls;
    app.Logger.LogInformation("========================================");
    app.Logger.LogInformation("PDF Conversion API is ready!");
    app.Logger.LogInformation("========================================");
    foreach (var address in addresses)
    {
        app.Logger.LogInformation($"Listening on: {address}");
    }
    app.Logger.LogInformation("Swagger UI: {Url}", $"{addresses.FirstOrDefault()}/swagger");
    app.Logger.LogInformation("========================================");
});

app.Run();
