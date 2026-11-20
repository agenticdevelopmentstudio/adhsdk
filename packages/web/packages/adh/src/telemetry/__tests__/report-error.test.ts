import { afterEach, describe, expect, it, vi } from 'vitest'
import { reportUnlessUnauthorized, setErrorReporter } from '../report-error'

const withStatus = (status: number) => Object.assign(new Error(`HTTP ${status}`), { status })

describe('reportUnlessUnauthorized', () => {
  afterEach(() => setErrorReporter(null))

  it('drops a 401 — an expired session, not a bug', () => {
    const spy = vi.fn()
    setErrorReporter(spy)
    reportUnlessUnauthorized(withStatus(401))
    expect(spy).not.toHaveBeenCalled()
  })

  it('reports every other status, other 4xx included, with its context', () => {
    const spy = vi.fn()
    setErrorReporter(spy)
    for (const status of [400, 403, 404, 422, 500, 503]) {
      const err = withStatus(status)
      reportUnlessUnauthorized(err, { feature: 'f' })
      expect(spy).toHaveBeenLastCalledWith(err, { feature: 'f' })
    }
    expect(spy).toHaveBeenCalledTimes(6)
  })

  it('reports a status-less error (a network failure, a bug)', () => {
    const spy = vi.fn()
    setErrorReporter(spy)
    const err = new Error('boom')
    reportUnlessUnauthorized(err)
    expect(spy).toHaveBeenCalledWith(err, undefined)
  })
})
