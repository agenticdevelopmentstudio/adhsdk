// @vitest-environment jsdom
// MarkdownReadingPalette — conformance vectors palette-001..011.
/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, it, expect, afterEach } from 'vitest'
import { render, cleanup } from '@testing-library/react'
import { renderToString } from 'react-dom/server'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { MarkdownReadingPalette } from '../components/MarkdownReadingPalette'
import { DEFAULT_THEME_ID, getThemeById } from '../themes/registry'

afterEach(cleanup)

function root(container: HTMLElement): HTMLElement {
  return container.firstElementChild as HTMLElement
}

describe('MarkdownReadingPalette', () => {
  it('palette-001 renders children unchanged', () => {
    const { container } = render(<MarkdownReadingPalette><div>Hello</div></MarkdownReadingPalette>)
    expect(root(container).innerHTML).toBe('<div>Hello</div>')
  })

  it('palette-002 sets the theme and shiki variant data attributes', () => {
    const { container } = render(<MarkdownReadingPalette themeId="dark">x</MarkdownReadingPalette>)
    expect(root(container)).toHaveAttribute('data-mdv-theme', 'dark')
    expect(root(container)).toHaveAttribute('data-mdv-shiki-variant', 'dark')
  })

  it('palette-003 applies the theme palette as inline style', () => {
    const { container } = render(<MarkdownReadingPalette themeId="dark">x</MarkdownReadingPalette>)
    const el = root(container)
    expect(el.style.getPropertyValue('--mdv-bg')).toBe('#0c0c0f')
    expect(el.style.getPropertyValue('--mdv-text')).toBe('#e8e6e3')
  })

  it('palette-004 has the adh-mv-content class by default', () => {
    const { container } = render(<MarkdownReadingPalette>x</MarkdownReadingPalette>)
    expect(root(container).classList.contains('adh-mv-content')).toBe(true)
  })

  it('palette-005 merges className with adh-mv-content', () => {
    const { container } = render(<MarkdownReadingPalette className="border rounded">x</MarkdownReadingPalette>)
    const el = root(container)
    expect(el).toHaveClass('adh-mv-content', 'border', 'rounded')
  })

  it('palette-006 forwards themeId and data-slot', () => {
    const { container } = render(
      <MarkdownReadingPalette themeId="light" data-slot="markdown-preview">x</MarkdownReadingPalette>,
    )
    expect(root(container)).toHaveAttribute('data-mdv-theme', 'light')
    expect(root(container)).toHaveAttribute('data-slot', 'markdown-preview')
  })

  it('palette-007 defaults to DEFAULT_THEME_ID', () => {
    const { container } = render(<MarkdownReadingPalette>x</MarkdownReadingPalette>)
    expect(DEFAULT_THEME_ID).toBe('dark')
    expect(root(container)).toHaveAttribute('data-mdv-theme', DEFAULT_THEME_ID)
  })

  it('palette-008 renders on the server and the source is server-safe', () => {
    const html = renderToString(<MarkdownReadingPalette><div>Hi</div></MarkdownReadingPalette>)
    expect(html).toContain('<div>Hi</div>')
    const src = readFileSync(resolve(__dirname, '../components/MarkdownReadingPalette.tsx'), 'utf8')
    expect(src).not.toMatch(/^\s*['"]use client['"]/m)
    expect(src).not.toMatch(/import\s*\{[^}]*\buse[A-Z]\w*[^}]*\}\s*from\s*['"]react['"]/)
  })

  it('palette-009 renders the wrapper with the theme and no child content for null children', () => {
    const { container } = render(<MarkdownReadingPalette>{null}</MarkdownReadingPalette>)
    const el = root(container)
    expect(el).toHaveAttribute('data-mdv-theme', 'dark')
    expect(el.style.getPropertyValue('--mdv-bg')).toBe('#0c0c0f')
    expect(el.childNodes.length).toBe(0)
  })

  it('palette-010 falls back to the default theme for an unknown id', () => {
    expect(() => getThemeById('not-a-real-theme')).not.toThrow()
    const { container } = render(<MarkdownReadingPalette themeId="not-a-real-theme">x</MarkdownReadingPalette>)
    const el = root(container)
    expect(el).toHaveAttribute('data-mdv-theme', 'dark')
    expect(el.style.getPropertyValue('--mdv-bg')).toBe(getThemeById('dark').palette['--mdv-bg'])
  })

  it('palette-011 whitespace-only className adds nothing', () => {
    const { container } = render(<MarkdownReadingPalette className="   ">x</MarkdownReadingPalette>)
    expect(root(container).getAttribute('class')).toBe('adh-mv-content')
  })
})
