import type { VercelRequest, VercelResponse } from '@vercel/node'
import { handleAdminRequest } from '../../server/handleAdminRequest'

function pathFromQuery(path: string | string[] | undefined): string {
  if (!path) return '/api/admin'
  const parts = Array.isArray(path) ? path : [path]
  return `/api/admin/${parts.join('/')}`
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const pathname = pathFromQuery(req.query.path)
  const searchParams = new URLSearchParams()
  for (const [key, value] of Object.entries(req.query)) {
    if (key === 'path' || value == null) continue
    if (Array.isArray(value)) {
      for (const item of value) searchParams.append(key, item)
    } else {
      searchParams.set(key, value)
    }
  }

  const result = await handleAdminRequest({
    path: pathname,
    method: req.method ?? 'GET',
    searchParams,
    body: req.body ?? {},
  })

  res.status(result.status).json(result.body)
}
