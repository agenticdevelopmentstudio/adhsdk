// Recipe: adhsdk auth, the product admin site's session (phase 6).
// Only `fetch` and the navigation are stubbed: the provider's own calls to /auth/session,
// /api/v1/account and /auth/signout are asserted, and the bearer it supplies is read back through
// readAccessToken, the same seam every @adh-sdk/data client sends from.
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { act, render, waitFor } from '@testing-library/react'
import {
  PRODUCT_ADMIN_REFRESH_LEAD_MS,
  ProductAdminAuthProvider,
  useProductAdminAuth,
  type ProductAdminAuthValue,
} from '../ProductAdminAuthProvider'
import { readAccessToken, accessTokenSource } from '../tokens'

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })

const account = (roles: string[]) => ({
  user: { id: 'c1', email: 'a@x.test', name: 'A', avatar_url: '' },
  ecosystem_id: 'eco-1',
  realm: 'customer',
  roles,
})

let seen: ProductAdminAuthValue | null = null
function Probe() {
  seen = useProductAdminAuth()
  return null
}

const fetchMock = vi.fn<(url: string, init?: RequestInit) => Promise<Response>>()
const navigate = vi.fn<(url: string) => void>()

function routes(handlers: Record<string, () => Response>) {
  fetchMock.mockImplementation(async (url: string) => {
    const h = handlers[url]
    if (!h) throw new Error(`unexpected fetch ${url}`)
    return h()
  })
}

const callsTo = (url: string) => fetchMock.mock.calls.filter(([u]) => u === url)

beforeEach(() => {
  seen = null
  fetchMock.mockReset()
  navigate.mockReset()
  vi.stubGlobal('fetch', fetchMock)
  window.history.replaceState(null, '', '/users?q=a')
})

afterEach(() => {
  vi.useRealTimers()
  vi.unstubAllGlobals()
})

describe('ProductAdminAuthProvider', () => {
  it('starts a session, holds the token in memory, and is ready for an admin', async () => {
    routes({
      '/auth/session': () => json(200, { accessToken: 'tok-1', expiresAt: Math.floor(Date.now() / 1000) + 3600 }),
      '/api/v1/account': () => json(200, account(['admin'])),
    })
    render(
      <ProductAdminAuthProvider navigate={navigate}>
        <Probe />
      </ProductAdminAuthProvider>,
    )
    expect(seen?.status).toBe('loading')
    await waitFor(() => expect(seen?.status).toBe('ready'))
    expect(seen?.accessToken).toBe('tok-1')
    expect(seen?.account).toEqual({
      user: { id: 'c1', email: 'a@x.test', name: 'A', avatarUrl: null },
      ecosystemId: 'eco-1',
      roles: ['admin'],
    })
    const [, init] = callsTo('/auth/session')[0]!
    expect(init).toMatchObject({ method: 'POST', credentials: 'include' })
    // The account read carried the in-memory bearer.
    const [, accountInit] = callsTo('/api/v1/account')[0]!
    expect((accountInit?.headers as Record<string, string>).Authorization).toBe('Bearer tok-1')
    expect(readAccessToken()).toBe('tok-1')
    expect(window.localStorage.length).toBe(0)
    expect(navigate).not.toHaveBeenCalled()
  })

  it('is no-access when the account lacks the admin role', async () => {
    routes({
      '/auth/session': () => json(200, { accessToken: 'tok-1', expiresAt: Math.floor(Date.now() / 1000) + 3600 }),
      '/api/v1/account': () => json(200, account(['member'])),
    })
    render(
      <ProductAdminAuthProvider navigate={navigate}>
        <Probe />
      </ProductAdminAuthProvider>,
    )
    await waitFor(() => expect(seen?.status).toBe('no-access'))
    expect(navigate).not.toHaveBeenCalled()
  })

  it('sends a 401 from /auth/session to sign-in with the return path', async () => {
    routes({ '/auth/session': () => json(401, { error: 'no session' }) })
    render(
      <ProductAdminAuthProvider navigate={navigate}>
        <Probe />
      </ProductAdminAuthProvider>,
    )
    await waitFor(() => expect(navigate).toHaveBeenCalledWith('/auth/signin?return=%2Fusers%3Fq%3Da'))
    expect(seen?.status).toBe('loading')
    expect(callsTo('/api/v1/account')).toHaveLength(0)
    expect(readAccessToken()).toBeNull()
  })

  it('refreshes one minute before the token expires', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    const now = Date.now()
    let n = 0
    routes({
      '/auth/session': () => {
        n += 1
        return json(200, { accessToken: `tok-${n}`, expiresAt: Math.floor(now / 1000) + 600 })
      },
      '/api/v1/account': () => json(200, account(['admin'])),
    })
    render(
      <ProductAdminAuthProvider navigate={navigate}>
        <Probe />
      </ProductAdminAuthProvider>,
    )
    await waitFor(() => expect(seen?.status).toBe('ready'))
    expect(callsTo('/auth/session')).toHaveLength(1)
    await act(async () => {
      vi.advanceTimersByTime(600_000 - PRODUCT_ADMIN_REFRESH_LEAD_MS - 2_000)
    })
    expect(callsTo('/auth/session')).toHaveLength(1)
    await act(async () => {
      vi.advanceTimersByTime(4_000)
    })
    await waitFor(() => expect(callsTo('/auth/session')).toHaveLength(2))
    await waitFor(() => expect(seen?.accessToken).toBe('tok-2'))
    expect(readAccessToken()).toBe('tok-2')
  })

  it('signs out: posts /auth/signout, drops the token, goes to sign-in', async () => {
    routes({
      '/auth/session': () => json(200, { accessToken: 'tok-1', expiresAt: Math.floor(Date.now() / 1000) + 3600 }),
      '/api/v1/account': () => json(200, account(['admin'])),
      '/auth/signout': () => new Response(null, { status: 204 }),
    })
    render(
      <ProductAdminAuthProvider navigate={navigate}>
        <Probe />
      </ProductAdminAuthProvider>,
    )
    await waitFor(() => expect(seen?.status).toBe('ready'))
    await act(async () => {
      await seen?.signOut()
    })
    const [, init] = callsTo('/auth/signout')[0]!
    expect(init).toMatchObject({ method: 'POST', credentials: 'include' })
    expect(seen?.accessToken).toBeNull()
    expect(readAccessToken()).toBeNull()
    expect(navigate).toHaveBeenLastCalledWith('/auth/signin')
  })

  it('removes its token source on unmount', async () => {
    routes({
      '/auth/session': () => json(200, { accessToken: 'tok-1', expiresAt: Math.floor(Date.now() / 1000) + 3600 }),
      '/api/v1/account': () => json(200, account(['admin'])),
    })
    const { unmount } = render(
      <ProductAdminAuthProvider navigate={navigate}>
        <Probe />
      </ProductAdminAuthProvider>,
    )
    await waitFor(() => expect(seen?.status).toBe('ready'))
    unmount()
    expect(accessTokenSource()).toBeNull()
  })
})
