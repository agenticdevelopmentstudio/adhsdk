/** InfoPanel host-attribute passthrough — remaining HTML attributes (data-*,
 *  id, handlers) spread onto the panel's root <section> so hosts can tag it
 *  for tests/analytics without a wrapper element. */

import * as React from 'react'
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import '@testing-library/jest-dom/vitest'

import { InfoPanel } from '../blocks/info-panel'

describe('InfoPanel', () => {
  it('spreads host attributes onto the root section', () => {
    render(
      <InfoPanel title="Fleet" data-testid="panel" data-kind="monitor" id="fleet-panel">
        body
      </InfoPanel>,
    )
    const panel = screen.getByTestId('panel')
    expect(panel.tagName).toBe('SECTION')
    expect(panel).toHaveAttribute('data-kind', 'monitor')
    expect(panel).toHaveAttribute('id', 'fleet-panel')
  })

  it('keeps the computed accessible name despite the spread', () => {
    render(
      <InfoPanel title="Fleet" data-testid="panel">
        body
      </InfoPanel>,
    )
    expect(screen.getByRole('region', { name: 'Fleet' })).toBeInTheDocument()
  })

  it('honors a raw aria-label when the title is not a string (no clobber)', () => {
    render(
      <InfoPanel title={<span>Fleet</span>} aria-label="Traffic overview">
        body
      </InfoPanel>,
    )
    // The raw aria-label must survive the {...rest} spread, not be overridden by
    // the computed (undefined) label from a non-string title.
    expect(screen.getByRole('region', { name: 'Traffic overview' })).toBeInTheDocument()
  })

  it('prefers the explicit ariaLabel prop over a raw aria-label', () => {
    render(
      <InfoPanel title="ignored" ariaLabel="Explicit" aria-label="Raw">
        body
      </InfoPanel>,
    )
    expect(screen.getByRole('region', { name: 'Explicit' })).toBeInTheDocument()
  })
})

