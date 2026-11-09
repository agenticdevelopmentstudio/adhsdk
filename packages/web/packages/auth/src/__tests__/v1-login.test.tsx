import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { act, render, waitFor } from '@testing-library/react'
import { AuthProvider, useAuth } from '../context'
import { configureAuth } from '../config'
import { getMfaStatus, listWebauthn, setPreferredMethod, enrollTotp } from '../account-security'
import { completeLoginCode } from '../mfa'
import { writeTokens } from '../tokens'
import type { MfaChallenge } from '../mfa'

vi.mock('@simplewebauthn/browser', () => ({
  startAuthentication: vi.fn(),
  startRegistration: vi.fn(),
}))

const V1_USER = {
  object: 'account',
  id: 'u1',
  email: 'a@b.com',
  name: 'Ada',
  avatar_url: 'https://img/a.png',
  slug: 'ada',
  capabilities: ['admin'],
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } })
}

interface Call { url: string; init?: RequestInit }
let calls: Call[]

function stub(handler: (url: string, init?: RequestInit) => Response): void {
  calls = []
  vi.stubGlobal(
    'fetch',
    vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      calls.push({ url: String(input), init })
      return handler(String(input), init)
    }),
  )
}

beforeEach(() => {
  window.localStorage.clear()
  configureAuth({ storageKey: 'auth_tokens' })
})
afterEach(() => vi.unstubAllGlobals())

let latest: ReturnType<typeof useAuth> | null = null
function Probe(): null {
  latest = useAuth()
  return null
}

describe('password login over /v1/auth/sessions', () => {
  it('maps the /v1 user and stores the token', async () => {
    stub((url) => (url.includes('/v1/auth/sessions') ? json(200, { object: 'auth.session', token: 'JWT', refresh_token: 'r', user: V1_USER }) : json(401, {})))
    render(<AuthProvider clientId="adh" silentSso={false}><Probe /></AuthProvider>)
    await waitFor(() => expect(latest?.isLoading).toBe(false))
    let out: unknown
    await act(async () => {
      out = await latest!.login('a@b.com', 'pw')
    })
    const post = calls.find((c) => c.url === '/api/v1/auth/sessions')!
    expect(JSON.parse(post.init!.body as string)).toEqual({ method: 'password', identifier: 'a@b.com', password: 'pw' })
    expect(out).toMatchObject({ id: 'u1', avatarUrl: 'https://img/a.png', capabilities: ['admin'] })
    expect(JSON.parse(window.localStorage.getItem('auth_tokens')!)).toEqual({ accessToken: 'JWT', refreshToken: '' })
  })

  it('hands back the 202 {mfa_required, token, methods} as a challenge', async () => {
    stub((url) => (url === '/api/v1/auth/sessions' ? json(202, { mfa_required: true, token: 'pending', methods: ['totp', 'sms'] }) : json(401, {})))
    render(<AuthProvider clientId="adh" silentSso={false}><Probe /></AuthProvider>)
    await waitFor(() => expect(latest?.isLoading).toBe(false))
    let out: unknown
    await act(async () => {
      out = await latest!.login('a@b.com', 'pw')
    })
    expect(out).toEqual<MfaChallenge>({ mfaRequired: true, token: 'pending', methods: ['totp', 'sms'] })
    expect(window.localStorage.getItem('auth_tokens')).toBeNull()
  })
})

describe('MFA completion', () => {
  it('posts the factor to /v1/auth/sessions and maps the user', async () => {
    stub(() => json(200, { token: 'JWT', refresh_token: 'r', user: V1_USER }))
    const out = await completeLoginCode('pending', 'totp', '123456')
    expect(calls[0]!.url).toBe('/api/v1/auth/sessions')
    expect(JSON.parse(calls[0]!.init!.body as string)).toEqual({ token: 'pending', method: 'totp', code: '123456' })
    expect(out.token).toBe('JWT')
    expect(out.user.avatarUrl).toBe('https://img/a.png')
  })
})

describe('account-security over /v1/account/mfa', () => {
  beforeEach(() => writeTokens({ accessToken: 'T', refreshToken: '' }))

  it('maps the factor status', async () => {
    stub(() => json(200, { object: 'account.mfa', sms: true, totp: false, webauthn: true, totp_pending: true, recovery_remaining: 4, preferred_method: 'sms' }))
    expect(await getMfaStatus()).toEqual({ sms: true, totp: false, webauthn: true, totpPending: true, recoveryRemaining: 4, preferredMethod: 'sms' })
    expect(calls[0]!.url).toBe('/api/v1/account/mfa')
  })

  it('maps TOTP enrollment', async () => {
    stub(() => json(200, { object: 'account.mfa.totp', secret: 'S', otpauth_uri: 'otpauth://x' }))
    expect(await enrollTotp()).toEqual({ secret: 'S', otpauthUri: 'otpauth://x' })
    expect(calls[0]!.url).toBe('/api/v1/account/mfa/totp')
  })

  it('lists passkeys through the paged collection', async () => {
    stub(() => json(200, { object: 'list', data: [{ id: 'p1', name: 'Key', kind: 'passkey', created: 1700000000, last_used_at: null }], has_more: false, url: '/v1/account/mfa/passkeys' }))
    const { items } = await listWebauthn()
    expect(items).toEqual([{ id: 'p1', name: 'Key', kind: 'passkey', createdAt: '2023-11-14T22:13:20.000Z', lastUsedAt: null }])
    expect(calls[0]!.url).toContain('/api/v1/account/mfa/passkeys?limit=100')
  })

  it('sets the preferred method as an include write', async () => {
    stub(() => json(200, { object: 'account.mfa', preferred_method: 'totp' }))
    expect(await setPreferredMethod('totp')).toEqual({ preferredMethod: 'totp' })
    expect(calls[0]!.init!.method).toBe('POST')
    expect(JSON.parse(calls[0]!.init!.body as string)).toEqual({ preference: { method: 'totp' } })
  })
})
