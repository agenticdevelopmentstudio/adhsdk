import { afterEach, beforeEach, describe, it, expect, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { LogPanel } from '../LogPanel'
import type { LogColumn, LogLine } from '../types'

type Ctx = { sessionId: string }

const baseColumns: LogColumn<Ctx>[] = [
  { id: 'time', title: 'Time', width: 80, defaultMono: true },
  { id: 'kind', title: 'Kind', width: 80 },
  { id: 'message', title: 'Message' },
]

function makeLines(): LogLine<Ctx>[] {
  return [
    {
      id: 'a',
      context: { sessionId: 's1' },
      values: {
        time: '12:00',
        kind: { text: 'INFO', level: 'info' },
        message: 'first event',
      },
    },
    {
      id: 'b',
      context: { sessionId: 's2' },
      values: {
        time: '12:01',
        kind: { text: 'ERROR', level: 'error', strong: true },
        message: 'second event',
      },
    },
  ]
}

describe('LogPanel', () => {
  it('renders column headers', () => {
    render(<LogPanel<Ctx> columns={baseColumns} lines={makeLines()} />)
    expect(screen.getByText('Time')).toBeTruthy()
    expect(screen.getByText('Kind')).toBeTruthy()
    expect(screen.getByText('Message')).toBeTruthy()
  })

  it('renders a row per line with cell text by column id', () => {
    render(<LogPanel<Ctx> columns={baseColumns} lines={makeLines()} />)
    expect(screen.getByText('first event')).toBeTruthy()
    expect(screen.getByText('second event')).toBeTruthy()
    expect(screen.getByText('INFO')).toBeTruthy()
    expect(screen.getByText('ERROR')).toBeTruthy()
  })

  it('renders empty state when no lines', () => {
    render(<LogPanel<Ctx> columns={baseColumns} lines={[]} emptyMessage="nothing" />)
    expect(screen.getByText('nothing')).toBeTruthy()
  })

  it('caps to maxLines (keeps the most recent)', () => {
    const lines: LogLine<Ctx>[] = Array.from({ length: 5 }, (_, i) => ({
      id: `${i}`,
      values: { message: `m${i}` },
    }))
    render(<LogPanel<Ctx> columns={baseColumns} lines={lines} maxLines={2} />)
    expect(screen.queryByText('m0')).toBeNull()
    expect(screen.queryByText('m2')).toBeNull()
    expect(screen.getByText('m3')).toBeTruthy()
    expect(screen.getByText('m4')).toBeTruthy()
  })

  it('fires onCellClick with the full line when a cell is clicked', () => {
    const onCellClick = vi.fn()
    const columns: LogColumn<Ctx>[] = [
      ...baseColumns.slice(0, 2),
      { id: 'session', title: 'Session', isClickable: true, onCellClick },
      baseColumns[2],
    ]
    const lines: LogLine<Ctx>[] = [
      {
        id: 'a',
        context: { sessionId: 's1' },
        values: { session: { text: 'sess-1', link: true }, message: 'go' },
      },
    ]
    render(<LogPanel<Ctx> columns={columns} lines={lines} />)
    fireEvent.click(screen.getByText('sess-1'))
    expect(onCellClick).toHaveBeenCalledTimes(1)
    expect(onCellClick.mock.calls[0][0]).toMatchObject({ id: 'a', context: { sessionId: 's1' } })
  })

  it('renders unknown-column cells as empty', () => {
    const lines: LogLine<Ctx>[] = [
      { id: 'a', values: { message: 'present', mystery: 'should not show' } },
    ]
    render(<LogPanel<Ctx> columns={baseColumns} lines={lines} />)
    expect(screen.getByText('present')).toBeTruthy()
    expect(screen.queryByText('should not show')).toBeNull()
  })

  it('hides the header when showHeader=false', () => {
    render(<LogPanel<Ctx> columns={baseColumns} lines={makeLines()} showHeader={false} />)
    expect(screen.queryByRole('columnheader')).toBeNull()
  })
})

describe('LogPanel followTail', () => {
  const ROW = 20
  const VIEW = 100
  const numbered = (n: number): LogLine<Ctx>[] =>
    Array.from({ length: n }, (_, i) => ({ id: `${i}`, values: { message: `m${i}` } }))

  /** At the end means the last row's bottom edge meets the viewport's bottom edge. */
  function expectAtEnd(body: HTMLElement, rows: number) {
    expect(body.scrollHeight).toBe(rows * ROW)
    expect(body.scrollTop).toBe(body.scrollHeight - body.clientHeight)
  }

  // jsdom lays nothing out. Give every `.lp-body` a height per row and a scrollTop
  // that clamps like a browser's (to scrollHeight - clientHeight). The getters go on
  // HTMLElement.prototype before each test renders, so the mount-time layout effect
  // already sees them; any other element falls through to jsdom's own value.
  const tops = new WeakMap<HTMLElement, number>()
  const isBody = (el: HTMLElement) => el.classList.contains('lp-body')
  const rowsHeight = (el: HTMLElement) => el.querySelectorAll('.lp-row').length * ROW
  const STUBBED = ['clientHeight', 'scrollHeight', 'scrollTop'] as const
  const saved = new Map<string, PropertyDescriptor | undefined>()

  function jsdomValue(el: HTMLElement, name: string): number {
    const desc = Object.getOwnPropertyDescriptor(Element.prototype, name)
    return desc?.get ? (desc.get.call(el) as number) : 0
  }

  beforeEach(() => {
    for (const name of STUBBED) saved.set(name, Object.getOwnPropertyDescriptor(HTMLElement.prototype, name))
    Object.defineProperty(HTMLElement.prototype, 'clientHeight', {
      configurable: true,
      get(this: HTMLElement) { return isBody(this) ? VIEW : jsdomValue(this, 'clientHeight') },
    })
    Object.defineProperty(HTMLElement.prototype, 'scrollHeight', {
      configurable: true,
      get(this: HTMLElement) { return isBody(this) ? rowsHeight(this) : jsdomValue(this, 'scrollHeight') },
    })
    Object.defineProperty(HTMLElement.prototype, 'scrollTop', {
      configurable: true,
      get(this: HTMLElement) { return isBody(this) ? (tops.get(this) ?? 0) : jsdomValue(this, 'scrollTop') },
      set(this: HTMLElement, v: number) {
        if (isBody(this)) tops.set(this, Math.max(0, Math.min(v, rowsHeight(this) - VIEW)))
        else Object.getOwnPropertyDescriptor(Element.prototype, 'scrollTop')?.set?.call(this, v)
      },
    })
  })

  afterEach(() => {
    for (const name of STUBBED) {
      const desc = saved.get(name)
      if (desc) Object.defineProperty(HTMLElement.prototype, name, desc)
      else delete (HTMLElement.prototype as unknown as Record<string, unknown>)[name]
    }
    saved.clear()
  })

  /** Scroll the body as a user would: move it, then let the panel see the scroll event. */
  function scroller(body: HTMLElement) {
    return {
      scrollTo(v: number) { body.scrollTop = v; fireEvent.scroll(body) },
      toEnd() { this.scrollTo(body.scrollHeight - VIEW) },
    }
  }

  function setup() {
    const view = render(<LogPanel<Ctx> columns={baseColumns} lines={numbered(10)} />)
    const body = view.container.querySelector<HTMLElement>('.lp-body')!
    return { ...view, body, scroll: scroller(body) }
  }

  it('opens scrolled to the end', () => {
    const { body } = setup()
    expectAtEnd(body, 10)
  })

  it('follows new lines while the view is at the end', () => {
    const { body, rerender } = setup()
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} />)
    expectAtEnd(body, 11)
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(12)} />)
    expectAtEnd(body, 12)
  })

  it('stays put while scrolled up, and follows again once back at the end', () => {
    const { body, rerender, scroll } = setup()
    scroll.scrollTo(40)
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} />)
    expect(body.scrollTop).toBe(40)

    scroll.toEnd()
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(12)} />)
    expectAtEnd(body, 12)
  })

  it('counts a view within a few pixels of the end as at the end', () => {
    const { body, rerender, scroll } = setup()
    scroll.scrollTo(40) // un-pin first, so only the 3px scroll can re-pin it
    scroll.scrollTo(10 * ROW - VIEW - 3)
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} />)
    expectAtEnd(body, 11)
  })

  it('treats a view just past the slack from the end as scrolled up', () => {
    const { body, rerender, scroll } = setup()
    scroll.scrollTo(40)
    scroll.scrollTo(10 * ROW - VIEW - 5)
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} />)
    expect(body.scrollTop).toBe(10 * ROW - VIEW - 5)
  })

  it('keeps following once maxLines caps the list and the row count stops growing', () => {
    const view = render(<LogPanel<Ctx> columns={baseColumns} lines={numbered(10)} maxLines={10} />)
    const body = view.container.querySelector<HTMLElement>('.lp-body')!
    expectAtEnd(body, 10)
    view.rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} maxLines={10} />)
    expectAtEnd(body, 10)
    body.scrollTop = 0
    view.rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(12)} maxLines={10} />)
    expectAtEnd(body, 10)
    expect(screen.getByText('m11')).toBeTruthy()
  })

  it('never moves the view when followTail is off', () => {
    const view = render(<LogPanel<Ctx> columns={baseColumns} lines={numbered(10)} followTail={false} />)
    const body = view.container.querySelector<HTMLElement>('.lp-body')!
    expect(body.scrollTop).toBe(0)
    view.rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} followTail={false} />)
    expect(body.scrollTop).toBe(0)
  })

  it('snaps to the end on the render that turns followTail back on', () => {
    const view = render(<LogPanel<Ctx> columns={baseColumns} lines={numbered(10)} followTail={false} />)
    const body = view.container.querySelector<HTMLElement>('.lp-body')!
    const scroll = scroller(body)
    scroll.scrollTo(40)
    view.rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(10)} followTail />)
    expectAtEnd(body, 10)
  })
})
