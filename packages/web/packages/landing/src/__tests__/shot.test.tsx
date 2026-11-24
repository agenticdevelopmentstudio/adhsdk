import { describe, expect, it } from 'vitest'
import { render } from '@testing-library/react'
import { Shot } from '../index'

describe('Shot conformance vectors', () => {
  it('shot-001 frame-chrome: bar with three dots and a title', () => {
    const { container } = render(<Shot title="My App" caption="c" />)
    const bar = container.querySelector('.lp-shot > .lp-shot__bar')!
    expect(bar).toBeTruthy()
    expect(bar.querySelectorAll('.lp-shot__dot')).toHaveLength(3)
    expect(bar.querySelector('.lp-shot__name')!.textContent).toBe('My App')
  })

  it('shot-002 title-in-bar: title is text in .lp-shot__name', () => {
    const { container } = render(<Shot title="MyWindow" caption="c" />)
    expect(container.querySelector('.lp-shot__name')!.textContent).toBe('MyWindow')
  })

  it('shot-003 media-verbatim: img is a direct child of .lp-shot, unwrapped', () => {
    const { container } = render(<Shot title="T" caption="c" media={<img src="x.png" />} />)
    const img = container.querySelector('.lp-shot > img')!
    expect(img).toBeTruthy()
    expect(img.getAttribute('class')).toBeNull()
    expect(container.querySelector('.lp-shot__placeholder')).toBeNull()
  })

  it('shot-004 placeholder-when-no-media: placeholder renders when media undefined', () => {
    const { container } = render(<Shot title="T" caption="c" />)
    expect(container.querySelector('.lp-shot > .lp-shot__placeholder')).toBeTruthy()
  })

  it('shot-005 caption-in-placeholder: caption sits in a <b>', () => {
    const { container } = render(<Shot title="T" caption="Screenshot pending" />)
    expect(container.querySelector('.lp-shot__placeholder b')!.textContent).toBe('Screenshot pending')
  })

  it('shot-006 pending-label-above-caption: label precedes the <b>', () => {
    const { container } = render(<Shot title="T" caption="cap" pendingLabel="Capture in progress" />)
    const ph = container.querySelector('.lp-shot__placeholder')!
    expect(ph.firstChild!.textContent).toBe('Capture in progress')
    expect(ph.lastElementChild!.tagName).toBe('B')
    expect(ph.textContent!.indexOf('Capture in progress')).toBeLessThan(ph.textContent!.indexOf('cap'))
  })

  it('shot-007 pending-label-above-caption: no label means only the <b>', () => {
    const { container } = render(<Shot title="T" caption="cap" />)
    const ph = container.querySelector('.lp-shot__placeholder')!
    expect(ph.childNodes).toHaveLength(1)
    expect(ph.firstElementChild!.tagName).toBe('B')
  })

  it('shot-008 pending-label-verbatim: custom node keeps its class', () => {
    const { container } = render(
      <Shot title="T" caption="cap" pendingLabel={<span className="custom">Loading</span>} />,
    )
    const span = container.querySelector('.lp-shot__placeholder > span')!
    expect(span.getAttribute('class')).toBe('custom')
    expect(span.textContent).toBe('Loading')
  })

  it('shot-009 falsy-pending-label-omitted: empty string adds no label', () => {
    const { container } = render(<Shot title="T" caption="cap" pendingLabel="" />)
    expect(container.querySelector('.lp-shot__placeholder')!.textContent).toBe('cap')
  })

  it('shot-010 media-verbatim: video replaces the placeholder', () => {
    const { container } = render(<Shot title="T" caption="c" media={<video src="x.mp4" />} />)
    expect(container.querySelector('.lp-shot__placeholder')).toBeNull()
    expect(container.querySelector('.lp-shot > video')).toBeTruthy()
  })

  it('shot-011 caption-in-placeholder: empty caption gives an empty <b>', () => {
    const { container } = render(<Shot title="T" caption="" />)
    const b = container.querySelector('.lp-shot__placeholder b')!
    expect(b).toBeTruthy()
    expect(b.textContent).toBe('')
  })

  it('shot-012 title-in-bar: empty title leaves frame and dots', () => {
    const { container } = render(<Shot title="" caption="c" />)
    expect(container.querySelector('.lp-shot__name')!.textContent).toBe('')
    expect(container.querySelector('.lp-shot')).toBeTruthy()
    expect(container.querySelectorAll('.lp-shot__dot')).toHaveLength(3)
  })

  it('shot-013 falsy-pending-label-omitted: pendingLabel={false} adds no label', () => {
    const { container } = render(<Shot title="T" caption="cap" pendingLabel={false} />)
    expect(container.querySelector('.lp-shot__placeholder')!.textContent).toBe('cap')
  })

  it('shot-014 falsy-pending-label-omitted: pendingLabel={null} adds no label', () => {
    const { container } = render(<Shot title="T" caption="cap" pendingLabel={null} />)
    expect(container.querySelector('.lp-shot__placeholder')!.textContent).toBe('cap')
  })

  it('shot-015 placeholder-when-no-media: media={null} renders no placeholder', () => {
    const { container } = render(<Shot title="T" caption="c" media={null} />)
    expect(container.querySelector('.lp-shot__placeholder')).toBeNull()
    expect(container.querySelector('.lp-shot__bar')).toBeTruthy()
  })

  it('shot-016 placeholder-when-no-media: media={false} renders no placeholder', () => {
    const { container } = render(<Shot title="T" caption="c" media={false} />)
    expect(container.querySelector('.lp-shot__placeholder')).toBeNull()
    expect(container.querySelector('.lp-shot__bar')).toBeTruthy()
  })
})
