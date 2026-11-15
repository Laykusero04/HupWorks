// Tests for src/lib/authRedirect.ts (open-redirect guard for ?next=).
import { describe, it } from 'node:test'
import assert from 'node:assert/strict'
import { loginUrl, safeNext } from '../src/lib/authRedirect.ts'

describe('safeNext: rejects anything that is not a plain in-app path', () => {
  const rejected: [string, string | null | undefined][] = [
    ['null', null],
    ['undefined', undefined],
    ['empty string', ''],
    ['https URL', 'https://evil.com'],
    ['http URL', 'http://evil.com/x'],
    ['protocol-relative', '//evil.com'],
    ['triple slash', '///evil.com'],
    ['backslash after slash', '/\\evil.com'],
    ['leading backslashes', '\\\\evil.com'],
    ['javascript scheme', 'javascript:alert(1)'],
    ['data scheme', 'data:text/html,hi'],
    ['no leading slash', 'users'],
    ['leading space', ' /users'],
    ['leading newline', '\n/users'],
    ['embedded newline', '/users\nSet-Cookie: x=1'],
    ['embedded tab', '/users\tx'],
    ['embedded NUL', '/users\u0000'],
    ['DEL character', '/users\u007f'],
    ['login path', '/login'],
    ['login with query', '/login?next=/users'],
    ['login trailing slash', '/login/'],
    ['login subpath', '/login/reset'],
  ]
  for (const [label, value] of rejected) {
    it(`${label} -> "/"`, () => {
      assert.equal(safeNext(value), '/')
    })
  }

  it('does not reject paths that merely start with "login"', () => {
    assert.equal(safeNext('/loginx'), '/loginx')
    assert.equal(safeNext('/login-help'), '/login-help')
  })
})

describe('safeNext: keeps same-origin in-app paths unchanged', () => {
  const kept = [
    '/',
    '/users',
    '/users?tab=all',
    '/users#top',
    '/users/12?x=1&y=%20',
    '/verifications/employer?status=pending',
  ]
  for (const path of kept) {
    it(`${path} is kept`, () => {
      assert.equal(safeNext(path), path)
    })
  }
})

describe('loginUrl', () => {
  it('no next -> /login', () => {
    assert.equal(loginUrl(), '/login')
    assert.equal(loginUrl(null), '/login')
  })
  it('root or unsafe next -> /login (no next parameter)', () => {
    assert.equal(loginUrl('/'), '/login')
    assert.equal(loginUrl('https://evil.com'), '/login')
    assert.equal(loginUrl('//evil.com'), '/login')
  })
  it('safe path with query is percent-encoded into next', () => {
    assert.equal(loginUrl('/users?tab=all'), '/login?next=%2Fusers%3Ftab%3Dall')
  })
})
