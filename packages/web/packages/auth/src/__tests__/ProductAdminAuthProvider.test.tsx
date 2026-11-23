// Recipe: adhsdk auth, the product admin site's session (phase 6).
// Only `fetch` and the navigation are stubbed: the provider's own calls to /auth/session,
// /api/v1/account and /auth/signout are asserted, and the bearer it supplies is read back through
// readAccessToken, the same seam every @adh-sdk/data client sends from.
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { StrictMode, useEffect } from 'react'
import { act, render, waitFor } from '@testing-library/react'
import {
  PRODUCT_ADMIN_REFRESH_LEAD_MS,
  ProductAdminAuthProvider,
  useProductAdminAuth,
  type ProductAdminAuthValue,
} from '../ProductAdminAuthProvider'
import { readAccessToken, accessTokenSource, clearTokens, writeTokens } from '../tokens'

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
  clearTokens()
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

  it('drops a refresh that lands after sign-out, and signs out after it settles', async () => {
    let n = 0
    let release: (r: Response) => void = () => undefined
    const order: string[] = []
    fetchMock.mockImplementation(async (url: string) => {
      order.push(url)
      if (url === '/auth/session') {
        n += 1
        if (n === 1) return json(200, { accessToken: 'tok-1', expiresAt: Math.floor(Date.now() / 1000) + 3600 })
        return new Promise<Response>((r) => (release = r))
      }
      if (url === '/api/v1/account') return json(200, account(['admin']))
      if (url === '/auth/signout') return new Response(null, { status: 204 })
      throw new Error(`unexpected fetch ${url}`)
    })
    render(
      <ProductAdminAuthProvider navigate={navigate}>
        <Probe />
      </ProductAdminAuthProvider>,
    )
    await waitFor(() => expect(seen?.status).toBe('ready'))
    // A refresh goes out (as the timer or a 401 retry would send it) and is still pending.
    const pending = accessTokenSource()!.refresh()
    let signedOut: Promise<void> | undefined
    await act(async () => {
      signedOut = seen?.signOut()
    })
    // Sign-out waits for the refresh to settle at the server before it posts.
    expect(callsTo('/auth/signout')).toHaveLength(0)
    await act(async () => {
      release(json(200, { accessToken: 'tok-2', expiresAt: Math.floor(Date.now() / 1000) + 3600 }))
      await signedOut
    })
    await expect(pending).resolves.toBeNull()
    expect(order.lastIndexOf('/auth/session')).toBeLessThan(order.indexOf('/auth/signout'))
    expect(seen?.accessToken).toBeNull()
    expect(readAccessToken()).toBeNull()
    expect(navigate).toHaveBeenLastCalledWith('/auth/signin')
  })

  it('refreshes once on mount when the host passes navigate as an inline arrow', async () => {
    routes({
      '/auth/session': () => json(200, { accessToken: 'tok-1', expiresAt: Math.floor(Date.now() / 1000) + 3600 }),
      '/api/v1/account': () => json(200, account(['admin'])),
    })
    render(
      <ProductAdminAuthProvider navigate={(u) => navigate(u)}>
        <Probe />
      </ProductAdminAuthProvider>,
    )
    await waitFor(() => expect(seen?.status).toBe('ready'))
    // Give a re-run, if there were one, time to fire.
    await act(async () => {
      await new Promise((r) => setTimeout(r, 20))
    })
    expect(callsTo('/auth/session')).toHaveLength(1)
  })

  it('sends one POST /auth/session across a StrictMode remount, and the second mount adopts it', async () => {
    let release: (r: Response) => void = () => undefined
    fetchMock.mockImplementation(async (url: string) => {
      if (url === '/auth/session') return new Promise<Response>((r) => (release = r))
      if (url === '/api/v1/account') return json(200, account(['admin']))
      throw new Error(`unexpected fetch ${url}`)
    })
    render(
      <StrictMode>
        <ProductAdminAuthProvider navigate={navigate}>
          <Probe />
        </ProductAdminAuthProvider>
      </StrictMode>,
    )
    expect(callsTo('/auth/session')).toHaveLength(1)
    await act(async () => {
      release(json(200, { accessToken: 'tok-1', expiresAt: Math.floor(Date.now() / 1000) + 3600 }))
    })
    await waitFor(() => expect(seen?.status).toBe('ready'))
    expect(callsTo('/auth/session')).toHaveLength(1)
    expect(readAccessToken()).toBe('tok-1')
    expect(navigate).not.toHaveBeenCalled()
  })

  it("installs its token source before a child's first effect, so no stored token leaks out", async () => {
    // Another session's token in the shared storage key: before the fix a child's mount query
    // sent it, since the source was not yet installed.
    writeTokens({ accessToken: 'other-session', refreshToken: '' })
    routes({
      '/auth/session': () => json(200, { accessToken: 'tok-1', expiresAt: Math.floor(Date.now() / 1000) + 3600 }),
      '/api/v1/account': () => json(200, account(['admin'])),
    })
    const atChildMount: { installed: boolean; token: string | null }[] = []
    function Child() {
      useEffect(() => {
        atChildMount.push({ installed: accessTokenSource() !== null, token: readAccessToken() })
      }, [])
      return null
    }
    render(
      <ProductAdminAuthProvider navigate={navigate}>
        <Child />
        <Probe />
      </ProductAdminAuthProvider>,
    )
    expect(atChildMount).toEqual([{ installed: true, token: null }])
    await waitFor(() => expect(seen?.status).toBe('ready'))
    expect(readAccessToken()).toBe('tok-1')
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
