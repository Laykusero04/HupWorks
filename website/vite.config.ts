import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import { adminApiPlugin } from './server/adminApi'

export default defineConfig(({ mode }) => {
  // Make website/.env available to the admin API middleware (incl. SUPABASE_SECRET_KEY).
  const env = loadEnv(mode, process.cwd(), '')
  for (const [key, value] of Object.entries(env)) {
    if (process.env[key] === undefined) process.env[key] = value
  }

  return {
    plugins: [react(), adminApiPlugin()],
    server: {
      port: 5173,
    },
  }
})
