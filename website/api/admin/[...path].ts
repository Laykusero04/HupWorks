import { handleAdminRequest } from '../_lib/handleAdminRequest'

export const config = {
  runtime: 'edge',
}

/** Vercel Edge handler — works with Vite `"type": "module"`. */
export default async function handler(request: Request): Promise<Response> {
  try {
    const url = new URL(request.url)
    let body: unknown = {}
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      try {
        body = await request.json()
      } catch {
        body = {}
      }
    }

    const result = await handleAdminRequest({
      path: url.pathname.replace(/\/+$/, '') || '/api/admin',
      method: request.method,
      searchParams: url.searchParams,
      body,
    })

    return new Response(JSON.stringify(result.body), {
      status: result.status,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    console.error('[api/admin]', err)
    return new Response(JSON.stringify({ ok: false, error: message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
}
