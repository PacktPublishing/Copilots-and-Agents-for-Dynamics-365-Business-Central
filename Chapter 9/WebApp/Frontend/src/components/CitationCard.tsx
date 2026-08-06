import { Citation } from '../services/chatService';
import {
  Card,
  CardHeader,
  Text,
  makeStyles,
  tokens,
  Badge,
} from '@fluentui/react-components';
import { DocumentRegular } from '@fluentui/react-icons';

const useStyles = makeStyles({
  card: {
    marginBottom: tokens.spacingVerticalM,
    maxWidth: '100%',
  },
  header: {
    display: 'flex',
    alignItems: 'center',
    gap: tokens.spacingHorizontalS,
  },
  content: {
    marginTop: tokens.spacingVerticalS,
    fontSize: tokens.fontSizeBase200,
    color: tokens.colorNeutralForeground2,
    lineHeight: '1.5',
  },
  metadata: {
    display: 'flex',
    gap: tokens.spacingHorizontalM,
    marginTop: tokens.spacingVerticalS,
    fontSize: tokens.fontSizeBase200,
  },
});

interface CitationCardProps {
  citation: Citation;
  index: number;
}

export const CitationCard: React.FC<CitationCardProps> = ({ citation, index }) => {
  const styles = useStyles();

  return (
    <Card className={styles.card} size="small">
      <CardHeader
        header={
          <div className={styles.header}>
            <DocumentRegular />
            <Text weight="semibold">
              [{index + 1}] {citation.title}
            </Text>
          </div>
        }
      />
      <div className={styles.content}>
        <Text>{citation.chunkText}</Text>
        <div className={styles.metadata}>
          {citation.pageNumber && (
            <Badge appearance="outline">Page {citation.pageNumber}</Badge>
          )}
          <Badge appearance="outline">
            Relevance: {(citation.relevanceScore * 100).toFixed(0)}%
          </Badge>
        </div>
      </div>
    </Card>
  );
};
