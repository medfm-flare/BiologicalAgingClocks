import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: '/',  // Explicitly set to root for consistency in dev/prod
  root: '.',
  build: {
    outDir: 'dist',
    minify: 'esbuild',
  },
  server: {
    host: '0.0.0.0',
    port: 5175,
    proxy: {
      '/api': {
        target: 'http://localhost:8009',  // Your FastAPI port
        changeOrigin: true,  // Handles host header changes
        secure: false,  // If not using HTTPS in dev
      },
    },
  },
  preview: {
    host: '0.0.0.0',
    port: 5175,
  },
});