/**
 * `CoverAllControl` conformance vectors ca-001 .. ca-012, rendered on their own.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, cleanup, fireEvent } from '@testing-library/react'
import { describe, it, expect, afterEach, vi } from 'vitest'
import { CoverAllControl } from '../blocks/cover-all-control'

type Flags = { canCollapse: boolean; canExpand: boolean }

function setup(flags: Flags = { canCollapse: true, canExpand: true }) {
  const onCollapseAll = vi.fn()
  const onExpandAll = vi.fn()
  const utils = render(
    <CoverAllControl {...flags} onCollapseAll={onCollapseAll} onExpandAll={onExpandAll} />,
  )
  return { onCollapseAll, onExpandAll, ...utils }
}

const collapse = (): HTMLElement => screen.getByRole('button', { name: 'Collapse all lists' })
const expand = (): HTMLElement => screen.getByRole('button', { name: 'Expand all lists' })

afterEach(cleanup)

describe('CoverAllControl conformance vectors', () => {
  it('ca-001: clicking Collapse all lists calls onCollapseAll once with no arguments', () => {
    const { onCollapseAll, onExpandAll } = setup()
    fireEvent.click(collapse())
    expect(onCollapseAll).toHaveBeenCalledTimes(1)
    expect(onExpandAll).not.toHaveBeenCalled()
  })

  it('ca-002: clicking Expand all lists calls onExpandAll once', () => {
    const { onCollapseAll, onExpandAll } = setup()
    fireEvent.click(expand())
    expect(onExpandAll).toHaveBeenCalledTimes(1)
    expect(onCollapseAll).not.toHaveBeenCalled()
  })

  it('ca-003: canCollapse=false, canExpand=true disables only the collapse button', () => {
    setup({ canCollapse: false, canExpand: true })
    expect(collapse()).toBeDisabled()
    expect(expand()).toBeEnabled()
  })

  it('ca-004: canCollapse=true, canExpand=false disables only the expand button', () => {
    setup({ canCollapse: true, canExpand: false })
    expect(collapse()).toBeEnabled()
    expect(expand()).toBeDisabled()
  })

  it('ca-005: a disabled collapse button does not call onCollapseAll', () => {
    const { onCollapseAll } = setup({ canCollapse: false, canExpand: true })
    fireEvent.click(collapse())
    expect(onCollapseAll).not.toHaveBeenCalled()
  })

  it('ca-006: both buttons stay rendered, both disabled, when both flags are false', () => {
    setup({ canCollapse: false, canExpand: false })
    expect(collapse()).toBeDisabled()
    expect(expand()).toBeDisabled()
  })

  it('ca-007: the frame is a named group carrying data-htd-cover-all', () => {
    const { container } = setup()
    const group = screen.getByRole('group', { name: 'Collapse or expand all lists' })
    expect(group).toHaveAttribute('data-htd-cover-all')
    expect(container.querySelector('[data-htd-cover-all]')).toBe(group)
  })

  it('ca-008: each button title equals its accessible name', () => {
    setup()
    expect(collapse()).toHaveAttribute('title', 'Collapse all lists')
    expect(expand()).toHaveAttribute('title', 'Expand all lists')
  })

  it('ca-009: the chevron wrappers and the divider are aria-hidden', () => {
    setup()
    for (const button of [collapse(), expand()]) {
      const glyph = button.querySelector('span')
      expect(glyph).not.toBeNull()
      expect(glyph).toHaveAttribute('aria-hidden', 'true')
    }
    const group = screen.getByRole('group')
    const divider = Array.from(group.children).find((c) => c.tagName === 'SPAN')
    expect(divider).toHaveAttribute('aria-hidden', 'true')
  })

  it('ca-010: neither button submits a surrounding form', () => {
    const onSubmit = vi.fn((e: { preventDefault: () => void }) => e.preventDefault())
    render(
      <form onSubmit={onSubmit}>
        <CoverAllControl
          canCollapse
          canExpand
          onCollapseAll={() => {}}
          onExpandAll={() => {}}
        />
      </form>,
    )
    expect(collapse()).toHaveAttribute('type', 'button')
    expect(expand()).toHaveAttribute('type', 'button')
    fireEvent.click(collapse())
    fireEvent.click(expand())
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('ca-011: DOM order is collapse button, divider, expand button', () => {
    setup()
    const group = screen.getByRole('group')
    const kids = Array.from(group.children)
    expect(kids).toHaveLength(3)
    expect(kids[0]).toBe(collapse())
    expect(kids[1]!.getAttribute('aria-hidden')).toBe('true')
    expect(kids[2]).toBe(expand())
  })

  it('ca-012: rerendering with new flags updates the enabled states immediately', () => {
    const onCollapseAll = vi.fn()
    const onExpandAll = vi.fn()
    const { rerender } = render(
      <CoverAllControl
        canCollapse
        canExpand={false}
        onCollapseAll={onCollapseAll}
        onExpandAll={onExpandAll}
      />,
    )
    expect(collapse()).toBeEnabled()
    expect(expand()).toBeDisabled()
    rerender(
      <CoverAllControl
        canCollapse={false}
        canExpand
        onCollapseAll={onCollapseAll}
        onExpandAll={onExpandAll}
      />,
    )
    expect(collapse()).toBeDisabled()
    expect(expand()).toBeEnabled()
  })
})
