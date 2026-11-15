import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import type { Session } from '@supabase/supabase-js'
import { useNavigate } from 'react-router-dom'
import { probeAdmin, setAuthFailureHandler } from '../lib/adminApi'
import { loginUrl } from '../lib/authRedirect'
import { supabase } from '../lib/supabase'

export type AuthNotice = 'expired' | 'signedout' | 'not_admin' | null
export type SignInResult = 'ok' | 'invalid' | 'not_admin' | 'rate_limit' | 'network'

type AuthContextValue = {
  session: Session | null
  email: string | null
  /** True while the stored session is being restored on first load. */
  loading: boolean
  notice: AuthNotice
  clearNotice: () => void
  signIn: (email: string, password: string) => Promise<SignInResult>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const navigate = useNavigate()
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)
  const [notice, setNotice] = useState<AuthNotice>(null)
  const forcing = useRef(false)

  useEffect(() => {
    let active = true
    supabase.auth
      .getSession()
      .then(({ data }) => {
        if (active) setSession(data.session)
      })
      .catch((err) => console.error('Session restore failed', err))
      .finally(() => {
        if (active) setLoading(false)
      })
    // Keep this callback synchronous; no supabase calls inside it.
    const { data: sub } = supabase.auth.onAuthStateChange((_event, next) => {
      setSession(next)
    })
    return () => {
      active = false
      sub.subscription.unsubscribe()
    }
  }, [])

  const forceSignOut = useCallback(
    async (reason: Exclude<AuthNotice, null | 'signedout'>) => {
      if (forcing.current) return
      forcing.current = true
      const next = window.location.pathname + window.location.search
      try {
        await supabase.auth.signOut({ scope: 'local' })
      } catch (err) {
        console.error('Sign out failed', err)
      }
      setSession(null)
      setNotice(reason)
      navigate(reason === 'expired' ? loginUrl(next) : '/login', { replace: true })
      forcing.current = false
    },
    [navigate],
  )

  useEffect(() => {
    setAuthFailureHandler((status) => {
      if (window.location.pathname === '/login') return
      void forceSignOut(status === 401 ? 'expired' : 'not_admin')
    })
    return () => setAuthFailureHandler(null)
  }, [forceSignOut])

  const signIn = useCallback<AuthContextValue['signIn']>(async (email, password) => {
    setNotice(null)
    let result
    try {
      result = await supabase.auth.signInWithPassword({ email, password })
    } catch (err) {
      console.error('Sign in failed', err)
      return 'network'
    }
    if (result.error) {
      const e = result.error
      console.error('Sign in error', e.status, e.code)
      if (e.status === 429 || e.code === 'over_request_rate_limit') return 'rate_limit'
      if (e.code === 'invalid_credentials' || e.status === 400) return 'invalid'
      return 'network'
    }
    const probe = await probeAdmin()
    if (probe === 'admin') return 'ok'
    await supabase.auth.signOut({ scope: 'local' }).catch(() => undefined)
    setSession(null)
    return probe === 'error' ? 'network' : 'not_admin'
  }, [])

  const signOut = useCallback(async () => {
    try {
      await supabase.auth.signOut()
    } catch (err) {
      console.error('Sign out failed', err)
      await supabase.auth.signOut({ scope: 'local' }).catch(() => undefined)
    }
    setSession(null)
    setNotice('signedout')
    navigate('/login', { replace: true })
  }, [navigate])

  const value = useMemo<AuthContextValue>(
    () => ({
      session,
      email: session?.user.email ?? null,
      loading,
      notice,
      clearNotice: () => setNotice(null),
      signIn,
      signOut,
    }),
    [session, loading, notice, signIn, signOut],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
