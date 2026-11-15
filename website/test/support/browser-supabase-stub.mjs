// Replaces the browser client module (src/lib/supabase.ts) for adminApi tests.
// The session is controlled by tests through globalThis.__hupFakeBrowserSession.
export const supabase = {
  auth: {
    async getSession() {
      const impl = globalThis.__hupFakeBrowserSession
      return impl ? impl() : { data: { session: null }, error: null }
    },
  },
}
