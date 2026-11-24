import type { ChatStreamEvent } from '../types'

const delay = (ms: number): Promise<void> => new Promise((r) => setTimeout(r, ms))

function shuffled<T>(items: readonly T[]): T[] {
  const a = items.slice()
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[a[i], a[j]] = [a[j]!, a[i]!]
  }
  return a
}

/**
 * A shuffle bag: each item is drawn exactly once before any repeats. When the
 * bag empties it reshuffles for a fresh pass, and a fresh pass never opens with
 * the item just drawn, so no two consecutive draws are equal (a one-item bag is
 * exempt). Use it for canned persona replies so a short session never repeats
 * itself.
 */
export class ShuffleBag<T> {
  readonly #items: readonly T[]
  #bag: T[] = []
  #hasLast = false
  #last: T | undefined

  constructor(items: readonly T[]) {
    if (items.length === 0) throw new Error('ShuffleBag requires at least one item')
    this.#items = items
  }

  next(): T {
    if (this.#bag.length === 0) {
      const bag = shuffled(this.#items)
      // The next draw is bag's last element; move the previous draw out of that slot.
      const top = bag.length - 1
      if (this.#hasLast && top > 0 && bag[top] === this.#last) {
        ;[bag[0], bag[top]] = [bag[top]!, bag[0]!]
      }
      this.#bag = bag
    }
    const item = this.#bag.pop() ?? this.#items[0]!
    this.#last = item
    this.#hasLast = true
    return item
  }
}

export interface StreamTokensOptions {
  /** Floor delay between tokens. Default 45ms. */
  minMs?: number
  /** Random extra delay on top of `minMs`. Default 55ms. */
  jitterMs?: number
}

/**
 * Emit `text` one token at a time so a persona reads as actually talking (and
 * any status indicator keeps animating through the reveal). Whitespace is
 * preserved as its own tokens.
 */
export async function* streamTokens(
  text: string,
  opts: StreamTokensOptions = {},
): AsyncIterable<ChatStreamEvent> {
  const { minMs = 45, jitterMs = 55 } = opts
  for (const token of text.split(/(\s+)/)) {
    if (token) yield { type: 'token', text: token }
    await delay(minMs + Math.random() * jitterMs)
  }
  yield { type: 'done' }
}
