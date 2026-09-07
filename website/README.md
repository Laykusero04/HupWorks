# HupWorks Admin Website

React (Vite) admin shell for the same Supabase project as the Flutter app.

## Setup (local)

```bash
cd website
cp .env.example .env
# From repo root .env, copy:
#   SUPABASE_URL          → VITE_SUPABASE_URL
#   SUPABASE_ANON_KEY     → VITE_SUPABASE_ANON_KEY
#   SUPABASE_SECRET_KEY   → SUPABASE_SECRET_KEY  (no VITE_ prefix)
npm install
npm run dev
```

Open http://localhost:5173 — Overview should show **Connected** and live KPI counts.

Restart `npm run dev` after any `.env` change.

## Deploy to Vercel

Your import settings should be:

| Setting | Value |
|---------|--------|
| Root Directory | `website` |
| Framework Preset | Vite |
| Build Command | `npm run build` (default) |
| Output Directory | `dist` (default) |

### Environment Variables (add before Deploy)

In **Environment Variables** on the same New Project screen (or Project → Settings → Environment Variables):

| Name | Value | Notes |
|------|--------|--------|
| `VITE_SUPABASE_URL` | `https://….supabase.co` | Same as Flutter `SUPABASE_URL` |
| `VITE_SUPABASE_ANON_KEY` | anon key | Optional for current admin UI |
| `SUPABASE_SECRET_KEY` | **service role** key | Required for `/api/admin/*`. Never use `VITE_` prefix |

Apply to **Production**, **Preview**, and **Development**.

Then click **Deploy**. After deploy, open the URL and check Overview → Connected.

SPA routes (`/verification`, `/catalog`, …) are handled by `vercel.json` rewrites. Admin APIs run as Vercel serverless functions under `api/admin/`.

## How Supabase is connected

- Browser talks to `/api/admin/*`.
- Locally: Vite middleware in `server/adminApi.ts`.
- On Vercel: `api/admin/[...path].ts`.
- Both call `server/handleAdminRequest.ts` with `SUPABASE_SECRET_KEY` (service role) so admin can read verification + reports despite RLS.
- Never put the secret in `VITE_*` — that would ship it to the browser.

## Notes

- Product blueprint: [`docs/ADMIN_PANEL.md`](../docs/ADMIN_PANEL.md)
- Routes: Overview, Verification, Reports, Users, Jobs & orders, Catalog
