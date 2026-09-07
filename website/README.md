# HupWorks Admin Website

React (Vite) admin shell for the same Supabase project as the Flutter app.

## Setup

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

## How Supabase is connected

- Browser talks to `/api/admin/*` on the Vite dev server.
- The middleware uses `SUPABASE_SECRET_KEY` (service role) so admin can read verification + reports despite RLS.
- Never put the secret in `VITE_*` — that would ship it to the browser.

## Notes

- Product blueprint: [`docs/ADMIN_PANEL.md`](../docs/ADMIN_PANEL.md)
- Routes: Overview, Verification, Reports, Users, Jobs & orders, Catalog
