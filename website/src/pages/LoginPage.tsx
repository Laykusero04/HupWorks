import { useEffect, useRef, useState, type FormEvent } from 'react'
import { Alert, Button, Form, Spinner } from 'react-bootstrap'
import { Navigate, useNavigate, useSearchParams } from 'react-router-dom'
import { useAuth, type SignInResult } from '../auth/AuthContext'
import { FullPageSpinner } from '../auth/RequireAdmin'
import { safeNext } from '../lib/authRedirect'

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

type Banner = { variant: 'danger' | 'warning' | 'info'; text: string; extra?: string }

function bannerFor(result: Exclude<SignInResult, 'ok'>): Banner {
  switch (result) {
    case 'invalid':
      return { variant: 'danger', text: 'Incorrect email or password.' }
    case 'not_admin':
      return {
        variant: 'danger',
        text: "This account doesn't have admin access.",
        extra: 'Try a different account.',
      }
    case 'rate_limit':
      return { variant: 'warning', text: 'Too many attempts. Wait a minute and try again.' }
    default:
      return { variant: 'warning', text: "Couldn't sign in. Check your connection and try again." }
  }
}

export function LoginPage() {
  const { session, loading, notice, clearNotice, signIn } = useAuth()
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const next = safeNext(params.get('next'))

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPw, setShowPw] = useState(false)
  const [busy, setBusy] = useState(false)
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({})
  const [banner, setBanner] = useState<Banner | null>(null)
  const emailRef = useRef<HTMLInputElement>(null)
  const pwRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (window.matchMedia('(min-width: 992px)').matches) emailRef.current?.focus()
  }, [loading])

  if (loading) return <FullPageSpinner />
  if (session && !busy) return <Navigate to={next} replace />

  const noticeBanner: Banner | null =
    banner ??
    (notice === 'expired'
      ? { variant: 'info', text: 'Your session expired. Sign in again to continue.' }
      : notice === 'signedout'
        ? { variant: 'info', text: "You've been signed out." }
        : notice === 'not_admin'
          ? bannerFor('not_admin')
          : null)

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    if (busy) return
    const trimmed = email.trim()
    const next_errors: { email?: string; password?: string } = {}
    if (!trimmed) next_errors.email = 'Enter your email address.'
    else if (!EMAIL_RE.test(trimmed)) next_errors.email = 'Enter a valid email address.'
    if (!password) next_errors.password = 'Enter your password.'
    setErrors(next_errors)
    if (next_errors.email) return emailRef.current?.focus()
    if (next_errors.password) return pwRef.current?.focus()

    setBusy(true)
    setBanner(null)
    clearNotice()
    const result = await signIn(trimmed, password)
    if (result === 'ok') {
      navigate(next, { replace: true, state: { focusHeading: true } })
      return
    }
    setBanner(bannerFor(result))
    setPassword('')
    if (result === 'invalid') pwRef.current?.focus()
    setBusy(false)
  }

  const icon =
    noticeBanner?.variant === 'info' ? 'bi-info-circle' : 'bi-exclamation-triangle'

  return (
    <>
      <title>Sign in - HupWorks Admin</title>
      <meta name="robots" content="noindex" />
      <main className="login-page">
        <div className="login-card card shadow-sm">
          <div className="d-flex align-items-center gap-2 mb-4">
            <span className="admin-brand-mark">H</span>
            <div>
              <strong className="d-block">HupWorks</strong>
              <span className="small text-secondary">Admin</span>
            </div>
          </div>
          <h1 className="h3 mb-1">Sign in</h1>
          <p className="text-secondary">Admin access only.</p>

          {noticeBanner && (
            <Alert
              variant={noticeBanner.variant}
              role={noticeBanner.variant === 'info' ? 'status' : 'alert'}
              className="login-alert d-flex gap-2"
            >
              <i className={`bi ${icon}`} aria-hidden />
              <div>
                <div className="login-balance">{noticeBanner.text}</div>
                {noticeBanner.extra && <div className="login-balance">{noticeBanner.extra}</div>}
              </div>
            </Alert>
          )}

          <Form onSubmit={onSubmit} noValidate>
            <Form.Group className="mb-3" controlId="login-email">
              <Form.Label>Email</Form.Label>
              <Form.Control
                ref={emailRef}
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="username"
                inputMode="email"
                autoCapitalize="none"
                spellCheck={false}
                required
                readOnly={busy}
                isInvalid={!!errors.email}
                aria-invalid={!!errors.email}
                aria-describedby={errors.email ? 'login-email-err' : undefined}
                className="login-input"
              />
              {errors.email && (
                <div id="login-email-err" className="login-error">
                  <i className="bi bi-exclamation-circle" aria-hidden /> {errors.email}
                </div>
              )}
            </Form.Group>

            <Form.Group className="mb-3" controlId="login-password">
              <Form.Label>Password</Form.Label>
              <div className="d-flex gap-2 align-items-start">
                <div className="flex-grow-1 login-pw-field">
                  <Form.Control
                    ref={pwRef}
                    type={showPw ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    autoComplete="current-password"
                    required
                    readOnly={busy}
                    isInvalid={!!errors.password}
                    aria-invalid={!!errors.password}
                    aria-describedby={errors.password ? 'login-password-err' : undefined}
                    className="login-input"
                  />
                  {errors.password && (
                    <div id="login-password-err" className="login-error">
                      <i className="bi bi-exclamation-circle" aria-hidden /> {errors.password}
                    </div>
                  )}
                </div>
                <Button
                  type="button"
                  variant="outline-secondary"
                  className="login-toggle"
                  aria-pressed={showPw}
                  aria-label={showPw ? 'Hide password' : 'Show password'}
                  onClick={() => setShowPw((v) => !v)}
                >
                  {showPw ? 'Hide' : 'Show'}
                </Button>
              </div>
            </Form.Group>

            <Button type="submit" className="login-submit w-100" disabled={busy}>
              {busy ? (
                <span role="status" aria-live="polite">
                  <Spinner animation="border" size="sm" aria-hidden className="me-2 login-spinner" />
                  Signing in...
                </span>
              ) : (
                'Sign in'
              )}
            </Button>
            <p className="small text-secondary mt-3 mb-0 login-help">
              Forgot your password? Ask another admin to reset it.
            </p>
          </Form>
        </div>
      </main>
    </>
  )
}
