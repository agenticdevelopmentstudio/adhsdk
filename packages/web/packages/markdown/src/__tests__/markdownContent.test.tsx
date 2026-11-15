// @vitest-environment jsdom
//
// MarkdownContent — conformance vectors markdown-001 to 016. It is an async server component, so
// each test awaits the component function and renders the element it returns.
/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, cleanup } from '@testing-library/react'

import { MarkdownContent } from '../components/MarkdownContent'
import type { MarkdownContentProps } from '../components/MarkdownContent'

afterEach(cleanup)

async function root(props: MarkdownContentProps): Promise<HTMLElement> {
  const { container } = render(await MarkdownContent(props))
  return container.firstElementChild as HTMLElement
}

/** innerHTML without the id and anchor wrapper rehype-slug / rehype-autolink-headings add to headings. */
function normalised(el: HTMLElement): string {
  const copy = el.cloneNode(true) as HTMLElement
  copy.querySelectorAll('h1 > a, h2 > a, h3 > a').forEach((a) => a.replaceWith(...a.childNodes))
  copy.querySelectorAll('[id]').forEach((n) => n.removeAttribute('id'))
  return copy.innerHTML.replace(/>\s+</g, '><').trim()
}

describe('MarkdownContent', () => {
  it('markdown-001: renders headings and paragraphs inside the adh-mv-prose root', async () => {
    const el = await root({ content: '# Hello\n\nWorld' })
    expect(el.tagName).toBe('DIV')
    expect(el.className).toBe('adh-mv-prose')
    expect(el.querySelector('h1')?.textContent).toBe('Hello')
    expect(el.querySelector('p')?.textContent).toBe('World')
  })

  it('markdown-002: appends className to the root class list', async () => {
    const el = await root({ content: 'text', className: 'custom-override' })
    expect(el.getAttribute('class')).toBe('adh-mv-prose custom-override')
  })

  it('markdown-003: strips leading frontmatter', async () => {
    const el = await root({ content: '---\nfrontmatter: value\n---\n# Title' })
    expect(normalised(el)).toBe('<h1>Title</h1>')
    expect(el.innerHTML).not.toContain('frontmatter')
  })

  it('markdown-004: script tags and event handlers do not reach the output', async () => {
    const el = await root({ content: "<script>alert('xss')</script>" })
    expect(el.innerHTML).not.toContain('<script')
    for (const node of el.querySelectorAll('*')) {
      expect([...node.attributes].some((a) => a.name.startsWith('on'))).toBe(false)
    }
  })

  it('markdown-005: highlights fenced code into pre.shiki with token spans', async () => {
    const el = await root({ content: '```ts\nconst x = 1\n```' })
    const pre = el.querySelector('pre.shiki')!
    expect(pre).not.toBeNull()
    expect(pre.querySelectorAll('code span').length).toBeGreaterThan(1)
    expect(pre.textContent).toContain('const x = 1')
  })

  it('markdown-006: a --- after a blank line is a thematic break, not frontmatter', async () => {
    const el = await root({ content: '# Title\n\n---\n\nMore text' })
    expect([...el.children].map((c) => c.tagName)).toEqual(['H1', 'HR', 'P'])
  })

  it('markdown-007: whitespace-only content renders an empty root', async () => {
    const el = await root({ content: '   \n\n  ' })
    expect(el.className).toBe('adh-mv-prose')
    expect(el.innerHTML.trim()).toBe('')
  })

  it('markdown-008: empty content renders an empty root', async () => {
    const el = await root({ content: '' })
    expect(el.className).toBe('adh-mv-prose')
    expect(el.innerHTML.trim()).toBe('')
  })

  it('markdown-009: with no className the class is exactly adh-mv-prose', async () => {
    const el = await root({ content: 'text' })
    expect(el.getAttribute('class')).toBe('adh-mv-prose')
  })

  it('markdown-010: renders a nested list, a table, highlighted code and a link', async () => {
    const content = '- a\n  - b\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n```js\nconst y = 2\n```\n\n[link](https://example.com)'
    const el = await root({ content })
    expect(el.querySelector('ul ul')).not.toBeNull()
    expect(el.querySelector('table')).not.toBeNull()
    expect(el.querySelectorAll('pre.shiki code span').length).toBeGreaterThan(1)
    expect(el.querySelector('a[href="https://example.com"]')).not.toBeNull()
  })

  it('markdown-011: a NOTE blockquote becomes an adh-mv-alert', async () => {
    const el = await root({ content: '> [!NOTE]\n> Body text' })
    const alert = el.querySelector('div.adh-mv-alert.adh-mv-alert--note')!
    expect(alert).not.toBeNull()
    const [title, body] = alert.querySelectorAll('p')
    expect(title).toHaveClass('adh-mv-alert-title')
    expect(title!.textContent).toBe('Note')
    expect(body!.textContent).toBe('Body text')
    expect(el.textContent).not.toContain('[!NOTE]')
  })

  it('markdown-012: a leading --- with no closing line is a thematic break; nothing is dropped', async () => {
    const el = await root({ content: '---\n\nIntro paragraph.\n\nMore text' })
    expect([...el.children].map((c) => c.tagName)).toEqual(['HR', 'P', 'P'])
    expect([...el.querySelectorAll('p')].map((p) => p.textContent)).toEqual(['Intro paragraph.', 'More text'])
  })

  it('markdown-013: a closed but malformed frontmatter block is stripped without throwing', async () => {
    const el = await root({ content: '---\ntitle: [unclosed\n---\n# Body' })
    expect(normalised(el)).toBe('<h1>Body</h1>')
  })

  it('markdown-014: javascript: links, onerror and img tags are removed', async () => {
    const el = await root({ content: '[x](javascript:alert(1)) and <img src=x onerror=alert(1)>' })
    expect(el.innerHTML).not.toContain('javascript:')
    expect(el.innerHTML).not.toContain('onerror')
    expect(el.innerHTML).not.toContain('<img')
    expect(el.textContent).toContain('x')
    expect(el.querySelector('a[href]')).toBeNull()
  })

  it('markdown-015: a highlighter failure rejects with that error and returns no HTML', async () => {
    vi.resetModules()
    vi.doMock('shiki', () => ({ createHighlighter: () => Promise.reject(new Error('boom')) }))
    try {
      const { MarkdownContent: Fresh } = await import('../components/MarkdownContent')
      await expect(Fresh({ content: 'text' })).rejects.toThrow('boom')
    } finally {
      vi.doUnmock('shiki')
      vi.resetModules()
    }
  })

  it('markdown-016: measure fill adds adh-mv-prose--fill before the caller class', async () => {
    const el = await root({ content: 'text', measure: 'fill', className: 'custom-override' })
    expect(el.getAttribute('class')).toBe('adh-mv-prose adh-mv-prose--fill custom-override')
    const plain = await root({ content: 'text' })
    expect(plain.getAttribute('class')).toBe('adh-mv-prose')
  })
})
