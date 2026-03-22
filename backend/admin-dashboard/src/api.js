import axios from 'axios';

const API_BASE_URL = '/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor: attach JWT token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor: handle token refresh on 401
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      try {
        const refreshToken = localStorage.getItem('refresh_token');
        if (refreshToken) {
          const res = await axios.post(`${API_BASE_URL}/token/refresh/`, {
            refresh: refreshToken,
          });
          localStorage.setItem('access_token', res.data.access);
          if (res.data.refresh) {
            localStorage.setItem('refresh_token', res.data.refresh);
          }
          originalRequest.headers.Authorization = `Bearer ${res.data.access}`;
          return api(originalRequest);
        }
      } catch (refreshError) {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    return Promise.reject(error);
  }
);

// ──────────────── AUTH ────────────────
export const login = (username, password) =>
  api.post('/token/', { username, password });

// ──────────────── DASHBOARD ────────────────
export const getDashboard = () => api.get('/admin/dashboard/');

// ──────────────── USERS ────────────────
export const getUsers = (page = 1) => api.get(`/admin/users/?page=${page}`);
export const getUser = (id) => api.get(`/admin/users/${id}/`);
export const deleteUser = (id) => api.delete(`/admin/users/${id}/`);

// ──────────────── DOCUMENTS ────────────────
export const getDocuments = (page = 1) => api.get(`/admin/documents/?page=${page}`);
export const deleteDocument = (id) => api.delete(`/admin/documents/${id}/`);

// ──────────────── APPLICATIONS ────────────────
export const getApplications = (page = 1) => api.get(`/admin/applications/?page=${page}`);
export const updateApplicationStatus = (id, status) =>
  api.patch(`/admin/applications/${id}/update_status/`, { status });

// ──────────────── NOTIFICATIONS ────────────────
export const getNotifications = (page = 1) => api.get(`/admin/notifications/?page=${page}`);
export const markNotificationRead = (id) =>
  api.patch(`/admin/notifications/${id}/mark_read/`);
export const deleteNotification = (id) => api.delete(`/admin/notifications/${id}/`);

// ──────────────── EXPIRY CHECK ────────────────
export const checkExpiry = () => api.post('/admin/check-expiry/');

export default api;