describe('InfoPanel — conformance vectors', () => {
  const header = (panel: HTMLElement): HTMLElement => panel.firstElementChild as HTMLElement
  const body = (panel: HTMLElement): HTMLElement => panel.lastElementChild as HTMLElement

  it('T1 header shows icon, then the title, then titleAfter', () => {
    render(
      <InfoPanel
        title="Fleet"
        icon={<i data-testid="icon" />}
        titleAfter={<button data-testid="copy">copy</button>}
        data-testid="panel"
      >
        x
      </InfoPanel>,
    )
    const group = header(screen.getByTestId('panel')).firstElementChild!
    expect(Array.from(group.children).map((c) => c.textContent || c.firstElementChild?.getAttribute('data-testid') || c.getAttribute('data-testid'))).toEqual(['icon', 'Fleet', 'copy'])
  })

  it('T2 a positive count renders after the title', () => {
    render(<InfoPanel title="Fleet" count={12}>x</InfoPanel>)
    const t = screen.getByText('Fleet')
    const c = screen.getByText('12')
    expect(t.compareDocumentPosition(c)).toBe(Node.DOCUMENT_POSITION_FOLLOWING)
  })

  it('T3 count 0 or omitted renders no count', () => {
    const { rerender } = render(<InfoPanel title="Fleet" count={0} data-testid="panel">x</InfoPanel>)
    expect(header(screen.getByTestId('panel')).firstElementChild!.children).toHaveLength(1)
    rerender(<InfoPanel title="Fleet" data-testid="panel">x</InfoPanel>)
    expect(header(screen.getByTestId('panel')).firstElementChild!.children).toHaveLength(1)
  })

  it('T4 center and actions land in their own header slots', () => {
    render(
      <InfoPanel title="Fleet" center={<b data-testid="bar" />} actions={<b data-testid="gear" />} data-testid="panel">
        x
      </InfoPanel>,
    )
    const slots = Array.from(header(screen.getByTestId('panel')).children)
    expect(slots).toHaveLength(3)
    expect(slots[1]!).toContainElement(screen.getByTestId('bar'))
    expect(slots[1]!).toHaveClass('justify-center', 'flex-1')
    expect(slots[2]!).toContainElement(screen.getByTestId('gear'))
  })

  it('T5 actions are right-justified via ml-auto when there is no center', () => {
    const { rerender } = render(
      <InfoPanel title="Fleet" actions={<b data-testid="gear" />} data-testid="panel">x</InfoPanel>,
    )
    expect(screen.getByTestId('gear').parentElement).toHaveClass('ml-auto')
    rerender(
      <InfoPanel title="Fleet" center={<i />} actions={<b data-testid="gear" />} data-testid="panel">x</InfoPanel>,
    )
    expect(screen.getByTestId('gear').parentElement).not.toHaveClass('ml-auto')
  })

  it.skip('T6 both headers have min-height 41px and align — jsdom has no real layout to assert alignment against', () => {})

  it('T7 content-sized by default: outer flex 0 0 auto, body not overflow-y-auto', () => {
    render(<InfoPanel title="Fleet" data-testid="panel">x</InfoPanel>)
    const panel = screen.getByTestId('panel')
    expect(panel.style.flex).toBe('0 0 auto')
    expect(body(panel)).not.toHaveClass('overflow-y-auto')
  })

  it.skip('T8 scroll mode fills and scrolls overflowing content — jsdom does not lay out or scroll content', () => {})

  it('T9 bodyRef resolves to the body element', () => {
    const ref = React.createRef<HTMLDivElement>()
    render(<InfoPanel title="Fleet" bodyRef={ref} data-testid="panel" scroll>x</InfoPanel>)
    expect(ref.current).toBe(body(screen.getByTestId('panel')))
    expect(ref.current).toHaveClass('overflow-y-auto')
  })

  it('T10 a string title names the section', () => {
    render(<InfoPanel title="Fleet" data-testid="panel">x</InfoPanel>)
    expect(screen.getByTestId('panel')).toHaveAttribute('aria-label', 'Fleet')
  })

  it('T11 a non-string title with ariaLabel names the section', () => {
    render(<InfoPanel title={<b>x</b>} ariaLabel="Fleet" data-testid="panel">x</InfoPanel>)
    expect(screen.getByTestId('panel')).toHaveAttribute('aria-label', 'Fleet')
  })

  it('T12 default body padding differs by mode', () => {
    const { rerender } = render(<InfoPanel title="F" scroll data-testid="panel">x</InfoPanel>)
    expect(body(screen.getByTestId('panel')).getAttribute('style')).toContain('8px 16px 10px')
    rerender(<InfoPanel title="F" data-testid="panel">x</InfoPanel>)
    expect(body(screen.getByTestId('panel')).getAttribute('style')).toContain('12px 16px')
  })

  it('T13 flex and maxHeight pass through to the outer style', () => {
    render(<InfoPanel title="F" flex="2 1 0%" maxHeight={400} data-testid="panel">x</InfoPanel>)
    const p = screen.getByTestId('panel')
    expect(p.style.flex).toBe('2 1 0%')
    expect(p.style.maxHeight).toBe('400px')
  })

  it('T14 host attributes pass through and aria-label still defaults from title', () => {
    render(<InfoPanel title="Fleet" data-testid="panel" data-kind="monitor">x</InfoPanel>)
    const p = screen.getByTestId('panel')
    expect(p).toHaveAttribute('data-kind', 'monitor')
    expect(p).toHaveAttribute('aria-label', 'Fleet')
  })

  it('T15 the ariaLabel prop wins over rest aria-label and string title', () => {
    render(<InfoPanel title="Fleet" aria-label="FromRest" ariaLabel="Explicit" data-testid="panel">x</InfoPanel>)
    expect(screen.getByTestId('panel')).toHaveAttribute('aria-label', 'Explicit')
  })

  it('T16 rest aria-label wins over the string title when ariaLabel is absent', () => {
    render(<InfoPanel title="Fleet" aria-label="FromRest" data-testid="panel">x</InfoPanel>)
    expect(screen.getByTestId('panel')).toHaveAttribute('aria-label', 'FromRest')
  })

  it('T17 a negative count renders no count', () => {
    render(<InfoPanel title="Fleet" count={-3} data-testid="panel">x</InfoPanel>)
    expect(screen.queryByText('-3')).not.toBeInTheDocument()
  })

  it('T18 a non-string title with no ariaLabel leaves the section unnamed', () => {
    render(<InfoPanel title={<b>x</b>} data-testid="panel">x</InfoPanel>)
    expect(screen.getByTestId('panel')).not.toHaveAttribute('aria-label')
  })

  it('T19 rest aria-label names the region for a non-string title', () => {
    render(<InfoPanel title={<b>x</b>} aria-label="FromRest" data-testid="panel">x</InfoPanel>)
    expect(screen.getByTestId('panel')).toHaveAttribute('aria-label', 'FromRest')
  })

  it('T20 the icon wrapper is aria-hidden while the title stays exposed', () => {
    render(<InfoPanel title="Fleet" icon={<i data-testid="icon" />}>x</InfoPanel>)
    expect(screen.getByTestId('icon').parentElement).toHaveAttribute('aria-hidden', 'true')
    expect(screen.getByText('Fleet')).not.toHaveAttribute('aria-hidden')
  })

  it('T21 style wins over the flex and maxHeight props', () => {
    render(
      <InfoPanel title="F" flex="2 1 0%" maxHeight={400} style={{ flex: '3 1 0%', maxHeight: 200 }} data-testid="panel">x</InfoPanel>,
    )
    const p = screen.getByTestId('panel')
    expect(p.style.flex).toBe('3 1 0%')
    expect(p.style.maxHeight).toBe('200px')
  })

  it('T22 className overrides the default radius', () => {
    render(<InfoPanel title="F" className="rounded-none" data-testid="panel">x</InfoPanel>)
    const p = screen.getByTestId('panel')
    expect(p).toHaveClass('rounded-none')
    expect(p).not.toHaveClass('rounded-[10px]')
  })
})
