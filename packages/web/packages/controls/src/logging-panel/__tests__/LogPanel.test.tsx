import { describe, it, expect, vi } from 'vitest'
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

  /** jsdom lays nothing out: give the scroller a height per row and a settable scrollTop. */
  function measure(body: HTMLElement) {
    let top = 0
    Object.defineProperty(body, 'clientHeight', { configurable: true, get: () => VIEW })
    Object.defineProperty(body, 'scrollHeight', {
      configurable: true,
      get: () => body.querySelectorAll('.lp-row').length * ROW,
    })
    Object.defineProperty(body, 'scrollTop', {
      configurable: true,
      get: () => top,
      set: (v: number) => { top = v },
    })
    return {
      scrollTo(v: number) { body.scrollTop = v; fireEvent.scroll(body) },
      toEnd() { this.scrollTo(body.scrollHeight - VIEW) },
    }
  }

  function setup() {
    const view = render(<LogPanel<Ctx> columns={baseColumns} lines={numbered(10)} />)
    const body = view.container.querySelector<HTMLElement>('.lp-body')!
    return { ...view, body, scroll: measure(body) }
  }

  it('follows new lines while the view is at the end', () => {
    const { body, rerender } = setup()
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} />)
    expect(body.scrollTop).toBe(11 * ROW)
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(12)} />)
    expect(body.scrollTop).toBe(12 * ROW)
  })

  it('stays put while scrolled up, and follows again once back at the end', () => {
    const { body, rerender, scroll } = setup()
    scroll.scrollTo(40)
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} />)
    expect(body.scrollTop).toBe(40)

    scroll.toEnd()
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(12)} />)
    expect(body.scrollTop).toBe(12 * ROW)
  })

  it('counts a view within a few pixels of the end as at the end', () => {
    const { body, rerender, scroll } = setup()
    scroll.scrollTo(10 * ROW - VIEW - 3)
    rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} />)
    expect(body.scrollTop).toBe(11 * ROW)
  })

  it('keeps following once maxLines caps the list and the row count stops growing', () => {
    const view = render(<LogPanel<Ctx> columns={baseColumns} lines={numbered(10)} maxLines={10} />)
    const body = view.container.querySelector<HTMLElement>('.lp-body')!
    measure(body)
    view.rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} maxLines={10} />)
    expect(body.scrollTop).toBe(10 * ROW)
    body.scrollTop = 0
    view.rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(12)} maxLines={10} />)
    expect(body.scrollTop).toBe(10 * ROW)
    expect(screen.getByText('m11')).toBeTruthy()
  })

  it('never moves the view when followTail is off', () => {
    const view = render(<LogPanel<Ctx> columns={baseColumns} lines={numbered(10)} followTail={false} />)
    const body = view.container.querySelector<HTMLElement>('.lp-body')!
    measure(body)
    view.rerender(<LogPanel<Ctx> columns={baseColumns} lines={numbered(11)} followTail={false} />)
    expect(body.scrollTop).toBe(0)
  })
})
