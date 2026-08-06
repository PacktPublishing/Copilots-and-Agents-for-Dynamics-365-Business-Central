import axios from 'axios';

const API_BASE_URL = '/api';

export interface UploadResponse {
  message: string;
  fileName: string;
  chunksIndexed: number;
}

export const uploadDocument = async (file: File): Promise<UploadResponse> => {
  const formData = new FormData();
  formData.append('file', file);

  const response = await axios.post<UploadResponse>(
    `${API_BASE_URL}/document/upload`,
    formData,
    {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    }
  );

  return response.data;
};

export const checkStatus = async (): Promise<{ status: string; message: string }> => {
  const response = await axios.get(`${API_BASE_URL}/document/status`);
  return response.data;
};
