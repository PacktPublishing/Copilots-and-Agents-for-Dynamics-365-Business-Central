import * as signalR from '@microsoft/signalr';

export interface ChatMessage {
  role: string;
  content: string;
  citations?: Citation[];
  timestamp: Date;
}

export interface Citation {
  documentId: string;
  title: string;
  chunkText: string;
  sourceUrl?: string;
  relevanceScore: number;
  pageNumber?: number;
}

export interface StreamResponse {
  content?: string;
  citations?: Citation[];
  isComplete: boolean;
}

class ChatService {
  private connection: signalR.HubConnection;
  private isConnected = false;

  constructor() {
    // Use current domain for SignalR connection (works on localhost and Azure)
    const signalRUrl = `${window.location.origin}/chatHub`;
    
    this.connection = new signalR.HubConnectionBuilder()
      .withUrl(signalRUrl, {
        skipNegotiation: false,
        transport: signalR.HttpTransportType.WebSockets,
      })
      .withAutomaticReconnect()
      .configureLogging(signalR.LogLevel.Information)
      .build();

    this.connection.onreconnecting((error) => {
      console.warn('SignalR reconnecting...', error);
    });

    this.connection.onreconnected((connectionId) => {
      console.log('SignalR reconnected:', connectionId);
    });

    this.connection.onclose((error) => {
      console.error('SignalR connection closed:', error);
      this.isConnected = false;
    });
  }

  async connect(): Promise<void> {
    if (this.isConnected) {
      return;
    }

    try {
      await this.connection.start();
      this.isConnected = true;
      console.log('SignalR connected');
    } catch (error) {
      console.error('Error connecting to SignalR:', error);
      throw error;
    }
  }

  async disconnect(): Promise<void> {
    if (this.connection) {
      await this.connection.stop();
      this.isConnected = false;
    }
  }

  async streamChatResponse(
    message: string,
    history: ChatMessage[] | null,
    useSummarization: boolean,
    onChunk: (response: StreamResponse) => void,
    onError?: (error: Error) => void
  ): Promise<void> {
    if (!this.isConnected) {
      await this.connect();
    }

    try {
      this.connection.stream('StreamChatResponse', message, history, useSummarization).subscribe({
        next: (response: StreamResponse) => {
          onChunk(response);
        },
        error: (error) => {
          console.error('Streaming error:', error);
          if (onError) {
            onError(error);
          }
        },
        complete: () => {
          console.log('Streaming complete');
        },
      });
    } catch (error) {
      console.error('Error starting stream:', error);
      if (onError) {
        onError(error as Error);
      }
    }
  }
}

export const chatService = new ChatService();
