/**
 * The public flag table is read without the caller's token. A signed-in visitor on a site whose
 * token the gateway refuses on /api/v1/feature_flags would otherwise read no flags on any page.
 * Drives the real provider with only `fetch` stubbed, as the gate tests beside it do.
 */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import '@testing-library/jest-dom/vitest'
import { cleanup, render, screen, waitFor } from '@testing-library/react'
import { FeatureFlagsProvider, FlagState, useFeatureFlag } from '@adh-sdk/adh/flags'

function Probe() {
  const state = useFeatureFlag('probe_flag')
  return <div data-testid="state">{state === FlagState.Yes ? 'yes' : state === FlagState.No ? 'no' : 'fetching'}</div>
}

describe('FeatureFlagsProvider: the public flag read', () => {
  beforeEach(() => {
    document.cookie = 'dev_flags=;max-age=0;path=/'
    // A signed-in visitor: the default auth storage holds an access token.
    localStorage.setItem('auth_tokens', JSON.stringify({ accessToken: 'TOK', refreshToken: '' }))
  })
  afterEach(() => {
    localStorage.clear()
    vi.unstubAllGlobals()
    cleanup()
  })

  it('sends no Authorization header, even when someone is signed in', async () => {
    const fetchMock = vi.fn(async (_url: string, _init?: RequestInit) =>
      new Response(
        JSON.stringify({ object: 'list', data: [{ id: 1, key: 'probe_flag', enabled: true }], has_more: false, url: '/v1/feature_flags' }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      ),
    )
    vi.stubGlobal('fetch', fetchMock)
    render(
      <FeatureFlagsProvider>
        <Probe />
      </FeatureFlagsProvider>,
    )
    await waitFor(() => expect(screen.getByTestId('state')).toHaveTextContent('yes'))
    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, init] = fetchMock.mock.calls[0]!
    expect(String(url)).toContain('/api/v1/feature_flags')
    expect(new Headers(init?.headers).get('authorization')).toBeNull()
    expect(init?.cache).toBe('no-store')
  })

  it('a refused read settles to no flags, and is not retried with a refreshed token', async () => {
    const fetchMock = vi.fn(async () => new Response('{}', { status: 401 }))
    vi.stubGlobal('fetch', fetchMock)
    render(
      <FeatureFlagsProvider>
        <Probe />
      </FeatureFlagsProvider>,
    )
    await waitFor(() => expect(screen.getByTestId('state')).toHaveTextContent('no'))
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })
})
