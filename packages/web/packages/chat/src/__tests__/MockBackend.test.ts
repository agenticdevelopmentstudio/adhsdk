import { describe, it, expect, vi, afterEach } from 'vitest'
import { MockBackend } from '../backends/MockBackend'

describe('MockBackend', () => {
  it('ccb-006: returns canned response for known commands', async () => {
    const backend = new MockBackend({ delayMs: 0 })
    const result = await backend.sendMessage('text', [])
    expect(result).toBe('Just a plain text reply with no panels or extras.')
  })

  it('is case-insensitive', async () => {
    const backend = new MockBackend({ delayMs: 0 })
    const result = await backend.sendMessage('HELLO', [])
    expect(result).toContain('Try:')
  })

  it('ccb-008: trims whitespace', async () => {
    const backend = new MockBackend({ delayMs: 0 })
    const result = await backend.sendMessage('  text  ', [])
    expect(result).toBe('Just a plain text reply with no panels or extras.')
  })

  it('ccb-009: returns fallback for unknown messages', async () => {
    const backend = new MockBackend({ delayMs: 0 })
    const result = await backend.sendMessage('unknown command', [])
    expect(result).toContain("I don't know that one")
    expect(result).toContain('hello')
  })

  it('ccb-010: returns rich response objects', async () => {
    const backend = new MockBackend({ delayMs: 0 })
    const result = await backend.sendMessage('small panel', [])
    expect(typeof result).toBe('object')
    if (typeof result === 'object') {
      expect(result.text).toBe('Here are some quick links for you.')
      expect(result.popover?.title).toBe('Quick Reference')
      expect(result.content).toHaveLength(1)
    }
  })

  it('accepts custom responses', async () => {
    const backend = new MockBackend({
      delayMs: 0,
      responses: { greet: 'Hi there!' },
    })
    const result = await backend.sendMessage('greet', [])
    expect(result).toBe('Hi there!')
  })

  it('ccb-011: custom responses merge with defaults', async () => {
    const backend = new MockBackend({
      delayMs: 0,
      responses: { greet: 'Hi there!' },
    })
    // Custom works
    expect(await backend.sendMessage('greet', [])).toBe('Hi there!')
    // Default still works
    expect(await backend.sendMessage('text', [])).toBe(
      'Just a plain text reply with no panels or extras.',
    )
  })

  it('respects delay range', async () => {
    const backend = new MockBackend({ delayMs: [50, 100] })
    const start = Date.now()
    await backend.sendMessage('text', [])
    const elapsed = Date.now() - start
    expect(elapsed).toBeGreaterThanOrEqual(45) // small tolerance
  })

  it('ccb-007: HELLO resolves to the hello response, not the fallback', async () => {
    const backend = new MockBackend({ delayMs: 0 })
    const result = await backend.sendMessage('HELLO', [])
    expect(result).toBe('Hey there! Try: small panel, big panel, small image, big image, links, or text.')
    expect(result).not.toContain("I don't know that one")
  })

  describe('ccb-012: simulated delay range under fake timers', () => {
    afterEach(() => {
      vi.useRealTimers()
      vi.restoreAllMocks()
    })

    const settledAfter = async (random: number, ms: number) => {
      vi.useFakeTimers()
      vi.spyOn(Math, 'random').mockReturnValue(random)
      const backend = new MockBackend({ delayMs: [50, 100] })
      let done = false
      const p = backend.sendMessage('text', []).then(() => {
        done = true
      })
      await vi.advanceTimersByTimeAsync(ms)
      const settled = done
      await vi.advanceTimersByTimeAsync(1000)
      await p
      return settled
    }

    it('ccb-012: Math.random = 0 resolves at 50ms and not before', async () => {
      expect(await settledAfter(0, 49)).toBe(false)
      expect(await settledAfter(0, 50)).toBe(true)
    })

    it('ccb-012: Math.random just under 1 resolves by 100ms (the upper bound) and not near the lower one', async () => {
      expect(await settledAfter(0.999999, 98)).toBe(false)
      expect(await settledAfter(0.999999, 100)).toBe(true)
    })
  })
})
