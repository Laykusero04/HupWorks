// Replaces '@supabase/supabase-js' in tests (see loader.mjs). Delegates to the
// factory installed by test/support/fake-supabase.ts. Never opens a connection.
export function createClient(url, key, options) {
  const factory = globalThis.__hupFakeSupabaseFactory
  if (typeof factory !== 'function') {
    throw new Error('test: fake Supabase client was not installed')
  }
  return factory(url, key, options)
}
