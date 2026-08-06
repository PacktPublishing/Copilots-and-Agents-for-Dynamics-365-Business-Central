# RAG Chat Application - PDF Q&A with Microsoft Agent Framework

A React web application with .NET 8 backend that enables users to chat with PDF documents using AI. The system uses **Microsoft Semantic Kernel** (Agent Framework) for orchestration, **Azure AI Search** for retrieval-augmented generation (RAG), and **Azure OpenAI** for generating intelligent responses with citations.

## Architecture

```
┌─────────────────┐
│  React Frontend │  (Port 5173)
│   - Fluent UI   │
│   - SignalR     │
└────────┬────────┘
         │
         ↓ WebSocket (SignalR)
┌────────────────────────────────┐
│     .NET 8 Web API             │  (Port 5000)
│  - SignalR Hub                 │
│  - Document Upload Controller  │
└────────┬───────────────────────┘
         │
    ┌────┴─────┬──────────────┐
    ↓          ↓              ↓
┌─────────┐ ┌──────────┐ ┌─────────────────┐
│Semantic │ │   RAG    │ │   Document      │
│ Kernel  │ │ Service  │ │   Processor     │
└────┬────┘ └────┬─────┘ └────┬────────────┘
     │           │             │
     ↓           ↓             ↓
┌──────────┐ ┌────────────────────┐
│Azure     │ │  Azure AI Search   │
│OpenAI    │ │  - Vector Search   │
│          │ │  - Hybrid Search   │
└──────────┘ └────────────────────┘
```

## Features

- ✅ **Real-time Streaming**: Chat responses stream in real-time via SignalR
- ✅ **RAG Pipeline**: Retrieval-augmented generation with Azure AI Search
- ✅ **Semantic Kernel**: Microsoft's agent framework for AI orchestration
- ✅ **PDF Upload**: Upload and index PDF documents automatically
- ✅ **Citations**: AI responses include source references with page numbers
- ✅ **Modern UI**: Built with Microsoft Fluent UI components
- ✅ **Local Development**: Run entirely on localhost with cloud AI services

## Prerequisites

Before running the application, ensure you have:

