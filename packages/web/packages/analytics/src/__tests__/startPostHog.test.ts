import { describe, it, expect, vi, beforeEach } from 'vitest'

const initMock = vi.hoisted(() => vi.fn())
const captureMock = vi.hoisted(() => vi.fn())
vi.mock('posthog-js', () => ({ default: { init: initMock, capture: captureMock } }))

// A fresh module per test, as a second bundled copy of the package would be.
async function load() {
  vi.resetModules()
  return import('../startPostHog')
}

beforeEach(() => {
  initMock.mockClear()
  captureMock.mockClear()
  delete process.env.NEXT_PUBLIC_POSTHOG_KEY
  delete process.env.NEXT_PUBLIC_POSTHOG_HOST
  delete (window as unknown as Record<string, unknown>).__adhsdkPostHog
})

describe('startPostHog', () => {
  it('stays off without a key', async () => {
    const { startPostHog } = await load()
    expect(startPostHog()).toBe(false)
    expect(initMock).not.toHaveBeenCalled()
  })

  it('starts once with the privacy config, however often it is called', async () => {
    process.env.NEXT_PUBLIC_POSTHOG_KEY = 'phc_test'
    const { startPostHog } = await load()
    expect(startPostHog()).toBe(true)
    expect(startPostHog()).toBe(true)
    expect(initMock).toHaveBeenCalledTimes(1)
    const [key, config] = initMock.mock.calls[0]
    expect(key).toBe('phc_test')
    expect(config).toMatchObject({
      api_host: 'https://us.i.posthog.com',
      autocapture: false,
      disable_session_recording: true,
      persistence: 'memory',
      person_profiles: 'identified_only',
    })
  })

  it('scrubs URLs before an event leaves the page', async () => {
    process.env.NEXT_PUBLIC_POSTHOG_KEY = 'phc_test'
    const { startPostHog } = await load()
    startPostHog()
    const { before_send } = initMock.mock.calls[0][1]
    const event = before_send({
      properties: {
        $current_url: 'https://a.example.com/u/123456?t=1',
        $referrer: 'https://b.example.com/x?y=2',
        $pathname: '/u/123456',
      },
    })
    expect(event.properties).toEqual({
      $current_url: 'https://a.example.com/u/:id',
      $referrer: 'https://b.example.com/x',
      $pathname: '/u/:id',
    })
  })
})

describe('captureAnalyticsEvent', () => {
  it('sends nothing before PostHog has started', async () => {
    const { captureAnalyticsEvent } = await load()
    captureAnalyticsEvent('x', { a: 1 })
    expect(captureMock).not.toHaveBeenCalled()
  })

  it('sends through the started instance', async () => {
    process.env.NEXT_PUBLIC_POSTHOG_KEY = 'phc_test'
    const { startPostHog, captureAnalyticsEvent } = await load()
    startPostHog()
    captureAnalyticsEvent('x', { a: 1 })
    expect(captureMock).toHaveBeenCalledWith('x', { a: 1 })
  })
})

describe('a second copy of the package', () => {
  it('reuses the instance the first started, for starting and for events', async () => {
    process.env.NEXT_PUBLIC_POSTHOG_KEY = 'phc_test'
    const first = await load()
    first.startPostHog()
    const second = await load()
    expect(second.startPostHog()).toBe(true)
    expect(initMock).toHaveBeenCalledTimes(1)
    second.captureAnalyticsEvent('x', { a: 1 })
    expect(captureMock).toHaveBeenCalledWith('x', { a: 1 })
  })
})
