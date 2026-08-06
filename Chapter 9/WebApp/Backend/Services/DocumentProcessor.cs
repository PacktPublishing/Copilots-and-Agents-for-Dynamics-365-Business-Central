using Azure;
using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Indexes.Models;
using Backend.Models;
using OpenAI.Embeddings;
using Docnet.Core;
using Docnet.Core.Models;
using System.Text;

namespace Backend.Services;

public class DocumentProcessor
{
    private readonly SearchIndexClient _indexClient;
    private readonly SearchClient _searchClient;
    private readonly EmbeddingClient _embeddingClient;
    private readonly ILogger<DocumentProcessor> _logger;
    private readonly string _indexName;

    public DocumentProcessor(
        SearchIndexClient indexClient,
        SearchClient searchClient,
        EmbeddingClient embeddingClient,
        ILogger<DocumentProcessor> logger,
        IConfiguration configuration)
    {
        _indexClient = indexClient;
        _searchClient = searchClient;
        _embeddingClient = embeddingClient;
        _logger = logger;
        _indexName = configuration["AzureAISearch:IndexName"] ?? "pdf-documents";
    }

    public async Task EnsureIndexExistsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var existingIndex = await _indexClient.GetIndexAsync(_indexName, cancellationToken);
            _logger.LogInformation("Index {IndexName} already exists", _indexName);
            
            // Check if the index has all required fields
            var hasDocumentId = existingIndex.Value.Fields.Any(f => f.Name == "documentId");
            if (!hasDocumentId)
            {
                _logger.LogWarning("Index {IndexName} missing documentId field. Recreating index.", _indexName);
                await _indexClient.DeleteIndexAsync(_indexName, cancellationToken);
                await CreateIndexAsync(cancellationToken);
            }
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            _logger.LogInformation("Creating index {IndexName}", _indexName);
            await CreateIndexAsync(cancellationToken);
        }
    }

    private async Task CreateIndexAsync(CancellationToken cancellationToken)
    {
        var index = new SearchIndex(_indexName)
        {
            Fields =
            {
                new SimpleField("id", SearchFieldDataType.String) { IsKey = true, IsFilterable = true },
                new SearchableField("content") { IsFilterable = false },
                new SearchableField("title") { IsFilterable = true, IsSortable = true },
                new SimpleField("documentId", SearchFieldDataType.String) { IsFilterable = true },
                new SimpleField("pageNumber", SearchFieldDataType.Int32) { IsFilterable = true, IsSortable = true },
                new SearchField("contentVector", SearchFieldDataType.Collection(SearchFieldDataType.Single))
                {
                    IsSearchable = true,
                    VectorSearchDimensions = 1536, // For text-embedding-ada-002
                    VectorSearchProfileName = "vector-profile"
                }
            },
            VectorSearch = new VectorSearch
            {
                Profiles =
                {
                    new VectorSearchProfile("vector-profile", "vector-config")
                },
                Algorithms =
                {
                    new HnswAlgorithmConfiguration("vector-config")
                }
            }
        };

        await _indexClient.CreateIndexAsync(index, cancellationToken);
        _logger.LogInformation("Index {IndexName} created successfully", _indexName);
    }

    public async Task<int> ProcessAndIndexPdfAsync(
        Stream pdfStream,
        string fileName,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Processing PDF: {FileName}", fileName);

        var documentId = Guid.NewGuid().ToString();
        var chunks = await ExtractAndChunkPdfAsync(pdfStream, fileName, documentId);

        _logger.LogInformation("Extracted {ChunkCount} chunks from {FileName}", chunks.Count, fileName);

        // Generate embeddings for all chunks
        var documents = new List<SearchDocument>();
        for (int i = 0; i < chunks.Count; i++)
        {
            var chunk = chunks[i];
            var embeddingResult = await _embeddingClient.GenerateEmbeddingAsync(
                chunk.Content,
                cancellationToken: cancellationToken);

            documents.Add(new SearchDocument
            {
                Id = $"{documentId}_{i}",
                Content = chunk.Content,
                Title = fileName,
                DocumentId = documentId,
                PageNumber = chunk.PageNumber,
                ContentVector = embeddingResult.Value.ToFloats().ToArray()
            });

            _logger.LogDebug("Generated embedding for chunk {ChunkIndex}", i);
        }

        // Upload to Azure AI Search
        await _searchClient.UploadDocumentsAsync(
            documents,
            cancellationToken: cancellationToken);

        _logger.LogInformation("Indexed {DocumentCount} chunks for {FileName}", documents.Count, fileName);

        return documents.Count;
    }

    private async Task<List<DocumentChunk>> ExtractAndChunkPdfAsync(
        Stream pdfStream,
        string fileName,
        string documentId)
    {
        var chunks = new List<DocumentChunk>();

        // Save stream to temporary file (Docnet requires file path)
        var tempFile = Path.GetTempFileName();
        try
        {
            using (var fileStream = File.Create(tempFile))
            {
                await pdfStream.CopyToAsync(fileStream);
            }

            using (var library = DocLib.Instance)
            using (var docReader = library.GetDocReader(tempFile, new PageDimensions(1080, 1920)))
            {
                for (int pageIndex = 0; pageIndex < docReader.GetPageCount(); pageIndex++)
                {
                    using (var pageReader = docReader.GetPageReader(pageIndex))
                    {
                        var text = pageReader.GetText();
                        if (string.IsNullOrWhiteSpace(text))
                            continue;

                        // Simple chunking by character count with overlap
                        const int chunkSize = 1000;
                        const int overlap = 200;

                        var pageChunks = ChunkText(text, chunkSize, overlap);

                        foreach (var chunkText in pageChunks)
                        {
                            chunks.Add(new DocumentChunk
                            {
                                Content = chunkText,
                                PageNumber = pageIndex + 1 // 1-based page numbering
                            });
                        }
                    }
                }
            }
        }
        finally
        {
            // Clean up temp file
            if (File.Exists(tempFile))
            {
                File.Delete(tempFile);
            }
        }

        return chunks;
    }

    private List<string> ChunkText(string text, int chunkSize, int overlap)
    {
        var chunks = new List<string>();
        var startIndex = 0;

        while (startIndex < text.Length)
        {
            var length = Math.Min(chunkSize, text.Length - startIndex);
            var chunk = text.Substring(startIndex, length);
            chunks.Add(chunk.Trim());

            startIndex += chunkSize - overlap;

            if (startIndex + overlap >= text.Length)
                break;
        }

        return chunks;
    }

    private class DocumentChunk
    {
        public string Content { get; set; } = string.Empty;
        public int PageNumber { get; set; }
    }
}
