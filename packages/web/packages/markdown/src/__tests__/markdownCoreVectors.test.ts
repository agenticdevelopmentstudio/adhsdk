// Conformance vectors for markdown/core that have no dedicated suite elsewhere in this
// package. The vectors that DO have one carry their id in that suite's test titles.
import { describe, it, expect, vi } from 'vitest'
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'
import { processMarkdown } from '../lib/process-markdown'
import { deriveDocumentTitle, setFrontmatterTitle, splitFrontmatter } from '../lib/document-title'

describe('markdown/core pipeline', () => {
  it('mdc-039: alerts become callout divs and a script tag is gone, in one pass', async () => {
    const { html } = await processMarkdown('> [!NOTE]\n> hi\n\n<script>x</script>')
    expect(html).toContain('<div class="adh-mv-alert adh-mv-alert--note"')
    expect(html).not.toContain('<script')
  })

  it('mdc-041: the shiki highlighter is created once across sequential calls', async () => {
    vi.resetModules()
    const createHighlighter = vi.fn()
    vi.doMock('shiki', async () => {
      const actual = await vi.importActual<typeof import('shiki')>('shiki')
      createHighlighter.mockImplementation(actual.createHighlighter)
      return { ...actual, createHighlighter }
    })
    try {
      const fresh = await import('../lib/process-markdown')
      await fresh.processMarkdown('```ts\nconst a = 1\n```')
      await fresh.processMarkdown('```ts\nconst b = 2\n```')
      expect(createHighlighter).toHaveBeenCalledTimes(1)
    } finally {
      vi.doUnmock('shiki')
      vi.resetModules()
    }
  })

  it('mdc-042: javascript: and data: URLs never reach the HTML', async () => {
    const { html } = await processMarkdown('[x](javascript:alert(1)) ![i](data:image/png;base64,AAAA)')
    expect(html).not.toContain('javascript:')
    expect(html).not.toContain('data:')
  })

  it('mdc-043: a nested alert is a callout while its outer quote stays a blockquote', async () => {
    const { html } = await processMarkdown('> quote\n>\n> > [!TIP]\n> > nested')
    expect(html).toMatch(/^<blockquote>/)
    expect(html).toContain('<div class="adh-mv-alert adh-mv-alert--tip">')
    expect(html.match(/<blockquote/g)).toHaveLength(1)
  })

  it('mdc-044: the marker is replaced by an injected title paragraph', async () => {
    const { html } = await processMarkdown('> [!WARNING]\n> Careful')
    expect(html).toMatch(
      /<div class="adh-mv-alert adh-mv-alert--warning">\s*<p class="adh-mv-alert-title">Warning<\/p>\s*<p>Careful<\/p>\s*<\/div>/,
    )
    expect(html).not.toContain('[!WARNING]')
  })

  it('mdc-060: malformed frontmatter YAML still renders the body, without the --- lines', async () => {
    const { html } = await processMarkdown('---\ntitle: [unclosed\n---\n# Body')
    expect(html).toMatch(/<h1[^>]*>[\s\S]*Body[\s\S]*<\/h1>/)
    expect(html).not.toContain('---')
  })
})

describe('markdown/core title and frontmatter', () => {
  it('mdc-051: line syntax is stripped once, so "- - a" titles as "- a"', () => {
    expect(deriveDocumentTitle('- - a')).toBe('- a')
  })

  it('mdc-054: the title is cut at 500 UTF-16 units, leaving a lone high surrogate', () => {
    const title = deriveDocumentTitle(`${'a'.repeat(499)}😀`)
    expect(title).toHaveLength(500)
    expect(title.endsWith('\uD83D')).toBe(true)
    expect('ab😀'.slice(0, 3)).toBe('ab\uD83D')
  })

  it('mdc-055: CRLF fences and trailing spaces after the closing --- are accepted', () => {
    const { body, data } = splitFrontmatter('---\r\ntitle: A\r\n---  \r\nbody')
    expect(body).toBe('body')
    expect(data).toEqual({ title: 'A' })
  })

  it('mdc-056: the write path never touches a name line', () => {
    const out = setFrontmatterTitle('---\nname: Old\n---\nbody', 'New')
    expect(out.split('\n')).toContain('name: Old')
    expect(out.split('\n')).toContain('title: "New"')
  })
})

describe('markdown/core palette ownership', () => {
  it('mdc-057: no color literal lives outside themes/palettes.ts', () => {
    const src = join(__dirname, '..')
    const files: string[] = []
    const walk = (dir: string): void => {
      for (const name of readdirSync(dir)) {
        const p = join(dir, name)
        if (statSync(p).isDirectory()) {
          if (name !== '__tests__') walk(p)
        } else if (/\.tsx?$/.test(name)) {
          files.push(p)
        }
      }
    }
    walk(src)
    const literal = /#[0-9a-fA-F]{6}\b|rgba?\(|hsl\(/
    const offenders = files
      .filter((f) => relative(src, f) !== join('themes', 'palettes.ts'))
      .filter((f) => literal.test(readFileSync(f, 'utf8')))
      .map((f) => relative(src, f))
    expect(files.length).toBeGreaterThan(5)
    expect(offenders).toEqual([])
  })
})

// Swift-only vectors: they exercise Apple types (Frontmatter, MarkdownText, MarkdownDocument)
// that have no web counterpart, and jsdom/vitest cannot run Swift.
describe('markdown/core Apple-only vectors', () => {
  it.skip('mdc-049: Frontmatter.value last duplicate key wins (Swift API, no web counterpart)', () => {})
  it.skip('mdc-050: Frontmatter.setting preserves body line endings (Swift API, no web counterpart)', () => {})
  it.skip('mdc-053: MarkdownText.byteLength is UTF-8 (Swift API, no web counterpart)', () => {})
  it.skip('mdc-058: MarkdownDocument value semantics on copy (Swift type, no web counterpart)', () => {})
})
