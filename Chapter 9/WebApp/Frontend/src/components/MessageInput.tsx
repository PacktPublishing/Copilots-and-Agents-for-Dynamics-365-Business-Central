import { useState } from 'react';
import {
  Button,
  Textarea,
  makeStyles,
  tokens,
  Spinner,
} from '@fluentui/react-components';
import { SendRegular } from '@fluentui/react-icons';

const useStyles = makeStyles({
  inputContainer: {
    display: 'flex',
    gap: tokens.spacingHorizontalM,
    padding: tokens.spacingVerticalXL,
    borderTop: `1px solid ${tokens.colorNeutralStroke1}`,
    backgroundColor: tokens.colorNeutralBackground1,
  },
  textarea: {
    flex: 1,
    minHeight: '80px',
  },
  sendButton: {
    alignSelf: 'flex-end',
  },
});

interface MessageInputProps {
  onSendMessage: (message: string) => void;
  disabled?: boolean;
  isStreaming?: boolean;
}

export const MessageInput: React.FC<MessageInputProps> = ({
  onSendMessage,
  disabled = false,
  isStreaming = false,
}) => {
  const styles = useStyles();
  const [message, setMessage] = useState('');

  const handleSend = () => {
    if (message.trim() && !disabled) {
      onSendMessage(message.trim());
      setMessage('');
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className={styles.inputContainer}>
      <Textarea
        className={styles.textarea}
        placeholder="Ask a question about your documents..."
        value={message}
        onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setMessage(e.target.value)}
        onKeyDown={handleKeyDown}
        disabled={disabled}
        resize="vertical"
      />
      <Button
        className={styles.sendButton}
        appearance="primary"
        icon={isStreaming ? <Spinner size="tiny" /> : <SendRegular />}
        onClick={handleSend}
        disabled={disabled || !message.trim() || isStreaming}
      >
        {isStreaming ? 'Sending...' : 'Send'}
      </Button>
    </div>
  );
};
