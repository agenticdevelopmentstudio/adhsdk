import { describe, it, expect, vi, beforeEach } from 'vitest'

// captureEvent hands off to the shared analytics package, which owns the PostHog instance.
const captureMock = vi.hoisted(() => vi.fn())
vi.mock('@agenticdevelopertoolkit/analytics', () => ({ captureAnalyticsEvent: captureMock }))

import {
  captureEvent,
  setPosthogReady,
  markRetriedRequest,
  consumeRetriedFlag,
  EVENT_HTTP_REQUEST,
} from '../telemetry/analytics'

describe('captureEvent', () => {
  beforeEach(() => {
    captureMock.mockClear()
    setPosthogReady(false)
  })

  it('does not reach PostHog until initialized', () => {
    captureEvent('x', { a: 1 })
    expect(captureMock).not.toHaveBeenCalled()
  })

  it('captures once PostHog is ready', () => {
    setPosthogReady(true)
    captureEvent(EVENT_HTTP_REQUEST, { path: '/api/x', status: 200 })
    expect(captureMock).toHaveBeenCalledWith(EVENT_HTTP_REQUEST, { path: '/api/x', status: 200 })
  })

  it('never throws even if the capture throws', () => {
    setPosthogReady(true)
    captureMock.mockImplementationOnce(() => {
      throw new Error('boom')
    })
    expect(() => captureEvent('x', {})).not.toThrow()
  })
})

describe('retry marker', () => {
  it('round-trips on the same init object and clears after consume', () => {
    const init = { method: 'GET' }
    markRetriedRequest(init)
    expect(consumeRetriedFlag(init)).toBe(true)
    expect(consumeRetriedFlag(init)).toBe(false)
  })

  it('is false for an unmarked init or a non-object', () => {
    expect(consumeRetriedFlag({})).toBe(false)
    expect(consumeRetriedFlag(undefined)).toBe(false)
  })
})
