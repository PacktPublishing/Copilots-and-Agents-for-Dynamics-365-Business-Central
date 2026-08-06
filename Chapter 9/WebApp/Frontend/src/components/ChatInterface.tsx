import { useState, useEffect, useRef } from 'react';
import { MessageList } from './MessageList';
import { MessageInput } from './MessageInput';
import { DocumentUploader } from './DocumentUploader';
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
  const [isConnected, setIsConnected] = useState(true); // Start as true to allow typing
  const [useSummarization, setUseSummarization] = useState(false);
  const currentMessageRef = useRef<ChatMessage | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const connectToChat = async () => {
      try {
        await chatService.connect();
        setIsConnected(true);
        console.log('Chat service connected successfully');
      } catch (error) {
        console.error('Failed to connect to chat service:', error);
        // Keep isConnected true to allow user to type
        // Connection will be retried when sending message
      }
    };

    connectToChat();

    return () => {
      chatService.disconnect();
    };
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = async (messageText: string) => {
    if (isStreaming) return;

    // Add user message
    const userMessage: ChatMessage = {
      role: 'user',
      content: messageText,
      timestamp: new Date(),
    };
    setMessages((prev: ChatMessage[]) => [...prev, userMessage]);

    // Ensure connection before sending
    try {
      await chatService.connect();
      setIsConnected(true);
    } catch (error) {
      console.error('Failed to connect before sending:', error);
      setMessages((prev: ChatMessage[]) => [
        ...prev,
        {
          role: 'assistant',
          content: 'Failed to connect to chat service. Please check if the backend is running.',
          timestamp: new Date(),
        },
      ]);
      return;
    }

    // Initialize assistant message
    currentMessageRef.current = {
      role: 'assistant',
      content: '',
      timestamp: new Date(),
    };

    setMessages((prev: ChatMessage[]) => [...prev, currentMessageRef.current!]);
    setIsStreaming(true);

    try {
      await chatService.streamChatResponse(
        messageText,
        messages.length > 0 ? messages.slice(-10) : null, // Send last 10 messages as context
        useSummarization, // Pass summarization flag
        (response: StreamResponse) => {
          if (response.content) {
            // Update content
            currentMessageRef.current!.content += response.content;
          }

          if (response.citations && response.citations.length > 0) {
            // Add citations
            currentMessageRef.current!.citations = response.citations;
          }

          // Always update the messages array with current state
          setMessages((prev: ChatMessage[]) => {
            const newMessages = [...prev];
            if (newMessages.length > 0) {
              newMessages[newMessages.length - 1] = { ...currentMessageRef.current! };
            }
            return newMessages;
          });

          if (response.isComplete) {
            setIsStreaming(false);
          }
        },
        (error: Error) => {
          console.error('Streaming error:', error);
          currentMessageRef.current!.content += '\n\n[Error: Failed to get response]';
          setMessages((prev: ChatMessage[]) => [...prev.slice(0, -1), { ...currentMessageRef.current! }]);
          setIsStreaming(false);
          currentMessageRef.current = null;
        }
      );
    } catch (error) {
      console.error('Error sending message:', error);
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
          <Text className={styles.switchLabel} weight="semibold">Summarize Responses</Text>
          <Switch 
            checked={useSummarization}
            onChange={(_, data) => setUseSummarization(data.checked)}
          />
        </div>
      </div>

      <DocumentUploader />

      <div className={styles.chatContainer}>
        <div className={styles.messagesContainer}>
          <MessageList messages={messages} />
          <div ref={messagesEndRef} />
        </div>
        <MessageInput
          onSendMessage={handleSendMessage}
          disabled={!isConnected}
          isStreaming={isStreaming}
        />
      </div>
    </div>
  );
};
