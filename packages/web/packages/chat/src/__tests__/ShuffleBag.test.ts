// packages/web/packages/chat/src/__tests__/ShuffleBag.test.ts
import { afterEach, describe, expect, it, vi } from 'vitest'
import { ShuffleBag, streamTokens } from '../backends/ShuffleBag'

describe('ShuffleBag', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('ccb-013: exhausts every item before repeating any', () => {
    const items = ['a', 'b', 'c', 'd']
    const bag = new ShuffleBag(items)
    const first = [bag.next(), bag.next(), bag.next(), bag.next()]
    expect([...first].sort()).toEqual([...items].sort())
  })

  it('ccb-014: refills after exhaustion', () => {
    const bag = new ShuffleBag(['a', 'b'])
    const drawn = [bag.next(), bag.next(), bag.next(), bag.next()]
    expect(drawn.filter((d) => d === 'a')).toHaveLength(2)
    expect(drawn.filter((d) => d === 'b')).toHaveLength(2)
  })

  it('ccb-015: repeats the sole item of a one-item bag', () => {
    const bag = new ShuffleBag(['only'])
    expect([bag.next(), bag.next()]).toEqual(['only', 'only'])
  })

  it('ccb-016: rejects an empty bag at construction', () => {
    // next() assumes at least one item (it falls back to items[0]); constructing
    // empty must fail fast rather than hand back a bag that can't draw.
    expect(() => new ShuffleBag([])).toThrow('ShuffleBag requires at least one item')
  })

  it('ccb-017: draws in Fisher-Yates order for a stubbed Math.random', () => {
    // With Math.random pinned to 0, the correct backward Fisher-Yates walk
    // (i from length-1 down to 1, j = floor(random * (i+1)) = 0 every time)
    // produces a specific, hand-verified permutation. A flipped loop
    // direction (or any other reordering of the swap sequence) produces a
    // different permutation for the same random stream, so this pins the
    // exact swap order rather than just "some" permutation.
    vi.spyOn(Math, 'random').mockReturnValue(0)
    const bag = new ShuffleBag(['a', 'b', 'c', 'd'])
    const drawn = [bag.next(), bag.next(), bag.next(), bag.next()]
    expect(drawn).toEqual(['a', 'd', 'c', 'b'])
  })
})

describe('streamTokens', () => {
  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('ccb-018: emits every token then a done event, preserving whitespace', async () => {
    const events = []
    for await (const e of streamTokens('hi there', { minMs: 0, jitterMs: 0 })) {
      events.push(e)
    }
    expect(events).toEqual([
      { type: 'token', text: 'hi' },
      { type: 'token', text: ' ' },
      { type: 'token', text: 'there' },
      { type: 'done' },
    ])
  })

  it('ccb-019: emits just done for empty text', async () => {
    const events = []
    for await (const e of streamTokens('', { minMs: 0, jitterMs: 0 })) {
      events.push(e)
    }
    expect(events).toEqual([{ type: 'done' }])
  })

  it('ccb-020: still delays on the empty split entry even though nothing is yielded for it', async () => {
    // ''.split(/(\s+)/) === [''] — a single falsy token. The delay must run
    // unconditionally on every loop iteration (only the yield is guarded by
    // the truthiness check), so the lone `{ type: 'done' }` event must not
    // resolve until that delay has elapsed. A `continue`-on-falsy version
    // skips the delay entirely and resolves on the next microtask instead,
    // with no timer advance needed at all.
    vi.useFakeTimers()
    vi.spyOn(Math, 'random').mockReturnValue(0) // delay = minMs + 0 * jitterMs = 50ms

    const iter = streamTokens('', { minMs: 50, jitterMs: 10 })[Symbol.asyncIterator]()

    let resolved = false
    const p = iter.next().then((r) => {
      resolved = true
      return r
    })

    await vi.advanceTimersByTimeAsync(49)
    expect(resolved).toBe(false)

    await vi.advanceTimersByTimeAsync(1)
    const r = await p
    expect(resolved).toBe(true)
    expect(r.value).toEqual({ type: 'done' })
  })

  it('waits the full minMs + jitter before the next token resolves', async () => {
    vi.useFakeTimers()
    vi.spyOn(Math, 'random').mockReturnValue(0.5) // pins jitter fraction

    const iter = streamTokens('ab cd', { minMs: 100, jitterMs: 40 })[Symbol.asyncIterator]()

    const r1 = await iter.next()
    expect(r1.value).toEqual({ type: 'token', text: 'ab' })

    // expected delay = minMs + random * jitterMs = 100 + 0.5 * 40 = 120ms
    let resolved = false
    const p2 = iter.next().then((r) => {
      resolved = true
      return r
    })

    await vi.advanceTimersByTimeAsync(119)
    expect(resolved).toBe(false)

    await vi.advanceTimersByTimeAsync(1)
    const r2 = await p2
    expect(resolved).toBe(true)
    expect(r2.value).toEqual({ type: 'token', text: ' ' })
  })

  it('ccb-021: falls back to the 45ms/55ms defaults when opts is omitted', async () => {
    vi.useFakeTimers()
    vi.spyOn(Math, 'random').mockReturnValue(0) // 45 + 0 * 55 = 45ms

    const iter = streamTokens('x')[Symbol.asyncIterator]()
    const r1 = await iter.next()
    expect(r1.value).toEqual({ type: 'token', text: 'x' })

    let resolved = false
    const p2 = iter.next().then((r) => {
      resolved = true
      return r
    })

    await vi.advanceTimersByTimeAsync(44)
    expect(resolved).toBe(false)

    await vi.advanceTimersByTimeAsync(1)
    await p2
    expect(resolved).toBe(true)
  })
})
