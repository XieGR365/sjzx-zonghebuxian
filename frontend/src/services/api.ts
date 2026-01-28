import axios from 'axios';
import type { ApiResponse, Record, QueryParams, QueryResult, FilterOptions } from '@/types';

const api = axios.create({
  baseURL: '/api',
  timeout: 30000,
});

api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export const recordApi = {
  upload: (
    file: File
  ): Promise<
    ApiResponse<{
      insertedCount: number;
      updatedCount: number;
      insertedIds: number[];
      updatedIds: number[];
    }>
  > => {
    const formData = new FormData();
    formData.append('file', file);
    return api.post('/records/upload', formData);
  },

  query: (params: QueryParams): Promise<ApiResponse<QueryResult>> => {
    return api.get('/records/query', { params });
  },

  getDetail: (id: number): Promise<ApiResponse<Record>> => {
    return api.get(`/records/detail/${id}`);
  },

  getDatacenters: (): Promise<ApiResponse<string[]>> => {
    return api.get('/records/datacenters');
  },

  getFilterOptions: (): Promise<ApiResponse<FilterOptions>> => {
    return api.get('/records/filter-options');
  },

  clearAll: (): Promise<ApiResponse> => {
    return api.delete('/records/clear');
  },

  export: (params: QueryParams, format: string = 'excel'): Promise<Blob> => {
    return api.get('/records/export', {
      params: { ...params, format },
      responseType: 'blob',
    });
  },

  getJumpFiberStatistics: (): Promise<ApiResponse<any>> => {
    return api.get('/records/statistics/jump-fiber');
  },

  exportJumpFiberStatistics: (): Promise<Blob> => {
    return api.get('/records/statistics/jump-fiber/export', {
      responseType: 'blob',
    });
  },
};

export default api;
