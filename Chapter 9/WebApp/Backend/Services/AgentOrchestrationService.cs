using Backend.Models;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using System.Runtime.CompilerServices;
using BackendChatMessage = Backend.Models.ChatMessage;

namespace Backend.Services;

/// <summary>
/// Agent orchestration service using Microsoft Agent Framework.
/// Implements a sequential RAG → Summary workflow using ChatClientAgent.
/// </summary>
public class AgentOrchestrationService
{
    private readonly RagService _ragService;
    private readonly ILogger<AgentOrchestrationService> _logger;
    private readonly IChatClient _chatClient;

    public AgentOrchestrationService(
        IChatClient chatClient,
        RagService ragService,
        ILogger<AgentOrchestrationService> logger)
    {
        _chatClient = chatClient;
        _ragService = ragService;
        _logger = logger;
    }

    public async IAsyncEnumerable<StreamResponse> StreamSequentialResponseAsync(
        string userMessage,
        List<BackendChatMessage>? chatHistory = null,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Processing chat message with Agent Framework sequential orchestration: {Message}", userMessage);

        // Step 1: Retrieve relevant context from Azure AI Search
        (string context, List<Citation> citations) contextResult = (string.Empty, new List<Citation>());
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
            errorMessage = $"\n\n[Error retrieving context: {ex.Message}]";
        }

        if (errorMessage != null)
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

        string? orchestrationError = null;
        string finalSummary = string.Empty;

        try
        {
            // Step 2: Create RAG Agent using Microsoft Agent Framework
            _logger.LogInformation("Creating RAG Agent using ChatClientAgent");
            
            var ragAgent = new ChatClientAgent(
                chatClient: _chatClient,
                name: "RAGAgent",
                instructions: BuildRagAgentPrompt(contextResult.context));

            // Step 3: Run RAG Agent
            _logger.LogInformation("Running RAG Agent");
            var ragResponse = await ragAgent.RunAsync(userMessage, cancellationToken: cancellationToken);
            var ragText = ragResponse.Text ?? string.Empty;
            _logger.LogInformation("RAG Agent response received, length: {Length}", ragText.Length);

            // Step 4: Create Summary Agent using Microsoft Agent Framework
            _logger.LogInformation("Creating Summary Agent using ChatClientAgent");
            
            var summaryAgent = new ChatClientAgent(
                chatClient: _chatClient,
                name: "SummaryAgent",
                instructions: BuildSummarizationAgentPrompt());

            // Step 5: Run Summary Agent on RAG output
            _logger.LogInformation("Running Summary Agent");
            var summaryResponse = await summaryAgent.RunAsync(ragText, cancellationToken: cancellationToken);
            finalSummary = summaryResponse.Text ?? string.Empty;
            _logger.LogInformation("Summary Agent response received, length: {Length}", finalSummary.Length);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in Agent Framework sequential orchestration");
            orchestrationError = $"\n\n[Error in orchestration: {ex.Message}\nStack: {ex.StackTrace}]";
        }

        // Stream the final summary
        if (orchestrationError != null)
        {
            yield return new StreamResponse
            {
                Content = orchestrationError,
                Citations = null,
                IsComplete = true
            };
        }
        else if (!string.IsNullOrEmpty(finalSummary))
        {
            yield return new StreamResponse
            {
                Content = finalSummary,
                Citations = contextResult.citations,
                IsComplete = true
            };
        }
    }

    private string BuildRagAgentPrompt(string context)
    {
        if (string.IsNullOrWhiteSpace(context))
        {
            return @"You are a RAG (Retrieval Augmented Generation) agent. Answer questions based on your knowledge.
If you don't know the answer, say so. Be thorough and detailed in your answers.";
        }

        return $@"You are a RAG (Retrieval Augmented Generation) agent that answers questions based on provided document context.

IMPORTANT INSTRUCTIONS:
1. Answer the question using ONLY the information from the context below
2. When referencing information, include citation numbers like [1], [2], etc.
3. If the context doesn't contain enough information to answer, say so clearly
4. Be thorough and detailed in your answers - provide ALL relevant information from the context
5. Do not make up or infer information not present in the context

CONTEXT:
{context}

Now answer the user's question based on this context with as much detail as possible:";
    }

    private string BuildSummarizationAgentPrompt()
    {
        return @"You are a summarization agent. Your ONLY task is to create an EXTREMELY SHORT summary of the previous assistant's response.

STRICT REQUIREMENTS:
1. Maximum 4-5 lines of plain text (NO bullet points, NO lists, NO formatting)
2. Write as a single short paragraph
3. Include ONLY the most essential points with citation numbers [1], [2]
4. DO NOT copy the structure of the original text
5. DO NOT use your own knowledge - ONLY summarize what you see
6. DO NOT use phrases like 'Several new features' or 'Below is a breakdown'
7. Be direct and conversational
8. If the assistant's response is long, extract ONLY the top 2-3 key points

Example format: 'The Shopify Connector now supports X [1], enables Y [2], and includes Z [3]. These changes improve A and B.'

Summarize the previous message in 4-5 lines maximum:";
    }
}
