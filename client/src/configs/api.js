import axios from 'axios';

// Use environment variable if set, otherwise use relative /api (for same-domain deployment)
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api'
});

export default api;
