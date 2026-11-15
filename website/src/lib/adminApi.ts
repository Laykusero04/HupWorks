import { supabase } from './supabase'

export type AdminHealth = {
  ok: boolean
  usingServiceRole?: boolean
  userReportsReady?: boolean
  userBlocksReady?: boolean
  schemaHint?: string | null
  error?: string
}

export type AdminOverview = {
  ok: boolean
  pendingVerification: number
  pendingIdentity?: number
  pendingProfilePhoto?: number
  pendingEmployerVerification?: number
  openReports: number
  unpaidCompleted: number
  activeContracts: number
  error?: string
}

export type VerificationProfile = {
  id: string
  name: string | null
  email: string | null
  phone: string | null
  role: string | null
  city: string | null
  country: string | null
  bio: string | null
  profile_image_url: string | null
  verification_status: string | null
  verification_rejection_reason: string | null
  profile_photo_status: string | null
  profile_photo_rejection_reason: string | null
  seller_onboarding_completed: boolean | null
  company_name?: string | null
  company_registration_number?: string | null
  company_website?: string | null
}

export type VerificationSeller = {
  user_id: string
  job_title: string | null
  about: string | null
  skills: unknown
  address: string | null
  languages: unknown
  birth_year: number | null
  birth_month: number | null
  birth_day: number | null
}

export type VerificationPrivateDetails = {
  user_id: string
  date_of_birth: string | null
  street_address: string | null
  state: string | null
  postal_code: string | null
}

export type VerificationRow = {
  user_id: string
  id_selfie_path: string | null
  status: string | null
  submitted_at: string | null
  reviewed_at: string | null
  rejection_reason: string | null
  selfieUrl: string | null
  profile: VerificationProfile | null
  seller: VerificationSeller | null
  privateDetails: VerificationPrivateDetails | null
}

export type EmployerVerificationRow = {
  user_id: string
  verify_type: 'personal_id' | 'company' | string | null
  id_selfie_path: string | null
  company_doc_path: string | null
  company_name: string | null
  company_registration_number: string | null
  company_website: string | null
  status: string | null
  submitted_at: string | null
  reviewed_at: string | null
  rejection_reason: string | null
  docUrl: string | null
  profile: VerificationProfile | null
}

export type ReportRow = {
  id: string
  reporter_id: string
  reported_user_id: string | null
  reason: string
  details: string | null
  status: string
  created_at: string
  job_post_id: string | null
  order_id: string | null
  reporter?: {
    id: string
    name: string | null
    email: string | null
    role: string | null
  } | null
  reported?: {
    id: string
    name: string | null
    email: string | null
    role: string | null
  } | null
  order?: {
    id: string
    status: string | null
    payment_received_at: string | null
    client_id: string
    seller_id: string
    price: number | null
  } | null
  unpaid_completed?: boolean
  pair_blocked?: boolean
}

export type ReviewTrack = 'profile' | 'identity'

export class AdminAuthError extends Error {
  status: 401 | 403
  constructor(status: 401 | 403) {
    super(status === 401 ? 'Unauthorized' : 'Forbidden')
    this.name = 'AdminAuthError'
    this.status = status
  }
}

type AuthFailureHandler = (status: 401 | 403) => void
let authFailureHandler: AuthFailureHandler | null = null

/** AuthProvider registers this so any 401/403 triggers redirect / sign-out. */
export function setAuthFailureHandler(handler: AuthFailureHandler | null) {
  authFailureHandler = handler
}

const NETWORK_ERROR = "Couldn't reach the server. Check your connection and try again."
const GENERIC_ERROR = 'Request failed'

async function authedFetch(path: string, init: RequestInit = {}): Promise<Response> {
  const { data } = await supabase.auth.getSession()
  const token = data.session?.access_token
  if (!token) {
    authFailureHandler?.(401)
    throw new AdminAuthError(401)
  }
  let res: Response
  try {
    res = await fetch(path, {
      ...init,
      headers: { ...(init.headers as Record<string, string> | undefined), Authorization: `Bearer ${token}` },
    })
  } catch (err) {
    console.error('Admin API network error', err)
    throw new Error(NETWORK_ERROR)
  }
  if (res.status === 503) {
    // Transient auth/upstream failure: do not sign out, just ask to retry.
    throw new Error(NETWORK_ERROR)
  }
  if (res.status === 401 || res.status === 403) {
    authFailureHandler?.(res.status)
    throw new AdminAuthError(res.status)
  }
  return res
}

async function parseJsonResponse<T>(res: Response, path: string): Promise<T & { error?: string }> {
  const text = await res.text()
  try {
    return JSON.parse(text) as T & { error?: string }
  } catch {
    console.error(`Admin API returned non-JSON (${res.status}) for ${path}`)
    throw new Error(GENERIC_ERROR)
  }
}

async function getJson<T>(path: string): Promise<T> {
  const res = await authedFetch(path)
  const body = await parseJsonResponse<T>(res, path)
  if (!res.ok) {
    throw new Error(body.error || GENERIC_ERROR)
  }
  return body
}

