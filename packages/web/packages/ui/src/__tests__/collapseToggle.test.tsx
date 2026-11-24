/** Conformance tests for CollapseToggle (recipe ui/components/actions/collapse-toggle).
 *  One `it` per conformance vector, titled with the vector id. */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { CollapseToggle } from '../components/collapse-toggle'

function setup(props: Partial<React.ComponentProps<typeof CollapseToggle>> = {}) {
  const onToggle = vi.fn()
  render(<CollapseToggle collapsed={true} label="Topic List" onToggle={onToggle} {...props} />)
  return { onToggle, el: screen.getByRole('button') }
}

describe('CollapseToggle conformance', () => {
  it('collapse-toggle-001 shows » when collapsed', () => {
    expect(setup({ collapsed: true }).el).toHaveTextContent('»')
  })
  it('collapse-toggle-002 shows « when expanded', () => {
    expect(setup({ collapsed: false }).el).toHaveTextContent('«')
  })
  it('collapse-toggle-003 aria-label "Expand Topic List" when collapsed', () => {
    expect(setup({ collapsed: true }).el).toHaveAttribute('aria-label', 'Expand Topic List')
  })
  it('collapse-toggle-004 aria-label "Collapse Topic List" when expanded', () => {
    expect(setup({ collapsed: false }).el).toHaveAttribute('aria-label', 'Collapse Topic List')
  })
  it('collapse-toggle-005 aria-expanded false when collapsed', () => {
    expect(setup({ collapsed: true }).el).toHaveAttribute('aria-expanded', 'false')
  })
  it('collapse-toggle-006 aria-expanded true when expanded', () => {
    expect(setup({ collapsed: false }).el).toHaveAttribute('aria-expanded', 'true')
  })
  it('collapse-toggle-007 title "Expand Items" when collapsed', () => {
    expect(setup({ collapsed: true, label: 'Items' }).el).toHaveAttribute('title', 'Expand Items')
  })
  it('collapse-toggle-008 type="button"', () => {
    expect(setup().el).toHaveAttribute('type', 'button')
  })
  it('collapse-toggle-009 click invokes onToggle with the click event', () => {
    const { el, onToggle } = setup()
    fireEvent.click(el)
    expect(onToggle).toHaveBeenCalledTimes(1)
    expect(onToggle.mock.calls[0]![0].type).toBe('click')
  })
  it('collapse-toggle-010 Ctrl+click forwards ctrlKey=true', () => {
    const { el, onToggle } = setup()
    fireEvent.click(el, { ctrlKey: true })
    expect(onToggle.mock.calls[0]![0].ctrlKey).toBe(true)
  })
  it('collapse-toggle-011 aria-controls forwarded', () => {
    expect(setup({ controls: 'item-list' }).el).toHaveAttribute('aria-controls', 'item-list')
  })
  it('collapse-toggle-012 aria-controls absent when not provided', () => {
    expect(setup().el).not.toHaveAttribute('aria-controls')
  })
  it('collapse-toggle-013 custom className merged', () => {
    expect(setup({ className: 'custom-class' }).el).toHaveClass('custom-class')
  })
  it.skip('collapse-toggle-014 Enter/Space key activation fires click (jsdom does not synthesize click from key events; native browser behavior)', () => {})
  it('collapse-toggle-015 Meta+click forwards metaKey=true', () => {
    const { el, onToggle } = setup()
    fireEvent.click(el, { metaKey: true })
    expect(onToggle.mock.calls[0]![0].metaKey).toBe(true)
  })
  it('collapse-toggle-016 px-3 overrides default px-1', () => {
    const { el } = setup({ className: 'px-3' })
    expect(el).toHaveClass('px-3')
    expect(el).not.toHaveClass('px-1')
  })
  it('collapse-toggle-017 title "Collapse Items" when expanded', () => {
    expect(setup({ collapsed: false, label: 'Items' }).el).toHaveAttribute('title', 'Collapse Items')
  })
  it('collapse-toggle-018 empty label gives "Expand " name and title, glyph renders, onToggle fires', () => {
    const { el, onToggle } = setup({ collapsed: true, label: '' })
    expect(el).toHaveAttribute('aria-label', 'Expand ')
    expect(el).toHaveAttribute('title', 'Expand ')
    expect(el).toHaveTextContent('»')
    fireEvent.click(el)
    expect(onToggle).toHaveBeenCalledTimes(1)
  })
})
