import { useCallback, useEffect, useMemo, useState } from 'react'
import { Badge, Button, Collapse, Form } from 'react-bootstrap'
import { EmptyState, LoadingState } from '../components/LoadingState'
import { PageHeader } from '../components/PageHeader'
import { PageSection } from '../components/PageSection'
import { QueueToolbar } from '../components/QueueToolbar'
import { StatusAlert } from '../components/StatusAlert'
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
    <div>
      <PageHeader
        title="Catalog"
        subtitle="Edit category names and descriptions for English, Dutch, and Bengali."
      />

      <QueueToolbar
        search={query}
        onSearchChange={setQuery}
        searchPlaceholder="Search categories…"
        onRefresh={() => void load()}
        refreshing={loading}
        tabs={[
          { key: 'all', label: 'All' },
          { key: 'preset', label: 'Presets' },
          { key: 'custom', label: 'Custom' },
          { key: 'incomplete', label: 'Missing translation' },
        ]}
        activeTab={filter}
        onTabChange={(key) => setFilter(key as typeof filter)}
      />

      {error && <StatusAlert title="Error">{error}</StatusAlert>}

      {loading && <LoadingState label="Loading categories…" />}

      {!loading && !error && filtered.length === 0 && (
        <EmptyState>No categories match.</EmptyState>
      )}

      <div className="d-flex flex-column gap-2">
        {filtered.map((row) => {
          const draft = drafts[row.id] ?? toDraft(row)
          const open = expandedId === row.id
          const missing = missingLocales(draft)
          const busy = savingId === row.id

          return (
            <PageSection key={row.id} bodyClassName="py-3">
              <button
                type="button"
                className="btn btn-link text-decoration-none text-start text-body p-0 w-100"
                onClick={() => setExpandedId(open ? null : row.id)}
                aria-expanded={open}
              >
                <div className="d-flex justify-content-between gap-3">
                  <div className="min-w-0">
                    <div className="fw-semibold">{draft.nameI18n.en || row.name}</div>
                    <div className="d-flex flex-wrap gap-1 mt-2">
                      <Badge bg={row.is_custom ? 'info' : 'secondary'}>
                        {row.is_custom ? 'Custom' : 'Preset'}
                      </Badge>
                      {row.icon ? <Badge bg="light" text="dark">icon {row.icon}</Badge> : null}
                      {missing.length ? (
                        <Badge bg="warning" text="dark">
                          missing {missing.join(', ').toUpperCase()}
                        </Badge>
                      ) : (
                        <Badge bg="success">en / nl / bn complete</Badge>
                      )}
                    </div>
                  </div>
                  <span className="small text-secondary flex-shrink-0">{open ? 'Hide' : 'Edit'}</span>
                </div>
              </button>

              <Collapse in={open}>
                <div>
                  <hr className="my-3" />
                  <Form
                    onSubmit={(e) => {
                      e.preventDefault()
                      void onSave(row.id)
                    }}
                  >
                    <Form.Group className="mb-3" controlId={`icon-${row.id}`}>
                      <Form.Label>Icon key</Form.Label>
                      <Form.Control
                        value={draft.icon}
                        onChange={(e) =>
                          patchDraft(row.id, (prev) => ({ ...prev, icon: e.target.value }))
                        }
                        placeholder="cleaning, factory, trades…"
                      />
                    </Form.Group>

                    {LOCALES.map((locale) => (
                      <fieldset key={locale.code} className="border rounded p-3 mb-3">
                        <legend className="float-none w-auto px-2 fs-6 mb-0">
                          {locale.label} <code>{locale.code}</code>
                          {locale.code === 'en' ? ' (required)' : ''}
                        </legend>
                        <Form.Group className="mb-2" controlId={`name-${row.id}-${locale.code}`}>
                          <Form.Label>Name</Form.Label>
                          <Form.Control
                            value={draft.nameI18n[locale.code]}
                            onChange={(e) =>
                              patchDraft(row.id, (prev) => ({
                                ...prev,
                                nameI18n: { ...prev.nameI18n, [locale.code]: e.target.value },
                              }))
                            }
                            placeholder={`Category name (${locale.code})`}
                          />
                        </Form.Group>
                        <Form.Group controlId={`desc-${row.id}-${locale.code}`}>
                          <Form.Label>Description</Form.Label>
                          <Form.Control
                            as="textarea"
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
                        </Form.Group>
                      </fieldset>
                    ))}

                    <Button
                      type="submit"
                      variant="success"
                      disabled={busy || !draft.nameI18n.en.trim()}
                    >
                      {busy ? 'Saving…' : 'Save translations'}
                    </Button>
                  </Form>
                </div>
              </Collapse>
            </PageSection>
          )
        })}
      </div>
    </div>
  )
}
