import { describe, it, expect, afterEach } from 'vitest'
import { render, cleanup } from '@testing-library/react'
import { Progress } from '../components/Progress'

afterEach(cleanup)

function parts(ui: React.ReactElement) {
  const { container } = render(ui)
  return {
    wrapper: container.firstElementChild as HTMLElement,
    track: container.querySelector('[role="progressbar"]') as HTMLElement,
    fill: container.querySelector('.aws-progress__bar') as HTMLElement,
    label: container.querySelector('.aws-field__label'),
    hint: container.querySelector('.aws-field__hint'),
  }
}

describe('Progress (controls)', () => {
  it('T14: label and hint render around the progressbar', () => {
    const { label, hint, track } = parts(<Progress label="Sync" hint="Uploading" value={40} />)
    expect(label?.textContent).toBe('Sync')
    expect(hint?.textContent).toBe('Uploading')
    expect(track).toHaveAttribute('aria-valuenow', '40')
  })

  it('T15: valuemin is fixed at 0 and valuemax follows max', () => {
    const { track, fill } = parts(<Progress value={5} max={10} />)
    expect(track).toHaveAttribute('aria-valuemin', '0')
    expect(track).toHaveAttribute('aria-valuemax', '10')
    expect(fill.style.width).toBe('50%')
  })

  it('T16: a negative value is reported raw while the fill width clamps to 0%', () => {
    const { track, fill } = parts(<Progress value={-40} />)
    expect(track).toHaveAttribute('aria-valuenow', '-40')
    expect(fill.style.width).toBe('0%')
  })

  it('T17: a value above max is reported raw while the fill width clamps to 100%', () => {
    const { track, fill } = parts(<Progress value={140} max={100} />)
    expect(track).toHaveAttribute('aria-valuenow', '140')
    expect(fill.style.width).toBe('100%')
  })

  it('T18: a fractional value is not rounded', () => {
    const { track } = parts(<Progress value={35.6} />)
    expect(track).toHaveAttribute('aria-valuenow', '35.6')
  })

  it('T19: no value omits aria-valuenow and fills 0%', () => {
    const { track, fill } = parts(<Progress />)
    expect(track.hasAttribute('aria-valuenow')).toBe(false)
    expect(fill.style.width).toBe('0%')
  })

  it('T20: indeterminate adds its modifier, drops aria-valuenow and sets no inline width', () => {
    const { wrapper, track, fill } = parts(<Progress indeterminate />)
    expect(wrapper).toHaveClass('aws-field--progress-indeterminate')
    expect(track.hasAttribute('aria-valuenow')).toBe(false)
    expect(fill.style.width).toBe('')
    expect(fill.hasAttribute('style')).toBe(false)
  })
})
