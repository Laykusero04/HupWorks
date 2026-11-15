import { createClient } from '@supabase/supabase-js'

// Public browser credentials only (project URL + anon/publishable key).
// The secret/service key must never be used here; it lives server-side only.
const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const isSupabaseConfigured = Boolean(url && anonKey)

if (!isSupabaseConfigured && import.meta.env.DEV) {
  console.warn('Supabase browser client is not configured (see website/.env.example).')
}

export const supabase = createClient(
  url || 'http://localhost:54321',
  anonKey || 'missing-anon-key',
  { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false } },
)
