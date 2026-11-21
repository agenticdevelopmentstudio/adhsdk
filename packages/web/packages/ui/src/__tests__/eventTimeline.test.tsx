import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup, within } from '@testing-library/react'
import { EventTimeline, type TimelineEvent } from '../blocks/event-timeline'

afterEach(cleanup)

const events: TimelineEvent[] = [
  { time: '2026-11-21T09:00:00Z', title: 'Built', state: 'done', detail: '**ok**' },
  { time: '2026-11-21T09:05:00Z', title: 'Publishing', state: 'running' },
  { time: '2026-11-21T09:06:00Z', title: 'Slow', state: 'warning' },
  { time: '2026-11-21T09:07:00Z', title: 'Broke', state: 'failed' },
  { time: '2026-11-21T09:08:00Z', title: 'Note' },
]

describe('EventTimeline (ui)', () => {
  it('T1: an ordered list with a row per event, in the given order', () => {
    const { container } = render(<EventTimeline events={events} />)
    expect(container.querySelector('ol')).toBeInTheDocument()
    const rows = screen.getAllByRole('listitem')
    expect(rows).toHaveLength(5)
    expect(within(rows[0]!).getByText('Built')).toBeInTheDocument()
    expect(within(rows[4]!).getByText('Note')).toBeInTheDocument()
  })

  it('T2: each row names its state; no state reads as info', () => {
    render(<EventTimeline events={events} />)
    const rows = screen.getAllByRole('listitem')
    const names = ['done', 'running', 'warning', 'failed', 'info']
    names.forEach((n, i) => expect(within(rows[i]!).getByText(n)).toHaveClass('sr-only'))
  })

  it('T2: the dot tone follows the state', () => {
    const { container } = render(<EventTimeline events={events} />)
    const dots = Array.from(container.querySelectorAll('li span[aria-hidden="true"]'))
    expect(dots[0]).toHaveClass('text-apt-green')
    expect(dots[1]).toHaveClass('text-apt-blue')
    expect(dots[2]).toHaveClass('text-apt-orange')
    expect(dots[3]).toHaveClass('text-apt-red')
    expect(dots[4]).toHaveClass('text-apt-text-muted')
  })

  it('T3: only the running dot pulses', () => {
    const { container } = render(<EventTimeline events={events} />)
    expect(container.querySelectorAll('.animate-pulse')).toHaveLength(1)
    expect(screen.getAllByRole('listitem')[1]!.querySelector('.animate-pulse')).toBeInTheDocument()
  })

  it('T4: the time is in a <time> with the ISO dateTime; formatTime is used', () => {
    const { container, rerender } = render(<EventTimeline events={events.slice(0, 1)} />)
    const t = container.querySelector('time')!
    expect(t).toHaveAttribute('datetime', '2026-11-21T09:00:00Z')
    expect(t).toHaveTextContent(new Date('2026-11-21T09:00:00Z').toLocaleString())
    expect(t).toHaveClass('font-mono', 'text-apt-text-dim')
    rerender(<EventTimeline events={events.slice(0, 1)} formatTime={(iso) => `at ${iso}`} />)
    expect(screen.getByText('at 2026-11-21T09:00:00Z')).toBeInTheDocument()
  })

  it('T5: detail goes through renderMarkdown when given, else plain text in a <p>', () => {
    const { rerender } = render(
      <EventTimeline events={events.slice(0, 1)} renderMarkdown={(md) => <b data-testid="md">{md}</b>} />,
    )
    expect(screen.getByTestId('md')).toHaveTextContent('**ok**')
    rerender(<EventTimeline events={events.slice(0, 1)} />)
    const p = screen.getByText('**ok**')
    expect(p.tagName).toBe('P')
  })

  it('T5: no detail renders no detail element', () => {
    const { container } = render(<EventTimeline events={events.slice(1, 2)} />)
    expect(container.querySelector('p')).toBeNull()
  })

  it('T6: connectors join rows; the last row has none', () => {
    render(<EventTimeline events={events.slice(0, 3)} />)
    expect(screen.getAllByTestId('timeline-connector')).toHaveLength(2)
  })

  it('T7: empty shows the default label, or a custom one, and no list', () => {
    const { container, rerender } = render(<EventTimeline events={[]} />)
    expect(screen.getByText('No events yet.')).toBeInTheDocument()
    expect(container.querySelector('ol')).toBeNull()
    rerender(<EventTimeline events={[]} emptyLabel="Nothing" />)
    expect(screen.getByText('Nothing')).toBeInTheDocument()
  })

  it('T8: className reaches the root', () => {
    const { container } = render(<EventTimeline events={events} className="mt-2" />)
    expect(container.firstElementChild).toHaveClass('mt-2')
  })
})
