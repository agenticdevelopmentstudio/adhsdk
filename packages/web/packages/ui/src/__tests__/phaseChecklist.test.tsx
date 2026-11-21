import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup, within } from '@testing-library/react'
import { PhaseChecklist } from '../blocks/phase-checklist'
import type { ProgressPhase } from '../lib/progress-count'

afterEach(cleanup)

const phases: ProgressPhase[] = [
  {
    title: 'Phase 1',
    items: [
      { text: 'Renamed', status: 'done' },
      { text: 'Migrating', status: 'in-progress' },
      { text: 'Docs', status: 'todo' },
      { text: 'Old shim', status: 'stopped' },
    ],
  },
  { title: 'Phase 2', items: [] },
]

describe('PhaseChecklist (ui)', () => {
  it('T1: renders a section per phase headed by its title', () => {
    const { container } = render(<PhaseChecklist phases={phases} />)
    expect(container.querySelectorAll('section')).toHaveLength(2)
    expect(screen.getByRole('heading', { name: /Phase 1/ })).toBeInTheDocument()
  })

  it('T2: each phase shows its own "done / total", stopped items excluded', () => {
    render(<PhaseChecklist phases={phases} />)
    expect(screen.getByText('1 / 3')).toBeInTheDocument()
    expect(screen.getByText('0 / 0')).toBeInTheDocument()
  })

  it('T3: a list item per task', () => {
    render(<PhaseChecklist phases={phases} />)
    expect(screen.getAllByRole('listitem')).toHaveLength(4)
  })

  it('T4: every row carries its status name', () => {
    render(<PhaseChecklist phases={phases} />)
    const rows = screen.getAllByRole('listitem')
    expect(within(rows[0]).getByText('done')).toBeInTheDocument()
    expect(within(rows[1]).getByText('in progress')).toBeInTheDocument()
    expect(within(rows[2]).getByText('to do')).toBeInTheDocument()
    expect(within(rows[3]).getByText('stopped')).toBeInTheDocument()
  })

  it('T5: status icons are decorative', () => {
    const { container } = render(<PhaseChecklist phases={phases} />)
    const icons = container.querySelectorAll('li svg')
    expect(icons).toHaveLength(4)
    icons.forEach((svg) => expect(svg).toHaveAttribute('aria-hidden', 'true'))
  })

  it('T6: stopped text is struck through and dim; others are not', () => {
    render(<PhaseChecklist phases={phases} />)
    expect(screen.getByText('Old shim')).toHaveClass('line-through', 'text-apt-text-dim')
    expect(screen.getByText('Renamed')).not.toHaveClass('line-through')
  })

  it('T7: forwards className and host attributes', () => {
    const { container } = render(
      <PhaseChecklist phases={[]} className="mt-2" data-testid="pc" />,
    )
    expect(container.firstElementChild).toHaveClass('mt-2')
    expect(container.firstElementChild).toHaveAttribute('data-testid', 'pc')
  })
})
