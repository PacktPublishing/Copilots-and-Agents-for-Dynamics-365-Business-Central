using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.SignalR;
using System.Runtime.CompilerServices;

namespace Backend.Hubs;

public class ChatHub : Hub
{
    private readonly ChatService _chatService;
    private readonly AgentOrchestrationService _orchestrationService;
    private readonly ILogger<ChatHub> _logger;

    public ChatHub(
        ChatService chatService, 
        AgentOrchestrationService orchestrationService,
        ILogger<ChatHub> logger)
    {
        _chatService = chatService;
        _orchestrationService = orchestrationService;
        _logger = logger;
    }

    public async IAsyncEnumerable<StreamResponse> StreamChatResponse(
        string message,
        List<ChatMessage>? history,
        bool useSummarization,
        [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        var connectionId = Context.ConnectionId;
        _logger.LogInformation("Connection {ConnectionId} streaming chat for message: {Message}, Summarization: {UseSummarization}", 
            connectionId, message, useSummarization);

        if (useSummarization)
        {
            // Use sequential orchestration with summarization agent
            await foreach (var response in _orchestrationService.StreamSequentialResponseAsync(
                message,
                history,
                cancellationToken))
            {
                yield return response;
            }
        }
        else
        {
            // Use standard RAG without summarization
            await foreach (var response in _chatService.StreamChatResponseAsync(
                message,
                history,
                cancellationToken))
            {
                yield return response;
            }
        }

        _logger.LogInformation("Connection {ConnectionId} completed streaming", connectionId);
    }

    public override Task OnConnectedAsync()
    {
        _logger.LogInformation("Client connected: {ConnectionId}", Context.ConnectionId);
        return base.OnConnectedAsync();
    }

    public override Task OnDisconnectedAsync(Exception? exception)
    {
        if (exception != null)
        {
            _logger.LogWarning(exception, "Client disconnected with error: {ConnectionId}", 
                Context.ConnectionId);
        }
        else
        {
            _logger.LogInformation("Client disconnected: {ConnectionId}", Context.ConnectionId);
        }
        return base.OnDisconnectedAsync(exception);
    }
}
