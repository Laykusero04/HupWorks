/**
 * Applies report + soft-block SQL to Supabase via the Management API
 * or a direct Postgres URL.
 *
 * Usage:
 *   SUPABASE_ACCESS_TOKEN=... node tools/apply_report_block_sql.mjs
 *   DATABASE_URL=postgres://... node tools/apply_report_block_sql.mjs
 *
 * Without credentials, prints the SQL path to paste in the SQL Editor.
 */
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(__dirname, '..')
const sqlPath = path.join(root, 'migrations', '0039_user_blocks.sql')
const sql = fs.readFileSync(sqlPath, 'utf8')

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return
  for (const line of fs.readFileSync(filePath, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/)
    if (!m) continue
    if (process.env[m[1]] == null) process.env[m[1]] = m[2].trim()
  }
}

loadEnvFile(path.join(root, '.env'))
loadEnvFile(path.join(root, 'website', '.env'))

const projectUrl = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL || ''
const projectRef = (() => {
  try {
    return new URL(projectUrl).hostname.split('.')[0]
  } catch {
    return ''
  }
})()

async function applyViaManagementApi() {
  const token = process.env.SUPABASE_ACCESS_TOKEN
  if (!token || !projectRef) return false

  const res = await fetch(
    `https://api.supabase.com/v1/projects/${projectRef}/database/query`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query: sql }),
    },
  )
  const text = await res.text()
  if (!res.ok) {
    throw new Error(`Management API ${res.status}: ${text.slice(0, 500)}`)
  }
  console.log('Applied via Supabase Management API.')
  return true
}

async function applyViaDatabaseUrl() {
  const dbUrl = process.env.DATABASE_URL || process.env.SUPABASE_DB_URL
  if (!dbUrl) return false

  const pg = await import('pg')
  const client = new pg.default.Client({
    connectionString: dbUrl,
    ssl: { rejectUnauthorized: false },
  })
  await client.connect()
  try {
    await client.query(sql)
    console.log('Applied via DATABASE_URL.')
  } finally {
    await client.end()
  }
  return true
}

async function verifyRest() {
  const url = process.env.SUPABASE_URL
  const key = process.env.SUPABASE_SECRET_KEY
  if (!url || !key) return
  const res = await fetch(`${url}/rest/v1/user_reports?select=id&limit=1`, {
    headers: { apikey: key, Authorization: `Bearer ${key}` },
  })
  const body = await res.text()
  console.log('Verify user_reports:', res.status, body.slice(0, 200))
  const blocks = await fetch(`${url}/rest/v1/user_blocks?select=id&limit=1`, {
    headers: { apikey: key, Authorization: `Bearer ${key}` },
  })
  const blocksBody = await blocks.text()
  console.log('Verify user_blocks:', blocks.status, blocksBody.slice(0, 200))
}

async function main() {
  try {
    if (await applyViaManagementApi()) {
      await verifyRest()
      return
    }
    if (await applyViaDatabaseUrl()) {
      await verifyRest()
      return
    }
    console.error(
      [
        'Could not apply automatically (need SUPABASE_ACCESS_TOKEN or DATABASE_URL).',
        `Paste this file in Supabase SQL Editor: ${sqlPath}`,
        'Then re-run this script to verify, or refresh the Admin Reports page.',
      ].join('\n'),
    )
    process.exitCode = 2
  } catch (err) {
    console.error(err)
    process.exitCode = 1
  }
}

await main()
