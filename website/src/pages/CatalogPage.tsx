import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  fetchCategories,
  updateCategory,
  type CategoryRow,
} from '../lib/adminApi'

const LOCALES = [
  { code: 'en', label: 'English' },
  { code: 'nl', label: 'Nederlands' },
  { code: 'bn', label: 'বাংলা' },
] as const

type LocaleCode = (typeof LOCALES)[number]['code']

type Draft = {
  icon: string
  nameI18n: Record<LocaleCode, string>
  descriptionI18n: Record<LocaleCode, string>
}

function asMap(raw: Record<string, string> | null | undefined): Record<string, string> {
  if (!raw || typeof raw !== 'object') return {}
  return raw
}

function toDraft(row: CategoryRow): Draft {
  const names = asMap(row.name_i18n)
  const descriptions = asMap(row.description_i18n)
  return {
    icon: row.icon ?? '',
    nameI18n: {
      en: names.en ?? row.name ?? '',
      nl: names.nl ?? '',
      bn: names.bn ?? '',
    },
    descriptionI18n: {
      en: descriptions.en ?? row.description ?? '',
      nl: descriptions.nl ?? '',
      bn: descriptions.bn ?? '',
    },
  }
}

function missingLocales(draft: Draft): LocaleCode[] {
  return LOCALES.map((l) => l.code).filter((code) => !draft.nameI18n[code]?.trim())
}

export function CatalogPage() {
  const [rows, setRows] = useState<CategoryRow[]>([])
  const [drafts, setDrafts] = useState<Record<string, Draft>>({})
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [savingId, setSavingId] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [expandedId, setExpandedId] = useState<string | null>(null)
  const [filter, setFilter] = useState<'all' | 'preset' | 'custom' | 'incomplete'>('all')

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetchCategories()
      setRows(res.rows)
      const next: Record<string, Draft> = {}
      for (const row of res.rows) next[row.id] = toDraft(row)
      setDrafts(next)
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    return rows.filter((row) => {
      const draft = drafts[row.id] ?? toDraft(row)
      if (filter === 'preset' && row.is_custom) return false
      if (filter === 'custom' && !row.is_custom) return false
      if (filter === 'incomplete' && missingLocales(draft).length === 0) return false
      if (!q) return true
      const hay = [
        row.name,
        row.icon,
        ...Object.values(draft.nameI18n),
        ...Object.values(draft.descriptionI18n),
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase()
      return hay.includes(q)
    })
  }, [rows, drafts, query, filter])

  function patchDraft(id: string, updater: (prev: Draft) => Draft) {
    setDrafts((prev) => {
      const current = prev[id] ?? toDraft(rows.find((r) => r.id === id)!)
      return { ...prev, [id]: updater(current) }
    })
  }

  async function onSave(id: string) {
    const draft = drafts[id]
    if (!draft) return
    setSavingId(id)
    setError(null)
    try {
      const res = await updateCategory({
        id,
        nameI18n: draft.nameI18n,
        descriptionI18n: draft.descriptionI18n,
        icon: draft.icon,
      })
      if (res.row) {
        setRows((prev) => prev.map((r) => (r.id === id ? res.row! : r)))
        setDrafts((prev) => ({ ...prev, [id]: toDraft(res.row!) }))
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setSavingId(null)
    }
  }

  return (
    <div className="page queue-page">
      <div className="queue-top">
        <div>
          <h1>Catalog</h1>
          <p className="lede tight">
            Edit category names and descriptions for English, Dutch, and Bengali. The English name
            stays the canonical key used for matching.
          </p>
        </div>
        <div className="queue-tools">
          <input
            className="search-input"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search categories…"
          />
          <button type="button" className="btn ghost" onClick={() => void load()} disabled={loading}>
            Refresh
          </button>
        </div>
      </div>

      <div className="tabs">
        {(
          [
            ['all', 'All'],
            ['preset', 'Presets'],
            ['custom', 'Custom'],
            ['incomplete', 'Missing translation'],
          ] as const
        ).map(([key, label]) => (
          <button
            key={key}
            type="button"
            className={filter === key ? 'tab active' : 'tab'}
            onClick={() => setFilter(key)}
          >
            {label}
          </button>
        ))}
      </div>

      {error && (
        <section className="status-banner bad">
          <strong>Error</strong>
          <span>{error}</span>
        </section>
      )}

      {loading && <section className="panel empty">Loading categories…</section>}

      {!loading && !error && filtered.length === 0 && (
        <section className="panel empty">No categories match.</section>
      )}

      <div className="card-list">
        {filtered.map((row) => {
          const draft = drafts[row.id] ?? toDraft(row)
          const open = expandedId === row.id
          const missing = missingLocales(draft)
          const busy = savingId === row.id

          return (
            <article key={row.id} className="panel catalog-card">
              <button
                type="button"
                className="catalog-summary"
                onClick={() => setExpandedId(open ? null : row.id)}
              >
                <div>
                  <h2>{draft.nameI18n.en || row.name}</h2>
                  <p className="muted">
                    {row.is_custom ? 'Custom' : 'Preset'}
                    {row.icon ? ` · icon ${row.icon}` : ''}
                    {missing.length
                      ? ` · missing ${missing.join(', ').toUpperCase()}`
                      : ' · en / nl / bn complete'}
                  </p>
                </div>
                <span className="muted">{open ? 'Hide' : 'Edit'}</span>
              </button>

              {open && (
                <div className="catalog-editor">
                  <label className="field">
                    <span>Icon key</span>
                    <input
                      value={draft.icon}
                      onChange={(e) =>
                        patchDraft(row.id, (prev) => ({ ...prev, icon: e.target.value }))
                      }
                      placeholder="cleaning, factory, trades…"
                    />
                  </label>

                  {LOCALES.map((locale) => (
                    <fieldset key={locale.code} className="locale-block">
                      <legend>
                        {locale.label} <code>{locale.code}</code>
                        {locale.code === 'en' ? ' (required)' : ''}
                      </legend>
                      <label className="field">
                        <span>Name</span>
                        <input
                          value={draft.nameI18n[locale.code]}
                          onChange={(e) =>
                            patchDraft(row.id, (prev) => ({
                              ...prev,
                              nameI18n: { ...prev.nameI18n, [locale.code]: e.target.value },
                            }))
                          }
                          placeholder={`Category name (${locale.code})`}
                        />
                      </label>
                      <label className="field">
                        <span>Description</span>
                        <textarea
                          rows={2}
                          value={draft.descriptionI18n[locale.code]}
                          onChange={(e) =>
                            patchDraft(row.id, (prev) => ({
                              ...prev,
                              descriptionI18n: {
                                ...prev.descriptionI18n,
                                [locale.code]: e.target.value,
                              },
                            }))
                          }
                          placeholder={`Short description (${locale.code})`}
                        />
                      </label>
                    </fieldset>
                  ))}

                  <div className="actions">
                    <button
                      type="button"
                      className="btn good"
                      disabled={busy || !draft.nameI18n.en.trim()}
                      onClick={() => void onSave(row.id)}
                    >
                      {busy ? 'Saving…' : 'Save translations'}
                    </button>
                  </div>
                </div>
              )}
            </article>
          )
        })}
      </div>
    </div>
  )
}
