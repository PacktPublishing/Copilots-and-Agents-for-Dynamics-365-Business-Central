using Azure;
using Azure.AI.OpenAI;
using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Backend.Hubs;
using Backend.Services;
using Microsoft.Extensions.AI;
using OpenAI.Chat;
using OpenAI.Embeddings;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .WriteTo.Console()
    .CreateLogger();

builder.Host.UseSerilog();

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure CORS
var allowedOrigins = builder.Configuration.GetSection("CORS:AllowedOrigins").Get<string[]>() 
    ?? new[] { "http://localhost:5173", "http://localhost:5174", "http://localhost:3000" };

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Configure SignalR
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = builder.Environment.IsDevelopment();
    options.MaximumReceiveMessageSize = 102400; // 100 KB
});

// Configure Azure AI Search
var searchEndpoint = builder.Configuration["AzureAISearch:Endpoint"] 
    ?? throw new InvalidOperationException("AzureAISearch:Endpoint is not configured");
var searchApiKey = builder.Configuration["AzureAISearch:ApiKey"] 
    ?? throw new InvalidOperationException("AzureAISearch:ApiKey is not configured");
var indexName = builder.Configuration["AzureAISearch:IndexName"] ?? "pdf-documents";

var searchCredential = new AzureKeyCredential(searchApiKey);

builder.Services.AddSingleton(new SearchIndexClient(new Uri(searchEndpoint), searchCredential));
builder.Services.AddSingleton(new SearchClient(new Uri(searchEndpoint), indexName, searchCredential));

// Configure Azure OpenAI
var openAiEndpoint = builder.Configuration["AzureOpenAI:Endpoint"] 
    ?? throw new InvalidOperationException("AzureOpenAI:Endpoint is not configured");
var openAiApiKey = builder.Configuration["AzureOpenAI:ApiKey"] 
    ?? throw new InvalidOperationException("AzureOpenAI:ApiKey is not configured");
var chatDeployment = builder.Configuration["AzureOpenAI:ChatDeploymentName"] 
    ?? throw new InvalidOperationException("AzureOpenAI:ChatDeploymentName is not configured");
var embeddingDeployment = builder.Configuration["AzureOpenAI:EmbeddingDeploymentName"] 
    ?? throw new InvalidOperationException("AzureOpenAI:EmbeddingDeploymentName is not configured");

// Create Azure OpenAI client
var azureClient = new AzureOpenAIClient(
    new Uri(openAiEndpoint),
    new AzureKeyCredential(openAiApiKey));

// Get ChatClient for Agent Framework orchestration
var chatClient = azureClient.GetChatClient(chatDeployment);
builder.Services.AddSingleton(chatClient);

// Register IChatClient for Microsoft Agent Framework (using the extension method from Microsoft.Extensions.AI.OpenAI)
builder.Services.AddSingleton<IChatClient>(chatClient.AsIChatClient());

// Get EmbeddingClient for RAG embeddings (direct Azure.AI.OpenAI SDK usage)
var embeddingClient = azureClient.GetEmbeddingClient(embeddingDeployment);
builder.Services.AddSingleton(embeddingClient);

// Register application services
builder.Services.AddScoped<RagService>();
builder.Services.AddScoped<ChatService>();
builder.Services.AddScoped<AgentOrchestrationService>();
builder.Services.AddScoped<DocumentProcessor>();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFrontend");

// Serve static files from wwwroot (frontend React app)
app.UseDefaultFiles();
app.UseStaticFiles();

app.UseAuthorization();

app.MapControllers();
app.MapHub<ChatHub>("/chatHub");

app.MapGet("/", () => Results.Ok(new
{
    status = "running",
    message = "RAG Chat API with Microsoft Agent Framework",
    endpoints = new
    {
        chat = "/chatHub (SignalR)",
        upload = "/api/document/upload",
        swagger = "/swagger"
    }
}));

Log.Information("Starting RAG Chat API on http://localhost:5000");

app.Run();
