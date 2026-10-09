using Azure;
using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using Backend.Models;
using OpenAI.Embeddings;

namespace Backend.Services;

public class RagService
{
    private readonly SearchClient _searchClient;
    private readonly EmbeddingClient _embeddingClient;
    private readonly ILogger<RagService> _logger;
    private readonly string _indexName;

    public RagService(
        SearchClient searchClient,
        EmbeddingClient embeddingClient,
        ILogger<RagService> logger,
        IConfiguration configuration)
    {
        _searchClient = searchClient;
        _embeddingClient = embeddingClient;
        _logger = logger;
        _indexName = configuration["AzureAISearch:IndexName"] ?? "pdf-documents";
    }

    public async Task<(string Context, List<Citation> Citations)> RetrieveContextAsync(
        string query,
        int topK = 5,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Retrieving context for query: {Query}", query);

            // Generate embedding for the query using EmbeddingClient
            var embeddingResult = await _embeddingClient.GenerateEmbeddingAsync(query, cancellationToken: cancellationToken);
            var embeddingArray = embeddingResult.Value.ToFloats().ToArray();

            // Create vector search query
            var vectorQuery = new VectorizedQuery(embeddingArray)
            {
                KNearestNeighborsCount = topK,
                Fields = { "contentVector" }
            };

            // Configure search options for hybrid search (vector + keyword)
            var searchOptions = new SearchOptions
            {
                Size = topK,
                Select = { "id", "content", "title", "documentId", "pageNumber" }
            };
            searchOptions.VectorSearch = new VectorSearchOptions();
            searchOptions.VectorSearch.Queries.Add(vectorQuery);

            // Execute search
            var searchResults = await _searchClient.SearchAsync<Models.SearchDocument>(
                query,
                searchOptions,
                cancellationToken);

            _logger.LogInformation("Search query executed. Total results count check...");
            
            var citations = new List<Citation>();
            var contextParts = new List<string>();
            int citationNumber = 1;
            int totalResults = 0;

            await foreach (var result in searchResults.Value.GetResultsAsync())
            {
                totalResults++;
                var doc = result.Document;
                var score = result.Score ?? 0;

                _logger.LogInformation("Found document {Number}: Title={Title}, Score={Score}", totalResults, doc.Title, score);

                // Accept all top K results from Azure AI Search
                // Hybrid search returns pre-ranked results, trust the ranking
                citations.Add(new Citation
                {
                    DocumentId = doc.DocumentId,
                    Title = doc.Title,
                    ChunkText = doc.Content,
                    RelevanceScore = (float)score,
                    PageNumber = doc.PageNumber
                });

                // Format context with citation number
                contextParts.Add($"[{citationNumber}] {doc.Content}\n(Source: {doc.Title}, Page {doc.PageNumber})");
                citationNumber++;
            }

            _logger.LogInformation("Search completed. Total results: {Total}, After filtering: {Filtered}", totalResults, citations.Count);

            var context = string.Join("\n\n", contextParts);
            _logger.LogInformation("Retrieved {Count} relevant documents", citations.Count);

            return (context, citations);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving context from Azure AI Search");
            throw;
        }
    }

    public async Task<ReadOnlyMemory<float>> GenerateEmbeddingAsync(
        string text,
        CancellationToken cancellationToken = default)
    {
        var embeddingResult = await _embeddingClient.GenerateEmbeddingAsync(text, cancellationToken: cancellationToken);
        return embeddingResult.Value.ToFloats();
    }
}
