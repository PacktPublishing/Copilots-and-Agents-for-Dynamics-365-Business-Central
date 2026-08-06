import { useState } from 'react';
import {
  Button,
  makeStyles,
  tokens,
  Text,
  Spinner,
} from '@fluentui/react-components';
import { ArrowUploadRegular, CheckmarkCircleRegular } from '@fluentui/react-icons';
import { uploadDocument } from '../services/apiService';

const useStyles = makeStyles({
  container: {
    padding: tokens.spacingVerticalL,
    borderBottom: `1px solid ${tokens.colorNeutralStroke1}`,
    backgroundColor: tokens.colorNeutralBackground2,
  },
  content: {
    display: 'flex',
    alignItems: 'center',
    gap: tokens.spacingHorizontalM,
    flexWrap: 'wrap',
  },
  fileInput: {
    display: 'none',
  },
  status: {
    display: 'flex',
    alignItems: 'center',
    gap: tokens.spacingHorizontalS,
    color: tokens.colorPaletteGreenForeground1,
  },
  error: {
    color: tokens.colorPaletteRedForeground1,
  },
});

interface DocumentUploaderProps {
  onUploadComplete?: () => void;
}

export const DocumentUploader: React.FC<DocumentUploaderProps> = ({ onUploadComplete }) => {
  const styles = useStyles();
  const [uploading, setUploading] = useState(false);
  const [uploadStatus, setUploadStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.name.endsWith('.pdf')) {
      setError('Please select a PDF file');
      return;
    }

    setUploading(true);
    setError(null);
    setUploadStatus(null);

    try {
      const response = await uploadDocument(file);
      setUploadStatus(
        `${response.fileName} uploaded successfully (${response.chunksIndexed} chunks indexed)`
      );
      if (onUploadComplete) {
        onUploadComplete();
      }
    } catch (err: any) {
      console.error('Upload error:', err);
      const errorMessage = err.response?.data?.error || err.message || 'Failed to upload document';
      setError(errorMessage);
    } finally {
      setUploading(false);
      e.target.value = ''; // Reset file input
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.content}>
        <input
          type="file"
          id="file-upload"
          className={styles.fileInput}
          accept=".pdf"
          onChange={handleFileChange}
          disabled={uploading}
        />
        <Button
          appearance="primary"
          icon={uploading ? <Spinner size="tiny" /> : <ArrowUploadRegular />}
          disabled={uploading}
          onClick={() => document.getElementById('file-upload')?.click()}
        >
          {uploading ? 'Uploading...' : 'Upload PDF'}
        </Button>

        {uploadStatus && (
          <div className={styles.status}>
            <CheckmarkCircleRegular />
            <Text size={300}>{uploadStatus}</Text>
          </div>
        )}

        {error && (
          <Text size={300} className={styles.error}>
            {error}
          </Text>
        )}
      </div>
    </div>
  );
};
