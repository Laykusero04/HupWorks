import type { Plugin } from 'vite'
import { handleAdminRequest } from '../api/_lib/handleAdminRequest'

async function readJson(req: import('http').IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = []
  for await (const chunk of req) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk))
  }
  if (chunks.length === 0) return {}
  return JSON.parse(Buffer.concat(chunks).toString('utf8'))
}

function send(res: import('http').ServerResponse, status: number, body: unknown) {
  res.statusCode = status
  res.setHeader('Content-Type', 'application/json')
  res.end(JSON.stringify(body))
}

/** Local Vite middleware — production uses website/api/admin/[...path].ts on Vercel. */
export function adminApiPlugin(): Plugin {
  return {
    name: 'hupworks-admin-api',
    configureServer(server) {
      server.middlewares.use(async (req, res, next) => {
        if (!req.url?.startsWith('/api/admin')) return next()

        try {
          const url = new URL(req.url, 'http://localhost')
          const method = req.method ?? 'GET'
          const body =
            method === 'GET' || method === 'HEAD' ? {} : await readJson(req)
          const result = await handleAdminRequest({
            path: url.pathname,
            method,
            searchParams: url.searchParams,
            body,
          })
          return send(res, result.status, result.body)
        } catch (err) {
          const message =
            err && typeof err === 'object' && 'message' in err
              ? String((err as { message: unknown }).message)
              : err instanceof Error
                ? err.message
                : String(err)
          return send(res, 500, { ok: false, error: message })
        }
      })
    },
  }
}
