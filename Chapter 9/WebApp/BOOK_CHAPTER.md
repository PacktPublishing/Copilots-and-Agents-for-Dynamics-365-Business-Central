# Building an AI-Powered RAG Chat Application with Sequential Agent Orchestration

## Introduction

In this chapter, you'll learn how to build a complete AI-powered chat application that can answer questions about your PDF documents. This is called a **RAG (Retrieval-Augmented Generation)** application - it retrieves relevant information from your documents and uses AI to generate accurate answers.

### What You'll Build

By the end of this chapter, you'll have a working application that:
- Accepts PDF document uploads and indexes them for search
- Allows users to ask questions about the uploaded documents
- Uses AI to find relevant information and generate accurate responses
- Optionally summarizes long responses into concise answers using a two-agent workflow

### What is Sequential Agent Orchestration?

The key feature of this application is **sequential agent orchestration** using Microsoft Agent Framework. This means two AI "agents" work together in sequence:

1. **RAG Agent**: Retrieves relevant document chunks and generates a detailed, comprehensive answer
2. **Summary Agent**: Takes the detailed answer and condenses it into 4-5 lines

Users can toggle between getting full detailed answers or concise summaries.

### Technologies Overview

Don't worry if these terms are new to you - we'll explain everything as we build:

- **Backend**: ASP.NET Core 10.0 (C#) - handles the server-side logic
- **Frontend**: React + TypeScript - provides the user interface
- **AI Services**: Azure OpenAI - powers the chat and text understanding
- **Search**: Azure AI Search - finds relevant document sections
- **Real-time Communication**: SignalR - streams AI responses to the browser

## Technologies Used (Detailed)

### Backend Technologies

1. **ASP.NET Core 10.0**
   - Modern cross-platform framework for building web APIs
   - Provides built-in dependency injection and middleware support
   - Excellent performance and scalability

2. **OpenAI 2.14.0**
   - Stable OpenAI SDK for .NET, configured for the Azure OpenAI v1 API
   - Direct access to ChatClient and EmbeddingClient
   - Native support for streaming responses
   - No abstraction overhead for Azure OpenAI operations

3. **Microsoft Agent Framework 1.24.0 (Stable)**
   - `Microsoft.Agents.AI 1.24.0`
   - `Microsoft.Agents.AI.OpenAI 1.24.0`
   - `Microsoft.Agents.AI.Workflows 1.24.0`
   - Framework for building and orchestrating AI agents
   - Enables sequential workflow patterns for multi-agent scenarios

4. **Microsoft.Extensions.AI 10.10.0**
   - Unified AI abstraction layer for .NET
   - Provides common interfaces (IChatClient, IEmbeddingGenerator) across AI providers
   - Enables provider-agnostic agent orchestration

5. **Microsoft.Extensions.AI.OpenAI 10.10.1**
   - Adapter package that bridges the OpenAI SDK to IChatClient interface
   - Provides `AsIChatClient()` extension method for ChatClient
   - Enables use of Azure OpenAI with frameworks expecting IChatClient

6. **Azure AI Search**
   - Cloud-based search service for vector and full-text search
   - Provides semantic search capabilities using embeddings
   - Enables efficient retrieval of relevant document chunks

7. **Azure OpenAI Service**
   - Provides access to GPT models for chat completion
   - Text embedding models (text-embedding-ada-002) for semantic search
   - Enterprise-grade security and compliance

8. **SignalR**
   - Real-time communication library for ASP.NET Core
   - Enables WebSocket-based streaming of AI responses
   - Provides automatic fallback to long polling if WebSockets unavailable

9. **Docnet.Core 2.6.0**
   - High-performance library for PDF text extraction
   - Handles various PDF formats and encodings
   - Provides page-level text extraction capabilities

### Frontend Technologies

1. **React 18**
   - Modern JavaScript library for building user interfaces
   - Component-based architecture for reusability
   - Efficient virtual DOM for performance

2. **TypeScript**
   - Strongly-typed superset of JavaScript
   - Provides compile-time type checking
   - Enhances code maintainability and IDE support

3. **Vite**
   - Fast build tool and development server
   - Hot module replacement for instant feedback
   - Optimized production builds

4. **Fluent UI React Components**
   - Microsoft's modern UI component library
   - Accessible and responsive components
   - Consistent design language aligned with Microsoft 365

5. **SignalR Client (@microsoft/signalr)**
   - JavaScript client for SignalR connections
   - Handles WebSocket communication with the backend
   - Automatic reconnection and error handling

## Application Architecture

### High-Level Architecture

The application follows a modern three-tier architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend Layer                          │
│  (React + TypeScript + Fluent UI + SignalR Client)         │
└────────────────────┬────────────────────────────────────────┘
                     │ WebSocket (SignalR)
                     │ REST API
┌────────────────────▼────────────────────────────────────────┐
│                     Backend Layer                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          SignalR Hub (ChatHub)                       │   │
│  │  - WebSocket endpoint for real-time communication   │   │
│  │  - Routes requests to appropriate services          │   │
│  └────────┬────────────────────────────┬─────────────────┘  │
│           │                            │                     │
│  ┌────────▼──────────┐      ┌─────────▼─────────────────┐  │
│  │   ChatService     │      │ AgentOrchestrationService │  │
│  │ (Standard RAG)    │      │  (Sequential Workflow)    │  │
│  └────────┬──────────┘      └──────────┬────────────────┘  │
│           │                             │                    │
│           └──────────┬──────────────────┘                   │
│                      │                                       │
│           ┌──────────▼────────────┐                         │
│           │     RagService         │                         │
│           │  - Vector search       │                         │
│           │  - Context retrieval   │                         │
│           └──────────┬─────────────┘                        │
│                      │                                       │
│  ┌───────────────────▼─────────────────────────────────┐   │
│  │     OpenAI SDK / Microsoft.Extensions.AI            │   │
│  │  - IChatClient (via AsIChatClient() adapter)        │   │
│  │  - EmbeddingClient for vector generation            │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Vector Search / Document Upload
┌────────────────────▼────────────────────────────────────────┐
│                   Data Layer                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Azure AI Search                         │   │
│  │  - Vector index for document embeddings             │   │
│  │  - Full-text search capabilities                    │   │
│  │  - Stores document chunks with metadata             │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Backend Architecture Deep Dive

#### 1. SignalR Hub Layer

**ChatHub.cs** serves as the entry point for client connections:

```csharp
public class ChatHub : Hub
{
    public async IAsyncEnumerable<StreamResponse> StreamChatResponse(
        string message, 
        List<ChatMessage>? history, 
        bool useSummarization)
    {
        // Route to appropriate service based on summarization flag
        if (useSummarization)
        {
            await foreach (var response in _orchestrationService
                .StreamSequentialResponseAsync(message, history))
            {
                yield return response;
            }
        }
        else
        {
            await foreach (var response in _chatService
                .StreamChatResponseAsync(message, history))
            {
                yield return response;
            }
        }
    }
}
```

**Responsibilities:**
- Manages WebSocket connections from clients
- Accepts user messages and chat history
- Routes requests based on summarization flag
- Streams responses back to clients in real-time
- Handles connection lifecycle (connect, disconnect, errors)

#### 2. Service Layer

##### **RagService.cs** - Core RAG Implementation

This service handles the retrieval-augmented generation logic using hybrid search (vector + keyword):

```csharp
using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using Backend.Models;
using OpenAI.Embeddings;

public class RagService
{
    private readonly SearchClient _searchClient;
    private readonly EmbeddingClient _embeddingClient;
    private readonly ILogger<RagService> _logger;

    public RagService(
        SearchClient searchClient,
        EmbeddingClient embeddingClient,
        ILogger<RagService> logger)
    {
        _searchClient = searchClient;
        _embeddingClient = embeddingClient;
        _logger = logger;
    }

    public async Task<(string Context, List<Citation> Citations)> RetrieveContextAsync(
        string query,
        int topK = 5,
        CancellationToken cancellationToken = default)
    {
        // 1. Generate embedding for the query using EmbeddingClient
        var embeddingResult = await _embeddingClient.GenerateEmbeddingAsync(
            query, 
            cancellationToken: cancellationToken);
        var embeddingArray = embeddingResult.Value.ToFloats().ToArray();

        // 2. Create vector search query
        var vectorQuery = new VectorizedQuery(embeddingArray)
        {
            KNearestNeighborsCount = topK,
            Fields = { "contentVector" }
        };

        // 3. Configure search options for hybrid search
        var searchOptions = new SearchOptions { Size = topK };
        searchOptions.VectorSearch = new VectorSearchOptions();
        searchOptions.VectorSearch.Queries.Add(vectorQuery);

        // 4. Execute search
        var searchResults = await _searchClient.SearchAsync<SearchDocument>(
            query,  // Include text for hybrid search
            searchOptions,
            cancellationToken);

        // 5. Build context and citations from results
        var citations = new List<Citation>();
        var contextParts = new List<string>();
        int citationNumber = 1;

        await foreach (var result in searchResults.Value.GetResultsAsync())
        {
            var doc = result.Document;
            citations.Add(new Citation
            {
                DocumentId = doc.DocumentId,
                Title = doc.Title,
                ChunkText = doc.Content,
                RelevanceScore = (float)(result.Score ?? 0),
                PageNumber = doc.PageNumber
            });

            contextParts.Add($"[{citationNumber}] {doc.Content}\n(Source: {doc.Title}, Page {doc.PageNumber})");
            citationNumber++;
        }

        return (string.Join("\n\n", contextParts), citations);
    }
}
```

**Key Responsibilities:**
- Query vectorization using Azure OpenAI `EmbeddingClient`
- Hybrid search (vector + keyword) against document index
- Context assembly from top-K retrieved chunks
- Citation generation with document references
- Relevance scoring from Azure AI Search

##### **ChatService.cs** - Standard RAG Chat

Provides detailed, comprehensive responses without summarization. Uses `ChatClient` from the OpenAI SDK against Azure OpenAI:

```csharp
using Backend.Models;
using OpenAI.Chat;
using System.Runtime.CompilerServices;

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
        List<ChatMessage>? chatHistory,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        // 1. Retrieve relevant context from RAG service
        var (context, citations) = await _ragService.RetrieveContextAsync(
            userMessage, topK: 5, cancellationToken);
        
        // 2. Build chat messages with RAG context
        var messages = new List<OpenAI.Chat.ChatMessage>();
        messages.Add(new SystemChatMessage(BuildSystemPrompt(context)));
        
        // Add previous conversation history
        if (chatHistory != null)
        {
            foreach (var msg in chatHistory.TakeLast(5))
            {
                if (msg.Role.ToLower() == "user")
                    messages.Add(new UserChatMessage(msg.Content));
                else if (msg.Role.ToLower() == "assistant")
                    messages.Add(new AssistantChatMessage(msg.Content));
            }
        }
        messages.Add(new UserChatMessage(userMessage));
        
        // 3. Stream response from Azure OpenAI via ChatClient
        await foreach (var chunk in _chatClient.CompleteChatStreamingAsync(
            messages, cancellationToken: cancellationToken))
        {
            foreach (var part in chunk.ContentUpdate)
            {
                if (!string.IsNullOrEmpty(part.Text))
                {
                    yield return new StreamResponse 
                    { 
                        Content = part.Text,
                        IsComplete = false 
                    };
                }
            }
        }
        
        // 4. Send citations at the end
        yield return new StreamResponse
        {
            Citations = citations,
            IsComplete = true
        };
    }
}
```

**System Prompt Strategy:**
```
You are a helpful AI assistant that answers questions based on the 
provided document context.

IMPORTANT INSTRUCTIONS:
1. Answer using ONLY the information from the context
2. Include citation numbers [1], [2] when referencing information
3. If context doesn't contain enough information, say so clearly
4. Be concise but thorough in your answers
5. Do not make up or infer information not present in the context

CONTEXT:
{retrieved_context}

Now answer the user's question based on this context:
```

##### **AgentOrchestrationService.cs** - Sequential Agent Workflow

Implements the two-agent sequential orchestration for summarization using **Microsoft Agent Framework's `ChatClientAgent`**:

```csharp
using Backend.Models;
using Microsoft.Agents.AI;  // Microsoft Agent Framework
using Microsoft.Extensions.AI;
using System.Runtime.CompilerServices;

public class AgentOrchestrationService
{
    private readonly IChatClient _chatClient;
    private readonly RagService _ragService;
    private readonly ILogger<AgentOrchestrationService> _logger;

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
        List<ChatMessage>? chatHistory = null,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        // Step 1: Retrieve context from Azure AI Search
        var (context, citations) = await _ragService.RetrieveContextAsync(
            userMessage, topK: 5, cancellationToken);
        
        // Step 2: Create RAG Agent using Microsoft Agent Framework
        var ragAgent = new ChatClientAgent(
            chatClient: _chatClient,
            name: "RAGAgent",
            instructions: BuildRagAgentPrompt(context));

        // Step 3: Run RAG Agent to get detailed response
        var ragResponse = await ragAgent.RunAsync(
            userMessage, 
            cancellationToken: cancellationToken);
        var ragText = ragResponse.Text ?? string.Empty;
        
        // Step 4: Create Summary Agent using Microsoft Agent Framework
        var summaryAgent = new ChatClientAgent(
            chatClient: _chatClient,
            name: "SummaryAgent",
            instructions: BuildSummarizationAgentPrompt());

        // Step 5: Run Summary Agent on RAG output
        var summaryResponse = await summaryAgent.RunAsync(
            ragText, 
            cancellationToken: cancellationToken);
        var finalSummary = summaryResponse.Text ?? string.Empty;
        
        // Step 6: Return summary with citations
        yield return new StreamResponse
        {
            Content = finalSummary,
            Citations = citations,
            IsComplete = true
        };
    }
}
```

**Key Point:** The application uses Microsoft Agent Framework's `ChatClientAgent` class to create specialized agents. Each agent is configured with:
- `chatClient`: The IChatClient for LLM communication
- `name`: A unique identifier for the agent
- `instructions`: The system prompt defining the agent's behavior

**RAG Agent Prompt:**
```
You are a RAG (Retrieval Augmented Generation) agent that answers 
questions based on provided document context.

IMPORTANT INSTRUCTIONS:
1. Answer using ONLY the information from the context below
2. Include citation numbers like [1], [2] when referencing information
3. If context doesn't contain enough information, say so clearly
4. Be thorough and detailed - provide ALL relevant information
5. Do not make up or infer information not present in the context

CONTEXT:
{retrieved_context}

Now answer the user's question with as much detail as possible:
```

**Summarization Agent Prompt:**
```
You are a summarization agent. Your ONLY task is to create an 
EXTREMELY SHORT summary of the previous assistant's response.

STRICT REQUIREMENTS:
1. Maximum 4-5 lines of plain text (NO bullet points, NO lists)
2. Write as a single short paragraph
3. Include ONLY the most essential points with citations [1], [2]
4. DO NOT copy the structure of the original text
5. DO NOT use your own knowledge - ONLY summarize what you see
6. Be direct and conversational

Example format: 'The Shopify Connector now supports X [1], 
enables Y [2], and includes Z [3]. These changes improve A and B.'

Summarize the previous message in 4-5 lines maximum:
```

#### 3. Document Processing Pipeline

The application uses a **DocumentController** for the API endpoint and a **DocumentProcessor** service for the heavy lifting.

**DocumentController.cs** - API endpoint for PDF uploads:

```csharp
using Backend.Services;
using Microsoft.AspNetCore.Mvc;

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
        // Validate file
        if (file == null || file.Length == 0)
            return BadRequest(new { error = "No file uploaded" });

        if (!file.FileName.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { error = "Only PDF files are supported" });

        // Ensure index exists in Azure AI Search
        await _documentProcessor.EnsureIndexExistsAsync(cancellationToken);

        // Process and index the PDF
        using var stream = file.OpenReadStream();
        var chunkCount = await _documentProcessor.ProcessAndIndexPdfAsync(
            stream, file.FileName, cancellationToken);

        return Ok(new
        {
            message = "Document uploaded and indexed successfully",
            fileName = file.FileName,
            chunksIndexed = chunkCount
        });
    }
}
```

**DocumentProcessor.cs** - Handles PDF extraction and indexing:

```csharp
using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Indexes.Models;
using Docnet.Core;
using OpenAI.Embeddings;

public class DocumentProcessor
{
    private readonly SearchIndexClient _indexClient;
    private readonly SearchClient _searchClient;
    private readonly EmbeddingClient _embeddingClient;
    private readonly string _indexName;

    // Constructor receives dependencies via DI
    public DocumentProcessor(
        SearchIndexClient indexClient,
        SearchClient searchClient,
        EmbeddingClient embeddingClient,
        IConfiguration configuration)
    {
        _indexClient = indexClient;
        _searchClient = searchClient;
        _embeddingClient = embeddingClient;
        _indexName = configuration["AzureAISearch:IndexName"] ?? "pdf-documents";
    }

    public async Task EnsureIndexExistsAsync(CancellationToken cancellationToken)
    {
        // Check if index exists, create if not
        try
        {
            await _indexClient.GetIndexAsync(_indexName, cancellationToken);
        }
        catch (Azure.RequestFailedException ex) when (ex.Status == 404)
        {
            // Index doesn't exist, create it
            var index = new SearchIndex(_indexName)
            {
                Fields = {
                    new SimpleField("id", SearchFieldDataType.String) { IsKey = true },
                    new SearchableField("content"),
                    new SearchableField("title") { IsFilterable = true },
                    new SimpleField("documentId", SearchFieldDataType.String) { IsFilterable = true },
                    new SimpleField("pageNumber", SearchFieldDataType.Int32) { IsFilterable = true },
                    new SearchField("contentVector", SearchFieldDataType.Collection(SearchFieldDataType.Single))
                    {
                        IsSearchable = true,
                        VectorSearchDimensions = 1536,  // text-embedding-ada-002 dimensions
                        VectorSearchProfileName = "vector-profile"
                    }
                },
                VectorSearch = new VectorSearch
                {
                    Profiles = { new VectorSearchProfile("vector-profile", "vector-config") },
                    Algorithms = { new HnswAlgorithmConfiguration("vector-config") }
                }
            };
            await _indexClient.CreateIndexAsync(index, cancellationToken);
        }
    }

    public async Task<int> ProcessAndIndexPdfAsync(
        Stream pdfStream, string fileName, CancellationToken cancellationToken)
    {
        var documentId = Guid.NewGuid().ToString();
        
        // Extract text from PDF using Docnet
        var chunks = ExtractTextFromPdf(pdfStream, fileName, documentId);
        
        // Generate embeddings and create search documents
        var documents = new List<SearchDocument>();
        for (int i = 0; i < chunks.Count; i++)
        {
            var embedding = await _embeddingClient.GenerateEmbeddingAsync(
                chunks[i].Content, cancellationToken: cancellationToken);
                
            documents.Add(new SearchDocument
            {
                Id = $"{documentId}_{i}",
                Content = chunks[i].Content,
                Title = fileName,
                DocumentId = documentId,
                PageNumber = chunks[i].PageNumber,
                ContentVector = embedding.Value.ToFloats().ToArray()
            });
        }
        
        // Upload to Azure AI Search
        await _searchClient.UploadDocumentsAsync(documents, cancellationToken: cancellationToken);
        
        return documents.Count;
    }
}
```

**Text Chunking Strategy:**
- Fixed-size chunks with overlap for context preservation
- Typical chunk size: 500-1000 characters
- Overlap: 100-200 characters
- Preserves paragraph boundaries where possible
- Maintains metadata (source file, page number)

### Frontend Architecture

#### Component Hierarchy

```
App
└── ChatInterface
    ├── Header (Title, Subtitle, Summarization Toggle)
    ├── DocumentUploader
    │   └── File Input + Upload Button
    ├── MessageList
    │   └── MessageBubble (for each message)
    │       ├── User Message
    │       ├── Assistant Message
    │       └── Citations Panel
    └── MessageInput
        └── Text Input + Send Button
```

#### Key Components

**ChatInterface.tsx** - Main orchestrator:
```typescript
export const ChatInterface: React.FC = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isStreaming, setIsStreaming] = useState(false);
  const [useSummarization, setUseSummarization] = useState(false);
  const currentMessageRef = useRef<ChatMessage | null>(null);

  const handleSendMessage = async (messageText: string) => {
    // Add user message to UI
    setMessages(prev => [...prev, { 
      role: 'user', 
      content: messageText 
    }]);
    
    // Initialize empty assistant message
    currentMessageRef.current = {
      role: 'assistant',
      content: '',
      timestamp: new Date()
    };
    setMessages(prev => [...prev, currentMessageRef.current!]);
    
    // Stream response from backend
    await chatService.streamChatResponse(
      messageText,
      messages.slice(-10), // Last 10 messages as context
      useSummarization,
      (response: StreamResponse) => {
        // Update message content as chunks arrive
        if (response.content) {
          currentMessageRef.current!.content += response.content;
        }
        
        // Add citations when complete
        if (response.citations) {
          currentMessageRef.current!.citations = response.citations;
        }
        
        // Trigger re-render
        setMessages(prev => {
          const newMessages = [...prev];
          newMessages[newMessages.length - 1] = {...currentMessageRef.current!};
          return newMessages;
        });
      }
    );
  };
  
  return (
    <div>
      <Header>
        <Title>RAG Chat - PDF Q&A</Title>
        <Switch 
          checked={useSummarization}
          onChange={setUseSummarization}
          label="Summarize Responses"
        />
      </Header>
      <DocumentUploader />
      <MessageList messages={messages} />
      <MessageInput onSend={handleSendMessage} />
    </div>
  );
};
```

**chatService.ts** - SignalR client wrapper:
```typescript
class ChatService {
  private connection: HubConnection;
  
  async connect() {
    this.connection = new HubConnectionBuilder()
      .withUrl('http://localhost:5000/chatHub')
      .withAutomaticReconnect()
      .build();
    
    await this.connection.start();
  }
  
  async streamChatResponse(
    message: string,
    history: ChatMessage[] | null,
    useSummarization: boolean,
    onChunk: (response: StreamResponse) => void,
    onError: (error: Error) => void
  ) {
    try {
      const stream = this.connection.stream(
        'StreamChatResponse',
        message,
        history,
        useSummarization
      );
      
      for await (const response of stream) {
        onChunk(response);
      }
    } catch (error) {
      onError(error as Error);
    }
  }
}
```

## Agent Workflow and Framework

### Sequential Agent Orchestration Pattern

The application implements a sequential agent workflow where two specialized agents work in tandem using **Microsoft Agent Framework's `ChatClientAgent`**:

```
User Query
    │
    ▼
┌─────────────────────────────────────┐
│   1. Context Retrieval              │
│   (Azure AI Search)                 │
│   - Hybrid search (vector+keyword)  │
│   - Top-K relevant chunks           │
└────────────┬────────────────────────┘
             │ Context + Citations
             ▼
┌─────────────────────────────────────┐
│   2. RAG Agent (ChatClientAgent)    │
│   Role: Detail-oriented responder   │
│   - Name: "RAGAgent"                │
│   - Instructions: RAG prompt        │
│   - Output: Comprehensive answer    │
└────────────┬────────────────────────┘
             │ Detailed Response
             ▼
┌─────────────────────────────────────┐
│   3. Summary Agent (ChatClientAgent)│
│   Role: Concise summarizer          │
│   - Name: "SummaryAgent"            │
│   - Instructions: Summary prompt    │
│   - Output: 4-5 line summary        │
└────────────┬────────────────────────┘
             │ Concise Summary
             ▼
         User Interface
    (with original citations)
```

### Using Microsoft Agent Framework

The application uses `ChatClientAgent` from `Microsoft.Agents.AI` to create specialized agents. This approach provides:

1. **Named Agents**: Each agent has a unique identity for logging and debugging
2. **Instruction-Based Configuration**: System prompts are set via the `instructions` parameter
3. **IChatClient Integration**: Works seamlessly with Microsoft.Extensions.AI abstractions
4. **Simple API**: Just call `agent.RunAsync(input)` to execute

**Implementation using ChatClientAgent:**

```csharp
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;

// Create RAG Agent with specific instructions
var ragAgent = new ChatClientAgent(
    chatClient: _chatClient,          // IChatClient from DI
    name: "RAGAgent",                 // Unique agent name
    instructions: BuildRagAgentPrompt(context));  // System prompt

// Run the agent
var ragResponse = await ragAgent.RunAsync(userMessage);
string detailedAnswer = ragResponse.Text;

// Create Summary Agent
var summaryAgent = new ChatClientAgent(
    chatClient: _chatClient,
    name: "SummaryAgent",
    instructions: BuildSummarizationAgentPrompt());

// Run summary agent on RAG output
var summaryResponse = await summaryAgent.RunAsync(detailedAnswer);
string conciseSummary = summaryResponse.Text;
```

**Benefits of Using ChatClientAgent:**
1. **Named Agents**: Each agent has identity for tracing and debugging
2. **Clean Abstraction**: No need to manually manage chat message lists
3. **Framework Integration**: Works with Microsoft Agent Framework ecosystem
4. **Simple API**: Single `RunAsync()` method for execution
5. **Error Handling**: Built-in exception handling

### Agent Framework Components Used

The application combines Microsoft Agent Framework with Microsoft.Extensions.AI:

1. **ChatClientAgent** (Microsoft.Agents.AI): Creates named agents with instructions
2. **IChatClient Interface**: Unified interface for chat completion across providers
3. **ChatClient** (OpenAI): Direct SDK for streaming responses from Azure OpenAI
4. **EmbeddingClient** (OpenAI): Generates embeddings for vector search
5. **AsIChatClient() Extension**: Bridges the OpenAI ChatClient to IChatClient

## Step-by-Step Implementation Guide

This guide assumes you are starting from scratch. We'll explain each step in detail.

### Prerequisites

Before you begin, make sure you have:

1. **Development Environment:**
   - **Visual Studio 2026** (Community edition is free) OR **VS Code** with C# Dev Kit extension
   - **Node.js 18+** - Download from https://nodejs.org
   - **.NET 10 SDK** - Download from https://dotnet.microsoft.com/download/dotnet/10.0

2. **Azure Account & Resources:**
   - An Azure subscription (free tier available at https://azure.microsoft.com/free)
   - Azure OpenAI Service with:
     - A GPT-4 or GPT-3.5-turbo deployment (for chat)
     - A text-embedding-ada-002 deployment (for embeddings)
   - Azure AI Search service (free tier available)

3. **API Keys and Endpoints** (you'll get these from Azure Portal):
   - Azure OpenAI endpoint (looks like: `https://your-resource.openai.azure.com/`)
   - Azure OpenAI API key
   - Azure AI Search endpoint (looks like: `https://your-search.search.windows.net`)
   - Azure AI Search admin key

> **Tip:** Write down your endpoints and keys in a safe place - you'll need them later!

### Step 1: Create the Backend Project

Open a terminal (Command Prompt, PowerShell, or Terminal on Mac) and run these commands:

```bash
# 1. Create a new folder for your project and navigate to it
mkdir RagChatApp
cd RagChatApp

# 2. Create a .NET solution file (this organizes multiple projects)
dotnet new sln -n RagChatApp

# 3. Create a new ASP.NET Core Web API project called "Backend"
dotnet new webapi -n Backend --framework net10.0

# 4. Add the Backend project to the solution
dotnet sln add Backend/Backend.csproj

# 5. Navigate into the Backend folder
cd Backend

# 6. Add all the NuGet packages we need (these are libraries that add functionality)
dotnet add package OpenAI --version 2.14.0
dotnet add package Microsoft.Extensions.AI.OpenAI --version 10.10.1
dotnet add package Azure.Search.Documents --version 11.5.1
dotnet add package Docnet.Core --version 2.6.0
dotnet add package Microsoft.Agents.AI --version 1.24.0
dotnet add package Microsoft.Agents.AI.OpenAI --version 1.24.0
dotnet add package Microsoft.Agents.AI.Workflows --version 1.24.0
dotnet add package Serilog.AspNetCore --version 10.0.0
```

**What each package does:**
- `OpenAI`: Connects to Azure OpenAI's v1 API for chat and embeddings
- `Microsoft.Extensions.AI.OpenAI`: Provides the `IChatClient` interface for agent orchestration
- `Azure.Search.Documents`: Connects to Azure AI Search for document retrieval
- `Docnet.Core`: Extracts text from PDF files
- `Microsoft.Agents.AI`: Microsoft Agent Framework for creating AI agents
- `Serilog.AspNetCore`: Better logging for debugging

### Step 2: Configure Application Settings

Create `appsettings.json`:

```json
{
  "AzureOpenAI": {
    "Endpoint": "https://your-resource.openai.azure.com/",
    "ApiKey": "your-api-key",
    "ChatDeploymentName": "gpt-4",
    "EmbeddingDeploymentName": "text-embedding-ada-002"
  },
  "AzureAISearch": {
    "Endpoint": "https://your-search-service.search.windows.net",
    "ApiKey": "your-search-admin-key",
    "IndexName": "pdf-documents"
  },
  "CORS": {
    "AllowedOrigins": [
      "http://localhost:5173",
      "http://localhost:5174"
    ]
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft.AspNetCore": "Warning"
      }
    }
  },
  "AllowedHosts": "*"
}
```

### Step 3: Create Models

Create `Models/ChatModels.cs` (all models in one file for simplicity):

```csharp
namespace Backend.Models;

// Message exchanged with the frontend
public class ChatMessage
{
    public string Role { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public List<Citation>? Citations { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

// Citation referencing a source document
public class Citation
{
    public string DocumentId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string ChunkText { get; set; } = string.Empty;
    public string? SourceUrl { get; set; }
    public float RelevanceScore { get; set; }
    public int? PageNumber { get; set; }
}

// Request payload for chat
public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
    public List<ChatMessage>? History { get; set; }
}

// Response streamed back to frontend
public class StreamResponse
{
    public string? Content { get; set; }
    public List<Citation>? Citations { get; set; }
    public bool IsComplete { get; set; }
}

// Document stored in Azure AI Search index
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
```

> **Note:** The `SearchDocument` class uses `JsonPropertyName` attributes to match the Azure AI Search index field names exactly.

### Step 4: Implement RagService

Create `Services/RagService.cs`:

```csharp
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

    public RagService(
        SearchClient searchClient,
        EmbeddingClient embeddingClient,
        ILogger<RagService> logger)
    {
        _searchClient = searchClient;
        _embeddingClient = embeddingClient;
        _logger = logger;
    }

    public async Task<(string context, List<Citation> citations)> RetrieveContextAsync(
        string query,
        int topK = 5,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Retrieving context for query: {Query}", query);

        // Generate embedding for the query using EmbeddingClient
        var embeddingResponse = await _embeddingClient.GenerateEmbeddingAsync(
            query, 
            cancellationToken: cancellationToken
        );
        var queryEmbedding = embeddingResponse.Value.ToFloats().ToArray();

        // Perform vector search
        var searchOptions = new SearchOptions
        {
            VectorSearch = new()
            {
                Queries = { 
                    new VectorizedQuery(queryEmbedding)
                    {
                        KNearestNeighborsCount = topK,
                        Fields = { "contentVector" }
                    }
                }
            },
            Size = topK,
            Select = { "id", "content", "sourceFile", "pageNumber" }
        };

        SearchResults<DocumentChunk> results;
        try
        {
            results = await _searchClient.SearchAsync<DocumentChunk>(
                searchText: null,
                searchOptions,
                cancellationToken
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error performing vector search");
            throw;
        }

        // Build context and citations
        var contextBuilder = new StringBuilder();
        var citations = new List<Citation>();
        int citationNumber = 1;

        await foreach (var result in results.GetResultsAsync())
        {
            var chunk = result.Document;
            
            contextBuilder.AppendLine($"[{citationNumber}]");
            contextBuilder.AppendLine($"Source: {chunk.SourceFile}, Page: {chunk.PageNumber}");
            contextBuilder.AppendLine(chunk.Content);
            contextBuilder.AppendLine();

            citations.Add(new Citation
            {
                SourceFile = chunk.SourceFile,
                PageNumber = chunk.PageNumber,
                Score = result.Score ?? 0,
                Content = chunk.Content
            });

            citationNumber++;
        }

        _logger.LogInformation("Retrieved {Count} relevant documents", citations.Count);

        return (contextBuilder.ToString(), citations);
    }
}
```

### Step 5: Implement ChatService

Create `Services/ChatService.cs`:

```csharp
using Backend.Models;
using Microsoft.Extensions.AI;
using System.Runtime.CompilerServices;

namespace Backend.Services;

public class ChatService
{
    private readonly IChatClient _chatClient;
    private readonly RagService _ragService;
    private readonly ILogger<ChatService> _logger;

    public ChatService(
        IChatClient chatClient,
        RagService ragService,
        ILogger<ChatService> logger)
    {
        _chatClient = chatClient;
        _ragService = ragService;
        _logger = logger;
    }

    public async IAsyncEnumerable<StreamResponse> StreamChatResponseAsync(
        string userMessage,
        List<ChatMessage>? chatHistory = null,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Processing chat message: {Message}", userMessage);

        // Retrieve context from RAG service
        var (context, citations) = await _ragService.RetrieveContextAsync(
            userMessage,
            topK: 5,
            cancellationToken
        );

        // Build message list with RAG context
        var messages = new List<ChatMessage>
        {
            new(ChatRole.System, BuildSystemPrompt(context))
        };

        // Add previous conversation history
        if (chatHistory != null)
        {
            foreach (var msg in chatHistory.TakeLast(5))
            {
                var role = msg.Role.ToLower() == "user" ? ChatRole.User : ChatRole.Assistant;
                messages.Add(new ChatMessage(role, msg.Content));
            }
        }

        messages.Add(new ChatMessage(ChatRole.User, userMessage));

        // Stream response from LLM via IChatClient
        await foreach (var update in _chatClient
            .CompleteStreamingAsync(messages, cancellationToken: cancellationToken))
        {
            if (!string.IsNullOrEmpty(update.Text))
            {
                yield return new StreamResponse
                {
                    Content = update.Text,
                    Citations = null,
                    IsComplete = false
                };
            }
        }

        // Send citations at the end
        yield return new StreamResponse
        {
            Content = null,
            Citations = citations,
            IsComplete = true
        };
    }

    private string BuildSystemPrompt(string context)
    {
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
}
```

### Step 6: Implement AgentOrchestrationService

Create `Services/AgentOrchestrationService.cs`:

```csharp
using Backend.Models;
using Microsoft.Extensions.AI;
using System.Runtime.CompilerServices;

namespace Backend.Services;

public class AgentOrchestrationService
{
    private readonly IChatClient _chatClient;
    private readonly RagService _ragService;
    private readonly ILogger<AgentOrchestrationService> _logger;

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
        List<ChatMessage>? chatHistory = null,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Processing with sequential orchestration: {Message}", userMessage);

        // Step 1: Retrieve context
        var (context, citations) = await _ragService.RetrieveContextAsync(
            userMessage,
            topK: 5,
            cancellationToken
        );

        string ragResponse = string.Empty;
        string finalSummary = string.Empty;

        try
        {
            // Step 2: RAG Agent - Get detailed response
            var ragMessages = new List<ChatMessage>
            {
                new(ChatRole.System, BuildRagAgentPrompt(context)),
                new(ChatRole.User, userMessage)
            };

            var ragResult = await _chatClient.CompleteAsync(
                ragMessages,
                cancellationToken: cancellationToken
            );
            ragResponse = ragResult.Message.Text ?? "";

            _logger.LogInformation("RAG agent response length: {Length}", ragResponse.Length);

            // Step 3: Summarization Agent - Condense the response
            var summaryMessages = new List<ChatMessage>
            {
                new(ChatRole.System, BuildSummarizationAgentPrompt()),
                new(ChatRole.User, $"Summarize this text:\n\n{ragResponse}")
            };

            var summaryResult = await _chatClient.CompleteAsync(
                summaryMessages,
                cancellationToken: cancellationToken
            );
            finalSummary = summaryResult.Message.Text ?? "";

            _logger.LogInformation("Summary length: {Length}", finalSummary.Length);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in sequential orchestration");
            yield return new StreamResponse
            {
                Content = $"\n\n[Error: {ex.Message}]",
                Citations = null,
                IsComplete = true
            };
            yield break;
        }

        // Return final summary with citations
        yield return new StreamResponse
        {
            Content = finalSummary,
            Citations = citations,
            IsComplete = true
        };
    }

    private string BuildRagAgentPrompt(string context)
    {
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
6. DO NOT use phrases like 'As of my latest update' or 'I don't have specific details'
7. Be direct and conversational
8. If the assistant's response is long, extract ONLY the top 2-3 key points

Example format: 'The Shopify Connector now supports X [1], enables Y [2], and includes Z [3]. These changes improve A and B.'

Summarize the previous message in 4-5 lines maximum:";
    }
}
```

### Step 7: Create SignalR Hub

Create `Hubs/ChatHub.cs`:

```csharp
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
        _logger.LogInformation(
            "Connection {ConnectionId} streaming chat for message: {Message}, Summarization: {Summarization}",
            connectionId,
            message,
            useSummarization
        );

        // Route to appropriate service
        if (useSummarization)
        {
            await foreach (var response in _orchestrationService
                .StreamSequentialResponseAsync(message, history, cancellationToken))
            {
                yield return response;
            }
        }
        else
        {
            await foreach (var response in _chatService
                .StreamChatResponseAsync(message, history, cancellationToken))
            {
                yield return response;
            }
        }

        _logger.LogInformation("Connection {ConnectionId} completed streaming", connectionId);
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation("Client connected: {ConnectionId}", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("Client disconnected: {ConnectionId}", Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }
}
```

### Step 8: Configure Services in Program.cs

This is the main configuration file that wires everything together. Replace the contents of `Program.cs`:

```csharp
using Azure;
using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Backend.Hubs;
using Backend.Services;
using Microsoft.Extensions.AI;
using OpenAI;
using OpenAI.Chat;
using OpenAI.Embeddings;
using Serilog;
using System.ClientModel;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog for better logging
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .WriteTo.Console()
    .CreateLogger();
builder.Host.UseSerilog();

// Add basic services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure CORS (allows frontend to call backend)
var allowedOrigins = builder.Configuration.GetSection("CORS:AllowedOrigins").Get<string[]>() 
    ?? new[] { "http://localhost:5173", "http://localhost:5174" };

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();  // Required for SignalR
    });
});

// Configure SignalR for real-time streaming
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = builder.Environment.IsDevelopment();
    options.MaximumReceiveMessageSize = 102400;
});

// Configure Azure AI Search
var searchEndpoint = builder.Configuration["AzureAISearch:Endpoint"]!;
var searchApiKey = builder.Configuration["AzureAISearch:ApiKey"]!;
var indexName = builder.Configuration["AzureAISearch:IndexName"] ?? "pdf-documents";
var searchCredential = new AzureKeyCredential(searchApiKey);

builder.Services.AddSingleton(new SearchIndexClient(new Uri(searchEndpoint), searchCredential));
builder.Services.AddSingleton(new SearchClient(new Uri(searchEndpoint), indexName, searchCredential));

// Configure Azure OpenAI
var openAiEndpoint = builder.Configuration["AzureOpenAI:Endpoint"]!;
var openAiApiKey = builder.Configuration["AzureOpenAI:ApiKey"]!;
var chatDeployment = builder.Configuration["AzureOpenAI:ChatDeploymentName"]!;
var embeddingDeployment = builder.Configuration["AzureOpenAI:EmbeddingDeploymentName"]!;

// Keep the configured endpoint as the resource root; append the v1 API path.
var openAiClient = new OpenAIClient(
    new ApiKeyCredential(openAiApiKey),
    new OpenAIClientOptions
    {
        Endpoint = new Uri($"{openAiEndpoint.TrimEnd('/')}/openai/v1/")
    });

// Get ChatClient for standard chat operations (used by ChatService)
var chatClient = openAiClient.GetChatClient(chatDeployment);
builder.Services.AddSingleton(chatClient);

// Register IChatClient for Agent Framework (uses the AsIChatClient() adapter)
builder.Services.AddSingleton<IChatClient>(chatClient.AsIChatClient());

// Get EmbeddingClient for RAG embeddings
var embeddingClient = openAiClient.GetEmbeddingClient(embeddingDeployment);
builder.Services.AddSingleton(embeddingClient);

// Register application services
builder.Services.AddScoped<RagService>();
builder.Services.AddScoped<ChatService>();
builder.Services.AddScoped<AgentOrchestrationService>();
builder.Services.AddScoped<DocumentProcessor>();

var app = builder.Build();

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFrontend");
app.UseAuthorization();
app.MapControllers();
app.MapHub<ChatHub>("/chatHub");  // SignalR endpoint

app.Run();
```

**Key Points:**
- `ChatClient` is registered directly for streaming chat (used by ChatService)
- `IChatClient` is registered using `AsIChatClient()` adapter (used by Agent Framework)
- Both `SearchClient` and `SearchIndexClient` are needed (search vs. index management)
- SignalR hub is mapped to `/chatHub` endpoint

### Step 9: Create Frontend Project

```bash
# Navigate to solution root
cd ..

# Create Vite + React + TypeScript project
npm create vite@latest Frontend -- --template react-ts
cd Frontend

# Install dependencies
npm install
npm install @fluentui/react-components
npm install @microsoft/signalr
```

### Step 10: Create Frontend Services

Create `src/services/chatService.ts`:

```typescript
import * as signalR from '@microsoft/signalr';

// Message exchanged with backend
export interface ChatMessage {
  role: string;
  content: string;
  citations?: Citation[];
  timestamp: Date;
}

// Citation matching the backend model
export interface Citation {
  documentId: string;
  title: string;
  chunkText: string;
  sourceUrl?: string;
  relevanceScore: number;
  pageNumber?: number;
}

// Response streamed from backend
export interface StreamResponse {
  content?: string;
  citations?: Citation[];
  isComplete: boolean;
}

class ChatService {
  private connection: signalR.HubConnection | null = null;

  async connect(): Promise<void> {
    if (this.connection?.state === signalR.HubConnectionState.Connected) {
      return;
    }

    this.connection = new signalR.HubConnectionBuilder()
      .withUrl('http://localhost:5000/chatHub')
      .withAutomaticReconnect()
      .configureLogging(signalR.LogLevel.Information)
      .build();

    await this.connection.start();
    console.log('SignalR Connected');
  }

  async streamChatResponse(
    message: string,
    history: ChatMessage[] | null,
    useSummarization: boolean,
    onChunk: (response: StreamResponse) => void,
    onError: (error: Error) => void
  ): Promise<void> {
    if (!this.connection) {
      throw new Error('Connection not established');
    }

    try {
      // Call the SignalR streaming method
      const stream = this.connection.stream<StreamResponse>(
        'StreamChatResponse',
        message,
        history,
        useSummarization
      );

      // Process each chunk as it arrives
      for await (const response of stream) {
        onChunk(response);
      }
    } catch (error) {
      onError(error as Error);
    }
  }

  disconnect(): void {
    this.connection?.stop();
  }
}

export const chatService = new ChatService();
```

### Step 11: Create React Components

Create `src/components/ChatInterface.tsx`:

```typescript
import { useState, useEffect, useRef } from 'react';
import { MessageList } from './MessageList';
import { MessageInput } from './MessageInput';
import { chatService, ChatMessage, StreamResponse } from '../services/chatService';
import {
  makeStyles,
  tokens,
  Title3,
  Text,
  Switch,
} from '@fluentui/react-components';

const useStyles = makeStyles({
  container: {
    display: 'flex',
    flexDirection: 'column',
    height: '100vh',
    backgroundColor: tokens.colorNeutralBackground1,
  },
  header: {
    padding: tokens.spacingVerticalXL,
    borderBottom: `1px solid ${tokens.colorNeutralStroke1}`,
    backgroundColor: '#0078d4',
  },
  title: {
    color: '#ffffff',
    marginBottom: tokens.spacingVerticalS,
  },
  subtitle: {
    color: '#ffffff',
    opacity: 0.9,
    display: 'block',
  },
  headerControls: {
    display: 'flex',
    alignItems: 'center',
    gap: tokens.spacingHorizontalM,
    marginTop: tokens.spacingVerticalM,
  },
  switchLabel: {
    color: '#ffffff',
    fontSize: tokens.fontSizeBase300,
    fontWeight: tokens.fontWeightSemibold,
  },
  chatContainer: {
    display: 'flex',
    flexDirection: 'column',
    flex: 1,
    overflow: 'hidden',
  },
  messagesContainer: {
    flex: 1,
    overflow: 'hidden',
    display: 'flex',
    flexDirection: 'column',
  },
});

export const ChatInterface: React.FC = () => {
  const styles = useStyles();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isStreaming, setIsStreaming] = useState(false);
  const [useSummarization, setUseSummarization] = useState(false);
  const currentMessageRef = useRef<ChatMessage | null>(null);

  useEffect(() => {
    chatService.connect();
    return () => chatService.disconnect();
  }, []);

  const handleSendMessage = async (messageText: string) => {
    if (isStreaming) return;

    // Add user message
    const userMessage: ChatMessage = {
      role: 'user',
      content: messageText,
      timestamp: new Date(),
    };
    setMessages(prev => [...prev, userMessage]);

    // Initialize assistant message
    currentMessageRef.current = {
      role: 'assistant',
      content: '',
      timestamp: new Date(),
    };
    setMessages(prev => [...prev, currentMessageRef.current!]);
    setIsStreaming(true);

    try {
      await chatService.streamChatResponse(
        messageText,
        messages.slice(-10),
        useSummarization,
        (response: StreamResponse) => {
          if (response.content) {
            currentMessageRef.current!.content += response.content;
          }

          if (response.citations) {
            currentMessageRef.current!.citations = response.citations;
          }

          setMessages(prev => {
            const newMessages = [...prev];
            newMessages[newMessages.length - 1] = { ...currentMessageRef.current! };
            return newMessages;
          });

          if (response.isComplete) {
            setIsStreaming(false);
          }
        },
        (error) => {
          console.error('Error:', error);
          setIsStreaming(false);
        }
      );
    } catch (error) {
      console.error('Error:', error);
      setIsStreaming(false);
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <Title3 className={styles.title}>RAG Chat - PDF Q&A</Title3>
        <Text className={styles.subtitle}>
          Ask questions about your documents using AI-powered search
        </Text>
        <div className={styles.headerControls}>
          <Text className={styles.switchLabel} weight="semibold">
            Summarize Responses
          </Text>
          <Switch
            checked={useSummarization}
            onChange={(_, data) => setUseSummarization(data.checked)}
          />
        </div>
      </div>

      <div className={styles.chatContainer}>
        <div className={styles.messagesContainer}>
          <MessageList messages={messages} />
        </div>
        <MessageInput
          onSendMessage={handleSendMessage}
          disabled={isStreaming}
        />
      </div>
    </div>
  );
};
```

### Step 12: Run the Application

Now it's time to run your application! You'll need two terminal windows.

**Terminal 1 - Start the Backend:**
```bash
# Navigate to the Backend folder
cd Backend

# Run the backend server
dotnet run
```

You should see output like:
```
[INF] Now listening on: http://localhost:5000
[INF] Application started.
```

**Terminal 2 - Start the Frontend:**
```bash
# Navigate to the Frontend folder (from the RagChatApp root)
cd Frontend

# Start the development server
npm run dev
```

You should see output like:
```
  VITE v5.x.x  ready in xxx ms
  ➜  Local:   http://localhost:5173/
```

**Access the Application:**
1. Open your browser to `http://localhost:5173`
2. You should see the RAG Chat interface
3. Try uploading a PDF document using the upload button
4. Ask questions about your document
5. Toggle "Summarize Responses" to see the difference between detailed and summarized answers

**Troubleshooting Common Issues:**

| Problem | Solution |
|---------|----------|
| Backend won't start | Check your `appsettings.json` has correct Azure credentials |
| "CORS error" in browser | Ensure backend is running on port 5000 |
| "Connection refused" | Check both backend and frontend are running |
| PDF upload fails | Verify Azure AI Search index was created |
| No search results | Upload and index documents first |

## Key Learnings and Best Practices

### 1. Prompt Engineering for Agent Workflows

**Challenge:** Agents ignoring instructions in sequential workflows.

**Solution:** 
- Use explicit, imperative instructions ("DO NOT use your knowledge")
- Provide concrete examples of desired output format
- Specify constraints clearly (e.g., "Maximum 4-5 lines")
- Include negative examples (what NOT to do)

### 2. RAG Context Assembly

**Best Practices:**
- Include source metadata in context (file name, page number)
- Number citations consistently [1], [2], [3]
- Provide sufficient context (500-1000 characters per chunk)
- Use chunk overlap to maintain coherence
- Use hybrid search (vector + keyword) for better results

### 3. Streaming Response Handling

**Implementation Tips:**
- Use `IAsyncEnumerable<T>` for efficient streaming
- Send citations separately at the end
- Handle partial message updates carefully in React
- Use refs to avoid stale state in callbacks
- Implement proper error handling and recovery

### 4. Real-time Communication with SignalR

**Configuration Requirements:**
- Enable CORS with credentials for WebSocket
- Configure automatic reconnection
- Handle connection lifecycle properly
- Implement backpressure for fast-streaming scenarios
- Monitor connection state in UI

### 5. Azure AI Search Optimization

**Performance Tips:**
- Create appropriate indexes with vector fields
- Use batch operations for bulk indexing
- Implement retry logic for transient failures
- Monitor query latency and adjust K value
- Use hybrid search for better relevance

### 6. Cost Optimization

**Strategies:**
- Cache embeddings to avoid regeneration
- Implement response caching for common queries
- Use streaming to improve perceived performance
- Monitor token usage and set limits
- Consider cheaper models for summarization

## Deploying to Azure

This section provides comprehensive instructions for deploying the RAG Chat application to Azure, covering infrastructure setup, application deployment, and production configurations.

### Azure Resources Required

Before deployment, you need to provision the following Azure resources:

1. **Azure OpenAI Service**
   - GPT-4 or GPT-3.5-turbo deployment
   - text-embedding-ada-002 deployment

2. **Azure AI Search**
   - Standard tier or higher for production workloads
   - Vector search enabled

3. **Azure App Service (Backend)**
   - Windows or Linux App Service Plan (B1 or higher)
   - .NET 10 runtime (confirm availability for the selected hosting environment)

4. **Azure Static Web Apps (Frontend)**
   - Standard tier for custom domains and enterprise features
   - Or Azure Storage + CDN for static hosting

5. **Azure Application Insights** (Optional but recommended)
   - For monitoring and diagnostics

6. **Azure Key Vault** (Recommended)
   - For secure storage of API keys and connection strings

### Step 1: Provision Azure Resources

#### Using Azure Portal

**1.1 Create Resource Group:**
```bash
az group create \
  --name rg-ragchat-prod \
  --location eastus
```

**1.2 Create Azure OpenAI Service:**
```bash
az cognitiveservices account create \
  --name oai-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --kind OpenAI \
  --sku S0 \
  --location eastus
```

Deploy models:
```bash
# Deploy GPT-4 for chat
az cognitiveservices account deployment create \
  --name oai-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --deployment-name gpt-4 \
  --model-name gpt-4 \
  --model-version "0613" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name "Standard"

# Deploy text-embedding-ada-002
az cognitiveservices account deployment create \
  --name oai-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --deployment-name text-embedding-ada-002 \
  --model-name text-embedding-ada-002 \
  --model-version "2" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name "Standard"
```

**1.3 Create Azure AI Search:**
```bash
az search service create \
  --name srch-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --sku Standard \
  --location eastus \
  --partition-count 1 \
  --replica-count 1
```

**1.4 Create App Service Plan and Web App:**
```bash
# Create App Service Plan
az appservice plan create \
  --name asp-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --plan asp-ragchat-prod \
  --runtime "DOTNET|10.0"
```

**1.5 Create Application Insights:**
```bash
az monitor app-insights component create \
  --app appi-ragchat-prod \
  --location eastus \
  --resource-group rg-ragchat-prod \
  --application-type web
```

**1.6 Create Key Vault:**
```bash
az keyvault create \
  --name kv-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --location eastus \
  --enable-rbac-authorization false
```

### Step 2: Configure Key Vault

Store sensitive configuration in Key Vault:

```bash
# Get Azure OpenAI key
OPENAI_KEY=$(az cognitiveservices account keys list \
  --name oai-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --query key1 -o tsv)

# Get Azure Search admin key
SEARCH_KEY=$(az search admin-key show \
  --service-name srch-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --query primaryKey -o tsv)

# Store in Key Vault
az keyvault secret set \
  --vault-name kv-ragchat-prod \
  --name "AzureOpenAI--ApiKey" \
  --value "$OPENAI_KEY"

az keyvault secret set \
  --vault-name kv-ragchat-prod \
  --name "AzureSearch--ApiKey" \
  --value "$SEARCH_KEY"
```

### Step 3: Configure Backend for Production

**3.1 Update appsettings.Production.json:**

Create `Backend/appsettings.Production.json`:

```json
{
  "AzureOpenAI": {
    "Endpoint": "https://oai-ragchat-prod.openai.azure.com/",
    "ApiKey": "",
    "ChatDeploymentName": "gpt-4",
    "EmbeddingDeploymentName": "text-embedding-ada-002"
  },
  "AzureSearch": {
    "Endpoint": "https://srch-ragchat-prod.search.windows.net",
    "ApiKey": "",
    "IndexName": "documents"
  },
  "ApplicationInsights": {
    "ConnectionString": ""
  },
  "AllowedOrigins": [
    "https://your-frontend-app.azurestaticapps.net"
  ],
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "OpenAI": "Information"
    },
    "ApplicationInsights": {
      "LogLevel": {
        "Default": "Information"
      }
    }
  }
}
```

**3.2 Update Program.cs for Key Vault integration:**

```csharp
// Add at the top of Program.cs
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// Configure Key Vault (production only)
if (builder.Environment.IsProduction())
{
    var keyVaultName = builder.Configuration["KeyVaultName"];
    if (!string.IsNullOrEmpty(keyVaultName))
    {
        var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
        builder.Configuration.AddAzureKeyVault(
            keyVaultUri,
            new DefaultAzureCredential()
        );
    }
}

// Update CORS to read from configuration
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        var allowedOrigins = builder.Configuration
            .GetSection("AllowedOrigins")
            .Get<string[]>() ?? Array.Empty<string>();
            
        policy.WithOrigins(allowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
});

// Rest of the configuration...
```

**3.3 Add NuGet packages for Azure integration:**

```bash
cd Backend
dotnet add package Azure.Identity
dotnet add package Azure.Extensions.AspNetCore.Configuration.Secrets
dotnet add package Microsoft.ApplicationInsights.AspNetCore
```

### Step 4: Deploy Backend to Azure App Service

**4.1 Configure Web App settings:**

```bash
# Configure .NET version
az webapp config set \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --linux-fx-version "DOTNET|10.0"

# Enable WebSockets for SignalR
az webapp config set \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --web-sockets-enabled true

# Set always on
az webapp config set \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --always-on true
```

**4.2 Configure application settings:**

```bash
# Get Application Insights connection string
APPINSIGHTS_CONN=$(az monitor app-insights component show \
  --app appi-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --query connectionString -o tsv)

# Set application settings
az webapp config appsettings set \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --settings \
    KeyVaultName="kv-ragchat-prod" \
    ASPNETCORE_ENVIRONMENT="Production" \
    ApplicationInsights__ConnectionString="$APPINSIGHTS_CONN" \
    AzureOpenAI__Endpoint="https://oai-ragchat-prod.openai.azure.com/" \
    AzureOpenAI__ChatDeploymentName="gpt-4" \
    AzureOpenAI__EmbeddingDeploymentName="text-embedding-ada-002" \
    AzureSearch__Endpoint="https://srch-ragchat-prod.search.windows.net" \
    AzureSearch__IndexName="documents"
```

**4.3 Enable Managed Identity:**

```bash
# Enable system-assigned managed identity
az webapp identity assign \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod

# Get the identity principal ID
IDENTITY_PRINCIPAL_ID=$(az webapp identity show \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --query principalId -o tsv)

# Grant Key Vault access to the managed identity
az keyvault set-policy \
  --name kv-ragchat-prod \
  --object-id $IDENTITY_PRINCIPAL_ID \
  --secret-permissions get list
```

**4.4 Deploy using Azure CLI:**

```bash
cd Backend

# Publish the application
dotnet publish -c Release -o ./publish

# Create deployment package
cd publish
zip -r ../deploy.zip .
cd ..

# Deploy to App Service
az webapp deployment source config-zip \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --src deploy.zip
```

**4.5 Verify deployment:**

```bash
# Check deployment logs
az webapp log tail \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod

# Test the backend
curl https://app-ragchat-backend-prod.azurewebsites.net/api/document/status
```

### Step 5: Deploy Frontend to Azure Static Web Apps

**5.1 Create Static Web App:**

```bash
az staticwebapp create \
  --name swa-ragchat-frontend-prod \
  --resource-group rg-ragchat-prod \
  --location eastus2 \
  --sku Standard
```

**5.2 Update frontend configuration:**

Create `Frontend/.env.production`:

```env
VITE_API_BASE_URL=https://app-ragchat-backend-prod.azurewebsites.net
VITE_SIGNALR_HUB_URL=https://app-ragchat-backend-prod.azurewebsites.net/chatHub
```

Update `Frontend/src/services/chatService.ts`:

```typescript
const hubUrl = import.meta.env.VITE_SIGNALR_HUB_URL || 'http://localhost:5000/chatHub';

async connect(): Promise<void> {
  if (this.connection?.state === signalR.HubConnectionState.Connected) {
    return;
  }

  this.connection = new signalR.HubConnectionBuilder()
    .withUrl(hubUrl)
    .withAutomaticReconnect()
    .configureLogging(signalR.LogLevel.Information)
    .build();

  await this.connection.start();
}
```

**5.3 Build and deploy:**

```bash
cd Frontend

# Build for production
npm run build

# Get deployment token
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
  --name swa-ragchat-frontend-prod \
  --resource-group rg-ragchat-prod \
  --query properties.apiKey -o tsv)

# Deploy using SWA CLI
npm install -g @azure/static-web-apps-cli

swa deploy ./dist \
  --deployment-token $DEPLOYMENT_TOKEN \
  --env production
```

**Alternative: Deploy using Azure CLI:**

```bash
cd Frontend
npm run build

# Upload to Static Web App
az staticwebapp upload \
  --name swa-ragchat-frontend-prod \
  --resource-group rg-ragchat-prod \
  --source ./dist
```

### Step 6: Create Azure AI Search Index

Before using the application, create the search index:

**6.1 Create index definition file:**

Create `search-index-schema.json`:

```json
{
  "name": "documents",
  "fields": [
    {
      "name": "id",
      "type": "Edm.String",
      "key": true,
      "searchable": false,
      "filterable": false,
      "sortable": false,
      "facetable": false
    },
    {
      "name": "sourceFile",
      "type": "Edm.String",
      "searchable": true,
      "filterable": true,
      "sortable": true,
      "facetable": true
    },
    {
      "name": "pageNumber",
      "type": "Edm.Int32",
      "searchable": false,
      "filterable": true,
      "sortable": true,
      "facetable": false
    },
    {
      "name": "content",
      "type": "Edm.String",
      "searchable": true,
      "filterable": false,
      "sortable": false,
      "facetable": false
    },
    {
      "name": "contentVector",
      "type": "Collection(Edm.Single)",
      "searchable": true,
      "filterable": false,
      "sortable": false,
      "facetable": false,
      "dimensions": 1536,
      "vectorSearchProfile": "vector-profile"
    },
    {
      "name": "indexedAt",
      "type": "Edm.DateTimeOffset",
      "searchable": false,
      "filterable": true,
      "sortable": true,
      "facetable": false
    }
  ],
  "vectorSearch": {
    "algorithms": [
      {
        "name": "vector-algorithm",
        "kind": "hnsw",
        "hnswParameters": {
          "metric": "cosine",
          "m": 4,
          "efConstruction": 400,
          "efSearch": 500
        }
      }
    ],
    "profiles": [
      {
        "name": "vector-profile",
        "algorithm": "vector-algorithm"
      }
    ]
  }
}
```

**6.2 Create the index:**

```bash
# Get search endpoint and key
SEARCH_ENDPOINT="https://srch-ragchat-prod.search.windows.net"
SEARCH_KEY=$(az search admin-key show \
  --service-name srch-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --query primaryKey -o tsv)

# Create index
curl -X POST "$SEARCH_ENDPOINT/indexes?api-version=2023-11-01" \
  -H "Content-Type: application/json" \
  -H "api-key: $SEARCH_KEY" \
  -d @search-index-schema.json
```

### Step 7: Setup CI/CD with GitHub Actions

**7.1 Create GitHub secrets:**

In your GitHub repository, add these secrets:
- `AZURE_CREDENTIALS` - Service principal credentials
- `AZURE_WEBAPP_PUBLISH_PROFILE` - Backend publish profile
- `AZURE_STATIC_WEB_APPS_API_TOKEN` - Static Web App deployment token

**7.2 Create backend deployment workflow:**

Create `.github/workflows/backend-deploy.yml`:

```yaml
name: Deploy Backend to Azure

on:
  push:
    branches:
      - main
    paths:
      - 'Backend/**'
  workflow_dispatch:

env:
  AZURE_WEBAPP_NAME: app-ragchat-backend-prod
  DOTNET_VERSION: '10.0.x'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}
    
    - name: Restore dependencies
      run: dotnet restore
      working-directory: ./Backend
    
    - name: Build
      run: dotnet build --configuration Release --no-restore
      working-directory: ./Backend
    
    - name: Publish
      run: dotnet publish -c Release -o ${{env.DOTNET_ROOT}}/backend
      working-directory: ./Backend
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
        package: ${{env.DOTNET_ROOT}}/backend
```

**7.3 Create frontend deployment workflow:**

Create `.github/workflows/frontend-deploy.yml`:

```yaml
name: Deploy Frontend to Azure Static Web Apps

on:
  push:
    branches:
      - main
    paths:
      - 'Frontend/**'
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: Frontend/package-lock.json
    
    - name: Install dependencies
      run: npm ci
      working-directory: ./Frontend
    
    - name: Build
      run: npm run build
      working-directory: ./Frontend
      env:
        VITE_API_BASE_URL: https://app-ragchat-backend-prod.azurewebsites.net
        VITE_SIGNALR_HUB_URL: https://app-ragchat-backend-prod.azurewebsites.net/chatHub
    
    - name: Deploy to Azure Static Web Apps
      uses: Azure/static-web-apps-deploy@v1
      with:
        azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
        repo_token: ${{ secrets.GITHUB_TOKEN }}
        action: "upload"
        app_location: "Frontend/dist"
        skip_app_build: true
```

### Step 8: Configure Custom Domain (Optional)

**8.1 Configure custom domain for Static Web App:**

```bash
# Add custom domain
az staticwebapp hostname set \
  --name swa-ragchat-frontend-prod \
  --resource-group rg-ragchat-prod \
  --hostname www.yourdomain.com

# Validate domain
az staticwebapp hostname show \
  --name swa-ragchat-frontend-prod \
  --resource-group rg-ragchat-prod \
  --hostname www.yourdomain.com
```

**8.2 Configure custom domain for App Service:**

```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --hostname api.yourdomain.com

# Configure SSL certificate (free App Service Managed Certificate)
az webapp config ssl create \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --hostname api.yourdomain.com

# Bind certificate
az webapp config ssl bind \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --certificate-thumbprint <thumbprint> \
  --ssl-type SNI
```

### Step 9: Production Monitoring and Diagnostics

**9.1 Configure Application Insights alerts:**

```bash
# Create alert for high response time
az monitor metrics alert create \
  --name "High Response Time" \
  --resource-group rg-ragchat-prod \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/rg-ragchat-prod/providers/Microsoft.Web/sites/app-ragchat-backend-prod" \
  --condition "avg requests/duration > 1000" \
  --description "Alert when average response time exceeds 1 second" \
  --window-size 5m \
  --evaluation-frequency 1m

# Create alert for high error rate
az monitor metrics alert create \
  --name "High Error Rate" \
  --resource-group rg-ragchat-prod \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/rg-ragchat-prod/providers/Microsoft.Web/sites/app-ragchat-backend-prod" \
  --condition "avg requests/failed > 5" \
  --description "Alert when error rate exceeds 5 per minute" \
  --window-size 5m \
  --evaluation-frequency 1m
```

**9.2 Enable diagnostic logs:**

```bash
# Enable application logging
az webapp log config \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --application-logging filesystem \
  --level information

# Enable detailed error messages
az webapp log config \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --detailed-error-messages true \
  --failed-request-tracing true
```

### Step 10: Security Best Practices

**10.1 Enable HTTPS Only:**

```bash
az webapp update \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --https-only true
```

**10.2 Configure Azure Front Door (Optional - for global distribution):**

```bash
# Create Front Door
az afd profile create \
  --profile-name afd-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --sku Premium_AzureFrontDoor

# Add endpoint
az afd endpoint create \
  --endpoint-name ragchat-global \
  --profile-name afd-ragchat-prod \
  --resource-group rg-ragchat-prod \
  --enabled-state Enabled
```

**10.3 Configure IP restrictions (Optional):**

```bash
# Restrict backend access to specific IPs or Front Door
az webapp config access-restriction add \
  --name app-ragchat-backend-prod \
  --resource-group rg-ragchat-prod \
  --rule-name "Allow-FrontDoor" \
  --action Allow \
  --service-tag AzureFrontDoor.Backend \
  --priority 100
```

### Step 11: Cost Optimization

**11.1 Configure auto-scaling:**

```bash
# Enable autoscale for App Service Plan
az monitor autoscale create \
  --resource-group rg-ragchat-prod \
  --resource asp-ragchat-prod \
  --resource-type Microsoft.Web/serverfarms \
  --name autoscale-ragchat \
  --min-count 1 \
  --max-count 3 \
  --count 1

# Add scale-out rule (CPU > 70%)
az monitor autoscale rule create \
  --resource-group rg-ragchat-prod \
  --autoscale-name autoscale-ragchat \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1

# Add scale-in rule (CPU < 30%)
az monitor autoscale rule create \
  --resource-group rg-ragchat-prod \
  --autoscale-name autoscale-ragchat \
  --condition "Percentage CPU < 30 avg 5m" \
  --scale in 1
```

**11.2 Set up budget alerts:**

```bash
# Create budget
az consumption budget create \
  --budget-name "RagChat-Monthly-Budget" \
  --amount 500 \
  --time-grain Monthly \
  --start-date 2026-01-01 \
  --end-date 2026-12-31 \
  --resource-group rg-ragchat-prod
```

### Step 12: Backup and Disaster Recovery

**12.1 Configure backup for App Service:**

```bash
# Create storage account for backups
az storage account create \
  --name stragchatbackup \
  --resource-group rg-ragchat-prod \
  --location eastus \
  --sku Standard_LRS

# Get storage account connection string
BACKUP_STORAGE_CONN=$(az storage account show-connection-string \
  --name stragchatbackup \
  --resource-group rg-ragchat-prod \
  --query connectionString -o tsv)

# Configure backup
az webapp config backup update \
  --resource-group rg-ragchat-prod \
  --webapp-name app-ragchat-backend-prod \
  --container-url "$BACKUP_STORAGE_CONN" \
  --frequency 1d \
  --retain-one true \
  --retention 30
```

### Deployment Checklist

Before going to production, verify:

- ✅ All Azure resources provisioned correctly
- ✅ Managed Identity configured for Key Vault access
- ✅ Application settings configured in App Service
- ✅ CORS configured with correct frontend URL
- ✅ WebSockets enabled for SignalR
- ✅ Search index created with vector search capability
- ✅ SSL certificates configured for custom domains
- ✅ Application Insights monitoring enabled
- ✅ Diagnostic logs enabled
- ✅ Auto-scaling rules configured
- ✅ Budget alerts set up
- ✅ CI/CD pipelines tested
- ✅ Backup configured
- ✅ Security review completed

### Post-Deployment Testing

**Test backend health:**
```bash
curl https://app-ragchat-backend-prod.azurewebsites.net/api/document/status
```

**Test SignalR connection:**
```javascript
// In browser console on frontend
const connection = new signalR.HubConnectionBuilder()
  .withUrl("https://app-ragchat-backend-prod.azurewebsites.net/chatHub")
  .build();

connection.start()
  .then(() => console.log("Connected!"))
  .catch(err => console.error(err));
```

**Test document upload and search:**
1. Upload a test PDF document
2. Wait for indexing to complete
3. Query the document
4. Verify citations are returned correctly
5. Test with summarization enabled/disabled

### Troubleshooting Common Issues

**Issue: SignalR connection fails**
- Verify WebSockets are enabled in App Service
- Check CORS configuration includes credentials
- Verify frontend URL is in AllowedOrigins
- Check Application Insights for connection errors

**Issue: High latency in responses**
- Review Application Insights performance metrics
- Check Azure OpenAI throttling limits
- Consider caching embeddings
- Enable autoscaling if CPU is high

**Issue: Search returns no results**
- Verify index was created successfully
- Check if documents are indexed (query index statistics)
- Verify embedding dimensions match (1536 for ada-002)
- Test vector search with sample query

**Issue: Key Vault access denied**
- Verify Managed Identity is enabled
- Check Key Vault access policies
- Ensure secrets exist with correct names
- Review App Service logs for authentication errors

## Conclusion

This chapter demonstrated how to build a production-ready RAG chat application with AI-powered summarization using sequential agent orchestration. Key takeaways:

1. **Architecture Matters:** Clear separation between RAG and orchestration services enables flexibility and maintainability.

2. **Manual Orchestration:** Sometimes direct control over workflow is better than framework abstractions, especially for complex prompting requirements.

3. **User Experience:** Real-time streaming with SignalR provides responsive interactions, while the summarization toggle gives users control over response verbosity.

4. **Prompt Engineering:** Effective agent coordination requires carefully crafted system prompts with explicit instructions and constraints.

5. **Scalability:** The architecture supports easy extension to additional agents or alternative orchestration patterns.

The complete source code for this application is available in the accompanying repository, including additional features like document management, conversation history, and deployment configurations.

## Further Enhancements

Consider implementing these additional features:

1. **Conversation Memory:** Persist chat history to database for long-term context
2. **Multi-Document Upload:** Batch processing with progress tracking
3. **Source Highlighting:** Show exact text snippets from source documents
4. **Export Functionality:** Save conversations as PDF or Markdown
5. **User Authentication:** Add Azure AD B2C for multi-user support
6. **Advanced Orchestration:** Implement parallel agent execution or decision trees
7. **Evaluation Framework:** Add metrics for RAG quality and summarization effectiveness
8. **A/B Testing:** Compare different prompting strategies and models
9. **Caching Layer:** Redis for embedding and response caching
10. **Observability:** Application Insights integration for monitoring and diagnostics
