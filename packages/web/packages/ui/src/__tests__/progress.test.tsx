import { describe, it, expect, afterEach } from 'vitest'
import { render, cleanup } from '@testing-library/react'
import { Progress } from '../components/progress'

afterEach(cleanup)

function bar(ui: React.ReactElement) {
  const { container } = render(ui)
  const track = container.querySelector('[data-slot="progress"]') as HTMLElement
  const fill = container.querySelector('[data-slot="progress-indicator"]') as HTMLElement
  return { track, fill }
}

describe('Progress (ui)', () => {
  it('T1: renders a progressbar with min 0 and max 100', () => {
    const { track } = bar(<Progress value={35} />)
    expect(track).toHaveAttribute('role', 'progressbar')
    expect(track).toHaveAttribute('aria-valuemin', '0')
    expect(track).toHaveAttribute('aria-valuemax', '100')
  })

  it('T2: value 35 reports aria-valuenow 35 and a -65% fill transform', () => {
    const { track, fill } = bar(<Progress value={35} />)
    expect(track).toHaveAttribute('aria-valuenow', '35')
    expect(fill.style.transform).toBe('translateX(-65%)')
  })

  it('T3: no value defaults to 0', () => {
    const { track, fill } = bar(<Progress />)
    expect(track).toHaveAttribute('aria-valuenow', '0')
    expect(fill.style.transform).toBe('translateX(-100%)')
  })

  it('T4: a value below zero clamps to 0', () => {
    const { track, fill } = bar(<Progress value={-40} />)
    expect(track).toHaveAttribute('aria-valuenow', '0')
    expect(fill.style.transform).toBe('translateX(-100%)')
  })

  it('T5: a value above 100 clamps to 100', () => {
    const { track, fill } = bar(<Progress value={140} />)
    expect(track).toHaveAttribute('aria-valuenow', '100')
    expect(fill.style.transform).toBe('translateX(-0%)')
  })

  it('T6: aria-valuenow is rounded', () => {
    const { track } = bar(<Progress value={35.6} />)
    expect(track).toHaveAttribute('aria-valuenow', '36')
  })

  it('T7: indicatorClassName replaces the default fill tint', () => {
    const { fill } = bar(<Progress value={100} indicatorClassName="bg-apt-green" />)
    expect(fill).toHaveClass('bg-apt-green')
    expect(fill).not.toHaveClass('bg-apt-gold')
  })

  it('T8: track props are forwarded', () => {
    const { track } = bar(<Progress value={10} aria-label="Sync" id="p1" />)
    expect(track).toHaveAttribute('aria-label', 'Sync')
    expect(track).toHaveAttribute('id', 'p1')
  })

  it.skip('T9: reduce-motion override of the transition duration (jsdom does not load accessibility.css or resolve the cascade)', () => {})

  it('T10: NaN escapes the clamp and reaches aria-valuenow', () => {
    const { track, fill } = bar(<Progress value={NaN} />)
    expect(track).toHaveAttribute('aria-valuenow', 'NaN')
    // `translateX(-NaN%)` is an invalid declaration, so the style object drops it and the
    // fill is left untranslated (full width) rather than hidden.
    expect(fill.style.transform).toBe('')
  })

  it('T11: a color tint is paired with aria-valuetext', () => {
    const { track, fill } = bar(
      <Progress value={100} indicatorClassName="bg-apt-green" aria-valuetext="Complete" />,
    )
    expect(fill).toHaveClass('bg-apt-green')
    expect(track).toHaveAttribute('aria-valuetext', 'Complete')
  })

  it('T12: Infinity clamps to 100', () => {
    const { track, fill } = bar(<Progress value={Infinity} />)
    expect(track).toHaveAttribute('aria-valuenow', '100')
    expect(fill.style.transform).toBe('translateX(-0%)')
  })

  it('T13: -Infinity clamps to 0', () => {
    const { track, fill } = bar(<Progress value={-Infinity} />)
    expect(track).toHaveAttribute('aria-valuenow', '0')
    expect(fill.style.transform).toBe('translateX(-100%)')
  })
})