1. **Development Tools**
   - [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
   - [Node.js 18+](https://nodejs.org/) and npm
   - Code editor (VS Code recommended)

2. **Azure Resources** (Required)
   - **Azure OpenAI Service**
     - `gpt-4` or `gpt-35-turbo` deployment for chat
     - `text-embedding-ada-002` deployment for embeddings
   - **Azure AI Search**
     - Standard tier or higher (for vector search)
     - API key and endpoint

## Setup Instructions

### 1. Clone and Configure Backend

```powershell
cd c:\TEMP\CONTOSOWEBAPP\Backend

# Configure Azure services in appsettings.Development.json
# Edit the file with your Azure resource details:
```

**Backend\appsettings.Development.json**:
```json
{
  "AzureOpenAI": {
    "Endpoint": "https://YOUR_RESOURCE_NAME.openai.azure.com/",
    "ChatDeploymentName": "gpt-4",
    "EmbeddingDeploymentName": "text-embedding-ada-002",
    "ApiKey": "YOUR_AZURE_OPENAI_API_KEY"
  },
  "AzureAISearch": {
    "Endpoint": "https://YOUR_SEARCH_RESOURCE.search.windows.net",
    "IndexName": "pdf-documents",
    "ApiKey": "YOUR_AZURE_SEARCH_API_KEY"
  }
}
```

### 2. Restore Backend Dependencies

```powershell
cd Backend
dotnet restore
```

### 3. Install Frontend Dependencies

```powershell
cd ..\Frontend
npm install
```

## Running the Application

### Start Backend (Terminal 1)

```powershell
cd c:\TEMP\CONTOSOWEBAPP\Backend
dotnet run
```

The backend will start on `http://localhost:5000`

You should see:
```
Starting RAG Chat API on http://localhost:5000
```

### Start Frontend (Terminal 2)

```powershell
cd c:\TEMP\CONTOSOWEBAPP\Frontend
npm run dev
```

The frontend will start on `http://localhost:5173`

Open your browser to: **http://localhost:5173**

## Usage

### 1. Upload PDF Documents

1. Click the **"Upload PDF"** button in the header
2. Select a PDF file from your computer
3. Wait for the upload and indexing to complete
4. You'll see a success message with the number of chunks indexed

### 2. Ask Questions

1. Type your question in the text area at the bottom
2. Press **Enter** or click **"Send"**
3. Watch the AI response stream in real-time
4. View citations below the response with source references

### Example Questions

- "What are the main topics covered in this document?"
- "Summarize the key findings on page 5"
- "What does the document say about [specific topic]?"

## Project Structure

```
CONTOSOWEBAPP/
├── Backend/
│   ├── Controllers/
│   │   └── DocumentController.cs       # PDF upload endpoint
│   ├── Hubs/
│   │   └── ChatHub.cs                  # SignalR hub for streaming
│   ├── Models/
│   │   └── ChatModels.cs               # Data models
│   ├── Services/
│   │   ├── ChatService.cs              # Semantic Kernel integration
│   │   ├── RagService.cs               # Azure AI Search queries
│   │   └── DocumentProcessor.cs        # PDF processing & indexing
│   ├── Program.cs                      # App configuration
│   ├── Backend.csproj                  # NuGet packages
│   └── appsettings.Development.json    # Configuration
│
└── Frontend/
    ├── src/
    │   ├── components/
    │   │   ├── ChatInterface.tsx       # Main chat UI
    │   │   ├── MessageList.tsx         # Message display
    │   │   ├── MessageInput.tsx        # Input component
    │   │   ├── CitationCard.tsx        # Citation display
    │   │   └── DocumentUploader.tsx    # PDF upload UI
    │   ├── services/
    │   │   ├── chatService.ts          # SignalR client
    │   │   └── apiService.ts           # HTTP API client
    │   ├── App.tsx
    │   └── main.tsx
    ├── package.json
    └── vite.config.ts
```

## Key Technologies

### Backend
- **.NET 8**: Modern web API framework
- **Microsoft Semantic Kernel 1.4.0**: Agent framework for AI orchestration
- **Azure.Search.Documents 11.5.1**: Azure AI Search SDK
- **Azure.AI.OpenAI**: Azure OpenAI integration
- **SignalR**: Real-time WebSocket communication
- **UglyToad.PdfPig**: PDF text extraction

### Frontend
- **React 18**: UI library
- **TypeScript**: Type-safe JavaScript
- **Vite**: Fast build tool
- **Fluent UI**: Microsoft's design system
- **SignalR Client**: Real-time communication
- **React Markdown**: Render formatted responses

## How It Works

### RAG Pipeline

1. **Document Upload**
   - PDF is uploaded via HTTP POST
   - Text is extracted using PdfPig
   - Content is chunked (1000 chars with 200 char overlap)
   - Embeddings generated via Azure OpenAI
   - Indexed in Azure AI Search with vectors

2. **Query Processing**
   - User question is embedded
   - Hybrid search (vector + keyword) in Azure AI Search
   - Top 5 relevant chunks retrieved with scores
   - Context formatted with citation markers [1], [2], etc.

3. **Response Generation**
   - Semantic Kernel receives user question + context
   - System prompt instructs GPT to use only provided context
   - Response streams back via SignalR
   - Citations sent at completion

4. **Real-time Streaming**
   - SignalR WebSocket connection established
   - GPT response chunks stream to frontend
   - UI updates progressively as tokens arrive
   - Citations appended when complete

## Troubleshooting

### Backend won't start

**Error**: "AzureOpenAI:Endpoint is not configured"
- Solution: Update `appsettings.Development.json` with your Azure credentials

**Error**: Port 5000 already in use
- Solution: Change port in `launchSettings.json` and update frontend `chatService.ts`

### Frontend can't connect

**Error**: "SignalR connection failed"
- Check backend is running on port 5000
- Verify CORS settings in `Program.cs`
- Check browser console for detailed errors

### Search returns no results

- Ensure PDFs have been uploaded and indexed
- Check Azure AI Search portal for index contents
- Verify embedding deployment name matches configuration
- Check relevance threshold (default 0.7) in `RagService.cs`

### PDF upload fails

**Error**: "Only PDF files are supported"
- Ensure file has `.pdf` extension

**Error**: "Error processing document"
- Check PDF is not encrypted or password-protected
- Verify Azure AI Search credentials are correct
- Check backend logs for detailed error

## Configuration Options

### Chunk Size (Backend\Services\DocumentProcessor.cs)

```csharp
const int chunkSize = 1000;    // Characters per chunk
const int overlap = 200;       // Overlap between chunks
```

### Relevance Threshold (Backend\Services\RagService.cs)

```csharp
if (score < 0.7)  // Minimum relevance score (0-1)
    continue;
```

### Top-K Results (Backend\Services\RagService.cs)

```csharp
public async Task<(string Context, List<Citation> Citations)> RetrieveContextAsync(
    string query,
    int topK = 5,  // Number of chunks to retrieve
    ...
)
```

### Chat History Length (Frontend\src\components\ChatInterface.tsx)

```typescript
messages.slice(-10)  // Last 10 messages sent as context
```

## API Endpoints

### REST API

- `GET /` - API status and endpoints
- `POST /api/document/upload` - Upload PDF file
- `GET /api/document/status` - Check service status

### SignalR Hub

- `/chatHub` - WebSocket connection
  - `StreamChatResponse(message, history)` - Stream chat responses

## License

This project is provided as-is for educational and development purposes.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review backend logs in console
3. Check browser console for frontend errors
4. Verify Azure resource configurations

---

**Built with ❤️ using Microsoft technologies**
