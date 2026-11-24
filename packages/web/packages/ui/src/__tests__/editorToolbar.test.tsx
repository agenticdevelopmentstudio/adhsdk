import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { EditorToolbar } from '../components/editor-toolbar'

describe('EditorToolbar', () => {
  it('editor-toolbar-001 renders role="toolbar"', () => {
    render(<EditorToolbar>x</EditorToolbar>)
    expect(screen.getByRole('toolbar').tagName).toBe('DIV')
  })
  it('editor-toolbar-002 default aria-label', () => {
    render(<EditorToolbar>x</EditorToolbar>)
    expect(screen.getByRole('toolbar').getAttribute('aria-label')).toBe('Editor toolbar')
  })
  it('editor-toolbar-003 ariaLabel prop', () => {
    render(<EditorToolbar ariaLabel="Custom toolbar">x</EditorToolbar>)
    expect(screen.getByRole('toolbar').getAttribute('aria-label')).toBe('Custom toolbar')
  })
  it('editor-toolbar-004 renders children', () => {
    render(<EditorToolbar><button>Bold</button></EditorToolbar>)
    expect(screen.getByRole('toolbar').contains(screen.getByRole('button', { name: 'Bold' }))).toBe(true)
  })
  it('editor-toolbar-005 merges className with defaults', () => {
    render(<EditorToolbar className="custom-class">x</EditorToolbar>)
    const cls = screen.getByRole('toolbar').className
    expect(cls).toContain('custom-class')
    expect(cls).toContain('flex')
    expect(cls).toContain('items-center')
  })
  it.skip('editor-toolbar-006 display is flex (jsdom loads no Tailwind stylesheet, so computed style is empty)', () => {})
  it.skip('editor-toolbar-007 align-items is center (jsdom loads no Tailwind stylesheet, so computed style is empty)', () => {})
  it.skip('editor-toolbar-008 column-gap is 0.375rem (jsdom loads no Tailwind stylesheet, so computed style is empty)', () => {})
  it.skip('editor-toolbar-009 vertical centers match (needs real browser layout)', () => {})
  it.skip('editor-toolbar-010 child gap is 0.375rem (needs real browser layout)', () => {})
  it.skip('editor-toolbar-011 gap-4 override (needs real browser layout)', () => {})
  it('editor-toolbar-012 empty ariaLabel is kept', () => {
    render(<EditorToolbar ariaLabel="">x</EditorToolbar>)
    expect(screen.getByRole('toolbar').getAttribute('aria-label')).toBe('')
  })
})
