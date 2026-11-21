import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import { ProgressSummary } from '../blocks/progress-summary'

afterEach(cleanup)

function fill(container: HTMLElement) {
  return container.querySelector('[data-slot="progress-indicator"]') as HTMLElement
}

describe('ProgressSummary (ui)', () => {
  it('T1: shows "x of y items done" and the percentage', () => {
    render(<ProgressSummary done={1} total={3} />)
    expect(screen.getByText('1 of 3 items done')).toBeInTheDocument()
    expect(screen.getByText('33%')).toBeInTheDocument()
  })

  it('T2: label replaces "items"', () => {
    render(<ProgressSummary done={2} total={4} label="steps" />)
    expect(screen.getByText('2 of 4 steps done')).toBeInTheDocument()
  })

  it('T3: the bar is a progressbar named by the same text', () => {
    render(<ProgressSummary done={2} total={4} />)
    const bar = screen.getByRole('progressbar', { name: '2 of 4 items done' })
    expect(bar).toHaveAttribute('aria-valuenow', '50')
  })

  it('T4: 0 of 0 is 0% and not green', () => {
    const { container } = render(<ProgressSummary done={0} total={0} />)
    expect(screen.getByText('0%')).toBeInTheDocument()
    expect(fill(container)).not.toHaveClass('bg-apt-green')
  })

  it('T5: the indicator is green only when done equals a non-zero total', () => {
    const full = render(<ProgressSummary done={3} total={3} />)
    expect(fill(full.container)).toHaveClass('bg-apt-green')
    cleanup()
    const part = render(<ProgressSummary done={2} total={3} />)
    expect(fill(part.container)).not.toHaveClass('bg-apt-green')
  })

  it('T6: percent rounds down', () => {
    render(<ProgressSummary done={199} total={200} />)
    expect(screen.getByText('99%')).toBeInTheDocument()
  })

  it('T7: forwards className and host attributes to the root', () => {
    const { container } = render(
      <ProgressSummary done={1} total={2} className="mt-4" data-testid="ps" />,
    )
    expect(container.firstElementChild).toHaveClass('mt-4')
    expect(container.firstElementChild).toHaveAttribute('data-testid', 'ps')
  })
})
