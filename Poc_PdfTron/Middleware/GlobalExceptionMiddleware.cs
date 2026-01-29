using System.Net;
using System.Text.Json;

namespace Poc_PdfTron.Middleware;

/// <summary>
/// Middleware for handling global exceptions
/// Catches all unhandled exceptions and returns standardized error responses
/// </summary>
public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IHostEnvironment _environment;

    public GlobalExceptionMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionMiddleware> logger,
        IHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception occurred at {Path}", context.Request.Path);
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";

        var response = new ErrorResponse
        {
            Type = "https://tools.ietf.org/html/rfc7231#section-6.6.1",
            Title = "An error occurred while processing your request",
            Status = (int)HttpStatusCode.InternalServerError,
            Instance = context.Request.Path,
            TraceId = context.TraceIdentifier
        };

        // Customize response based on exception type
        switch (exception)
        {
            case ArgumentException argEx:
                response.Status = (int)HttpStatusCode.BadRequest;
                response.Title = "Invalid argument";
                response.Detail = argEx.Message;
                break;

            case InvalidOperationException invOpEx:
                response.Status = (int)HttpStatusCode.BadRequest;
                response.Title = "Invalid operation";
                response.Detail = invOpEx.Message;
                break;

            case UnauthorizedAccessException:
                response.Status = (int)HttpStatusCode.Forbidden;
                response.Title = "Access denied";
                response.Detail = "You do not have permission to access this resource";
                break;

            case FileNotFoundException fileNotFoundEx:
                response.Status = (int)HttpStatusCode.NotFound;
                response.Title = "File not found";
                response.Detail = fileNotFoundEx.Message;
                break;

            default:
                response.Status = (int)HttpStatusCode.InternalServerError;
                response.Title = "Internal server error";
                response.Detail = _environment.IsDevelopment()
                    ? exception.Message
                    : "An unexpected error occurred. Please contact support if the problem persists.";
                break;
        }

        // Include stack trace in development environment only
        if (_environment.IsDevelopment())
        {
            response.DeveloperMessage = exception.ToString();
        }

        context.Response.StatusCode = response.Status;

        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = true
        };

        var json = JsonSerializer.Serialize(response, jsonOptions);
        await context.Response.WriteAsync(json);
    }

    /// <summary>
    /// Error response model following RFC 7807 (Problem Details)
    /// </summary>
    private class ErrorResponse
    {
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public int Status { get; set; }
        public string? Detail { get; set; }
        public string Instance { get; set; } = string.Empty;
        public string? TraceId { get; set; }
        public string? DeveloperMessage { get; set; }
    }
}