async function postJson<T extends { ok: boolean; error?: string }>(
  path: string,
  input: unknown,
): Promise<T> {
  const res = await authedFetch(path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(input),
  })
  const body = await parseJsonResponse<T>(res, path)
  if (!res.ok || !body.ok) {
    throw new Error(body.error || GENERIC_ERROR)
  }
  return body
}

export type AdminProbe = 'admin' | 'unauthorized' | 'forbidden' | 'error'

/** Login-time admin check. Does not fire the global auth-failure handler. */
export async function probeAdmin(): Promise<AdminProbe> {
  const { data } = await supabase.auth.getSession()
  const token = data.session?.access_token
  if (!token) return 'unauthorized'
  try {
    const res = await fetch('/api/admin/health', { headers: { Authorization: `Bearer ${token}` } })
    if (res.status === 401) return 'unauthorized'
    if (res.status === 403) return 'forbidden'
    return res.ok ? 'admin' : 'error'
  } catch (err) {
    console.error('Admin check failed', err)
    return 'error'
  }
}

export function fetchHealth() {
  return getJson<AdminHealth>('/api/admin/health')
}

export function fetchOverview() {
  return getJson<AdminOverview>('/api/admin/overview')
}

export function fetchVerifications(status = 'pending') {
  return getJson<{ ok: boolean; rows: VerificationRow[] }>(
    `/api/admin/verifications?status=${encodeURIComponent(status)}`,
  )
}

export function fetchEmployerVerifications(status = 'pending') {
  return getJson<{ ok: boolean; rows: EmployerVerificationRow[] }>(
    `/api/admin/employer-verifications?status=${encodeURIComponent(status)}`,
  )
}

export function fetchReports() {
  return getJson<{ ok: boolean; rows: ReportRow[] }>('/api/admin/reports')
}

export type CategoryRow = {
  id: string
  name: string
  description: string | null
  icon: string | null
  is_custom: boolean
  created_at: string | null
  name_i18n: Record<string, string> | null
  description_i18n: Record<string, string> | null
}

export function fetchCategories() {
  return getJson<{ ok: boolean; rows: CategoryRow[] }>('/api/admin/categories')
}

export type AdminUserRow = {
  id: string
  name: string | null
  email: string | null
  phone: string | null
  role: string | null
  city: string | null
  country: string | null
  bio: string | null
  profile_image_url: string | null
  rating: number | null
  balance: number | null
  created_at: string | null
  verification_status: string | null
  profile_photo_status: string | null
  seller_onboarding_completed: boolean | null
  seller: { user_id: string; job_title: string | null } | null
  auth: {
    last_sign_in_at: string | null
    email_confirmed_at: string | null
    banned_until: string | null
    providers: string[]
  } | null
}

export function fetchUsers(role = 'all', q = '') {
  const params = new URLSearchParams()
  if (role && role !== 'all') params.set('role', role)
  if (q.trim()) params.set('q', q.trim())
  const qs = params.toString()
  return getJson<{ ok: boolean; rows: AdminUserRow[]; authMatched?: number }>(
    `/api/admin/users${qs ? `?${qs}` : ''}`,
  )
}

export async function deleteUser(userId: string) {
  return postJson<{ ok: boolean; deletedUserId?: string; error?: string }>(
    '/api/admin/users-delete',
    { userId },
  )
}

export async function setUserBlocked(userId: string, blocked: boolean) {
  return postJson<{
    ok: boolean
    userId?: string
    blocked?: boolean
    banned_until?: string | null
    error?: string
  }>('/api/admin/users-block', { userId, blocked })
}

export async function updateCategory(input: {
  id: string
  nameI18n: Record<string, string>
  descriptionI18n: Record<string, string>
  icon?: string | null
}) {
  return postJson<{ ok: boolean; row?: CategoryRow; error?: string }>(
    '/api/admin/category-update',
    input,
  )
}

export async function reviewVerification(input: {
  userId: string
  track: ReviewTrack
  decision: 'verified' | 'rejected'
  rejectionReason?: string
}) {
  return postJson<{ ok: boolean; error?: string }>(
    '/api/admin/verification-review',
    input,
  )
}

export async function reviewEmployerVerification(input: {
  userId: string
  track: ReviewTrack
  decision: 'verified' | 'rejected'
  rejectionReason?: string
}) {
  return postJson<{ ok: boolean; error?: string }>(
    '/api/admin/employer-verification-review',
    input,
  )
}

export function formatSkills(skills: unknown): string {
  if (!skills) return '—'
  if (Array.isArray(skills)) {
    const names = skills
      .map((item) => {
        if (typeof item === 'string') return item
        if (item && typeof item === 'object' && 'name' in item) {
          return String((item as { name: unknown }).name)
        }
        return null
      })
      .filter(Boolean)
    return names.length ? names.join(', ') : '—'
  }
  return String(skills)
}

export function formatLanguages(languages: unknown): string {
  if (!languages) return '—'
  if (Array.isArray(languages)) return languages.map(String).filter(Boolean).join(', ') || '—'
  return String(languages)
}

export function statusLabel(status: string | null | undefined): string {
  switch (status) {
    case 'verified':
      return 'Accepted'
    case 'pending':
      return 'Pending'
    case 'rejected':
      return 'Rejected'
    default:
      return 'Not submitted'
  }
}
