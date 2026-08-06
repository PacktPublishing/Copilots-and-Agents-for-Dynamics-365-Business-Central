namespace Backend.Models;

public class ChatMessage
{
    public string Role { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public List<Citation>? Citations { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

public class Citation
{
    public string DocumentId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string ChunkText { get; set; } = string.Empty;
    public string? SourceUrl { get; set; }
    public float RelevanceScore { get; set; }
    public int? PageNumber { get; set; }
}

public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
    public List<ChatMessage>? History { get; set; }
}

public class StreamResponse
{
    public string? Content { get; set; }
    public List<Citation>? Citations { get; set; }
    public bool IsComplete { get; set; }
}

public class SearchDocument
{
    [System.Text.Json.Serialization.JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;
    
    [System.Text.Json.Serialization.JsonPropertyName("content")]
    public string Content { get; set; } = string.Empty;
    
    [System.Text.Json.Serialization.JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;
    
    [System.Text.Json.Serialization.JsonPropertyName("documentId")]
    public string DocumentId { get; set; } = string.Empty;
    
    [System.Text.Json.Serialization.JsonPropertyName("pageNumber")]
    public int? PageNumber { get; set; }
    
    [System.Text.Json.Serialization.JsonPropertyName("contentVector")]
    public float[]? ContentVector { get; set; }
}
