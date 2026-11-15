import { handleAdminRequest } from './_lib/handleAdminRequest'

export const config = {
  runtime: 'edge',
}

/**
 * Single-file Vercel Edge entry for all /api/admin traffic.
 * vercel.json rewrites /api/admin/:path* → /api/admin?__path=:path* so nested
 * and flat segments both reach this function (non-Next catch-alls do not).
 */
export default async function handler(request: Request): Promise<Response> {
  try {
    const url = new URL(request.url)
    const searchParams = new URLSearchParams(url.searchParams)
    const rewritten = searchParams.get('__path')
    searchParams.delete('__path')

    const path = rewritten
      ? `/api/admin/${rewritten}`.replace(/\/+$/, '') || '/api/admin'
      : url.pathname.replace(/\/+$/, '') || '/api/admin'

    const result = await handleAdminRequest({
      path,
      method: request.method,
      searchParams,
      readBody: () => request.json().catch(() => ({})),
      authorization: request.headers.get('authorization'),
      ip: request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? null,
    })

    return new Response(JSON.stringify(result.body), {
      status: result.status,
      headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
    })
  } catch (err) {
    console.error('[api/admin]', err)
    return new Response(JSON.stringify({ ok: false, error: 'Request failed' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
    })
  }
}
