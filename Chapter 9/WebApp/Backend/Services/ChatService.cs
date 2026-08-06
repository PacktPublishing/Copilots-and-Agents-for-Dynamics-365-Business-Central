using Backend.Models;
using OpenAI.Chat;
using System.Runtime.CompilerServices;
using BackendChatMessage = Backend.Models.ChatMessage;

namespace Backend.Services;

public class ChatService
{
    private readonly ChatClient _chatClient;
    private readonly RagService _ragService;
    private readonly ILogger<ChatService> _logger;

    public ChatService(
        ChatClient chatClient,
        RagService ragService,
        ILogger<ChatService> logger)
    {
        _chatClient = chatClient;
        _ragService = ragService;
        _logger = logger;
    }

    public async IAsyncEnumerable<StreamResponse> StreamChatResponseAsync(
        string userMessage,
        List<BackendChatMessage>? chatHistory = null,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Processing chat message: {Message}", userMessage);

        // Step 1: Retrieve relevant context from Azure AI Search
        (string context, List<Citation> citations) contextResult = (string.Empty, new List<Citation>());
        bool hasError = false;
        string? errorMessage = null;

        try
        {
            contextResult = await _ragService.RetrieveContextAsync(
                userMessage,
                topK: 5,
                cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving context from RAG service");
            hasError = true;
            errorMessage = $"\n\n[Error retrieving context: {ex.Message}]";
        }

        if (hasError)
        {
            yield return new StreamResponse
            {
                Content = errorMessage,
                Citations = null,
                IsComplete = true
            };
            yield break;
        }

        _logger.LogInformation("Retrieved {CitationCount} citations", contextResult.citations.Count);

        // Step 2: Build chat messages with RAG context
        var messages = new List<OpenAI.Chat.ChatMessage>();

        // Add system prompt with RAG instructions
        var systemPrompt = BuildSystemPrompt(contextResult.context);
        messages.Add(new SystemChatMessage(systemPrompt));

        // Add previous conversation history if provided
        if (chatHistory != null)
        {
            foreach (var msg in chatHistory.TakeLast(5)) // Keep last 5 messages for context
            {
                if (msg.Role.ToLower() == "user")
                    messages.Add(new UserChatMessage(msg.Content));
                else if (msg.Role.ToLower() == "assistant")
                    messages.Add(new AssistantChatMessage(msg.Content));
            }
        }

        // Add current user message
        messages.Add(new UserChatMessage(userMessage));

        // Step 3: Stream response from LLM using ChatClient
        // Note: We must avoid yield in catch blocks due to C# language limitation
        IAsyncEnumerator<StreamingChatCompletionUpdate>? enumerator = null;
        string? initError = null;
        
        try
        {
            var streamingResponse = _chatClient.CompleteChatStreamingAsync(messages, cancellationToken: cancellationToken);
            enumerator = streamingResponse.GetAsyncEnumerator(cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error initializing chat streaming");
            initError = $"\n\n[Error: {ex.Message}]";
        }

        if (initError != null)
        {
            yield return new StreamResponse
            {
                Content = initError,
                Citations = null,
                IsComplete = true
            };
            yield break;
        }

        // Stream the chunks outside of try-catch
        string? streamError = null;
        while (true)
        {
            StreamingChatCompletionUpdate? chunk = null;
            bool hasMore = false;
            
            try
            {
                hasMore = await enumerator!.MoveNextAsync();
                if (hasMore)
                {
                    chunk = enumerator.Current;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error streaming chat response");
                streamError = $"\n\n[Error: {ex.Message}]";
            }

            if (streamError != null)
            {
                yield return new StreamResponse
                {
                    Content = streamError,
                    Citations = null,
                    IsComplete = true
                };
                yield break;
            }

            if (!hasMore) break;

            if (chunk != null)
            {
                foreach (var contentPart in chunk.ContentUpdate)
                {
                    var content = contentPart.Text;
                    if (!string.IsNullOrEmpty(content))
                    {
                        yield return new StreamResponse
                        {
                            Content = content,
                            Citations = null,
                            IsComplete = false
                        };
                    }
                }
            }
        }

        // Step 4: Send citations at the end
        yield return new StreamResponse
        {
            Content = null,
            Citations = contextResult.citations,
            IsComplete = true
        };

        _logger.LogInformation("Completed streaming response");
    }

    private string BuildSystemPrompt(string context)
    {
        if (string.IsNullOrWhiteSpace(context))
        {
            return @"You are a helpful AI assistant. Answer questions based on your knowledge.
If you don't know the answer, say so. Be concise and accurate.";
        }

        return $@"You are a helpful AI assistant that answers questions based on the provided document context.

IMPORTANT INSTRUCTIONS:
1. Answer the question using ONLY the information from the context below
2. When referencing information, include citation numbers like [1], [2], etc.
3. If the context doesn't contain enough information to answer, say so clearly
4. Be concise but thorough in your answers
5. Do not make up or infer information not present in the context

CONTEXT:
{context}

Now answer the user's question based on this context:";
    }

    public async Task<string> GetNonStreamingResponseAsync(
        string userMessage,
        List<BackendChatMessage>? chatHistory = null,
        CancellationToken cancellationToken = default)
    {
        var fullResponse = string.Empty;

        await foreach (var chunk in StreamChatResponseAsync(userMessage, chatHistory, cancellationToken))
        {
            if (chunk.Content != null)
            {
                fullResponse += chunk.Content;
            }
        }

        return fullResponse;
    }
}
