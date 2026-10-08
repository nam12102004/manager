import axios from 'axios';

// Create Axios Instance
// In development, Vite proxies '/api' to 'http://localhost:5050'
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

// Response Interceptor: Unwrap ApiResponse<T>
api.interceptors.response.use(
  (response) => {
    // If the response payload has format { success, data, message }
    if (response.data && typeof response.data === 'object' && 'success' in response.data) {
      if (!response.data.success) {
        return Promise.reject(new Error(response.data.message || 'Thao tác không thành công'));
      }
      return response.data; // has { success, data, message }
    }
    return { success: true, data: response.data, message: null };
  },
  (error) => {
    let message = 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
    if (error.response?.data?.message) {
      message = error.response.data.message;
    } else if (error.response?.data?.title) {
      message = error.response.data.title;
    } else if (error.message) {
      message = error.message;
    }
    return Promise.reject(new Error(message));
  }
);

export default api;
