const BASE = 'http://internal.invalid'

/** Returns a safe in-app path (with query/hash) or '/'. Rejects schemes, //, backslashes, control chars, /login. */
export function safeNext(raw: string | null | undefined): string {
  if (!raw) return '/'
  if (!raw.startsWith('/') || raw.startsWith('//')) return '/'
  // eslint-disable-next-line no-control-regex
  if (/[\\\u0000-\u001f\u007f]/.test(raw)) return '/'
  try {
    const u = new URL(raw, BASE)
    if (u.origin !== BASE) return '/'
    if (u.pathname === '/login' || u.pathname.startsWith('/login/')) return '/'
  } catch {
    return '/'
  }
  return raw
}

export function loginUrl(next?: string): string {
  const safe = safeNext(next)
  return safe === '/' ? '/login' : `/login?next=${encodeURIComponent(safe)}`
}
