import { ChatMessage } from '../services/chatService';
import { CitationCard } from './CitationCard';
import {
  Card,
  Text,
  makeStyles,
  tokens,
  Avatar,
} from '@fluentui/react-components';
import { PersonRegular, BotRegular } from '@fluentui/react-icons';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

const useStyles = makeStyles({
  messageList: {
    display: 'flex',
    flexDirection: 'column',
    gap: tokens.spacingVerticalL,
    padding: tokens.spacingVerticalXL,
    overflowY: 'auto',
    flex: 1,
  },
  messageCard: {
    maxWidth: '80%',
    minWidth: '200px',
    width: 'auto',
  },
  userMessage: {
    alignSelf: 'flex-end',
    backgroundColor: tokens.colorBrandBackground,
  },
  assistantMessage: {
    alignSelf: 'flex-start',
  },
  messageContent: {
    display: 'flex',
    gap: tokens.spacingHorizontalM,
    padding: tokens.spacingVerticalM,
    width: '100%',
    overflow: 'visible',
  },
  avatar: {
    flexShrink: 0,
  },
  textContent: {
    flex: 1,
    minWidth: 0,
    wordWrap: 'break-word',
    overflowWrap: 'break-word',
    whiteSpace: 'pre-wrap',
    overflow: 'visible',
    '& p': {
      marginTop: 0,
      marginBottom: tokens.spacingVerticalS,
    },
    '& p:last-child': {
      marginBottom: 0,
    },
    '& code': {
      backgroundColor: tokens.colorNeutralBackground3,
      padding: '2px 6px',
      borderRadius: tokens.borderRadiusSmall,
      fontFamily: tokens.fontFamilyMonospace,
    },
    '& pre': {
      backgroundColor: tokens.colorNeutralBackground3,
      padding: tokens.spacingVerticalM,
      borderRadius: tokens.borderRadiusMedium,
      overflowX: 'auto',
    },
  },
  citations: {
    marginTop: tokens.spacingVerticalM,
    paddingLeft: '48px',
  },
  citationsHeader: {
    marginBottom: tokens.spacingVerticalS,
    fontWeight: tokens.fontWeightSemibold,
  },
  emptyState: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    height: '100%',
    color: tokens.colorNeutralForeground3,
  },
});

interface MessageListProps {
  messages: ChatMessage[];
}

export const MessageList: React.FC<MessageListProps> = ({ messages }) => {
  const styles = useStyles();

  if (messages.length === 0) {
    return (
      <div className={styles.emptyState}>
        <Text size={500}>Start a conversation by asking a question about your documents</Text>
      </div>
    );
  }

  return (
    <div className={styles.messageList}>
      {messages.map((message, index) => (
        <div key={index}>
          <Card
            className={`${styles.messageCard} ${
              message.role === 'user' ? styles.userMessage : styles.assistantMessage
            }`}
          >
            <div className={styles.messageContent}>
              <Avatar
                className={styles.avatar}
                icon={message.role === 'user' ? <PersonRegular /> : <BotRegular />}
                color={message.role === 'user' ? 'brand' : 'colorful'}
              />
              <div className={styles.textContent}>
                <ReactMarkdown remarkPlugins={[remarkGfm]}>
                  {message.content}
                </ReactMarkdown>
              </div>
            </div>
          </Card>

          {message.citations && message.citations.length > 0 && (
            <div className={styles.citations}>
              <Text className={styles.citationsHeader}>Sources:</Text>
              {message.citations.map((citation, citationIndex) => (
                <CitationCard
                  key={citationIndex}
                  citation={citation}
                  index={citationIndex}
                />
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  );
};
