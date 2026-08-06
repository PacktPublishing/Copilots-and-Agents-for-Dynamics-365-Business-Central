using Backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DocumentController : ControllerBase
{
    private readonly DocumentProcessor _documentProcessor;
    private readonly ILogger<DocumentController> _logger;

    public DocumentController(
        DocumentProcessor documentProcessor,
        ILogger<DocumentController> logger)
    {
        _documentProcessor = documentProcessor;
        _logger = logger;
    }

    [HttpPost("upload")]
    public async Task<IActionResult> UploadDocument(
        IFormFile file,
        CancellationToken cancellationToken)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { error = "No file uploaded" });
        }

        if (!file.FileName.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { error = "Only PDF files are supported" });
        }

        try
        {
            _logger.LogInformation("Uploading document: {FileName}", file.FileName);

            // Ensure index exists
            await _documentProcessor.EnsureIndexExistsAsync(cancellationToken);

            // Process and index the PDF
            using var stream = file.OpenReadStream();
            var chunkCount = await _documentProcessor.ProcessAndIndexPdfAsync(
                stream,
                file.FileName,
                cancellationToken);

            return Ok(new
            {
                message = "Document uploaded and indexed successfully",
                fileName = file.FileName,
                chunksIndexed = chunkCount
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading document: {FileName}", file.FileName);
            return StatusCode(500, new { error = $"Error processing document: {ex.Message}" });
        }
    }

    [HttpGet("status")]
    public IActionResult GetStatus()
    {
        return Ok(new
        {
            status = "ready",
            message = "Document upload service is running"
        });
    }
}
