// @vitest-environment jsdom
//
// JsonRenderer — conformance vectors json-renderer-001 to 014. The Markdown pipeline is wrapped in a
// spy that still runs the real implementation unless a test overrides it, so the small path shows
// real output and the oversized path can be proven not to touch the pipeline.
/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, cleanup, waitFor } from '@testing-library/react'

vi.mock('../lib/process-markdown', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../lib/process-markdown')>()
  return { ...actual, processMarkdown: vi.fn(actual.processMarkdown) }
})

import { JsonRenderer, JSON_HIGHLIGHT_LIMIT } from '../components/JsonRenderer'
import { processMarkdown } from '../lib/process-markdown'

const spy = vi.mocked(processMarkdown)
const NOTE = 'Not valid JSON — shown as written.'

afterEach(() => {
  cleanup()
  spy.mockClear()
})

/** The Markdown source JsonRenderer handed to the pipeline on its last call. */
const lastSource = () => spy.mock.calls[spy.mock.calls.length - 1]![0] as string
const codeText = (container: HTMLElement) => container.querySelector('pre code')?.textContent ?? ''

describe('JsonRenderer', () => {
  it('json-renderer-001: pretty-prints a JSON document, fenced as json, without a note', async () => {
    const { container } = render(<JsonRenderer content={'{"a":1,"b":[true]}'} />)
    await waitFor(() => expect(container.querySelector('pre.shiki')).not.toBeNull())
    expect(lastSource()).toBe('```json\n{\n  "a": 1,\n  "b": [\n    true\n  ]\n}\n```\n')
    expect(codeText(container)).toBe('{\n  "a": 1,\n  "b": [\n    true\n  ]\n}')
    expect(container.textContent).not.toContain(NOTE)
  })

  it('json-renderer-002: pretty-prints each JSON Lines record, skipping blank lines', async () => {
    const { container } = render(<JsonRenderer content={'{"a":1}\n\n{"b":2}\n'} />)
    await waitFor(() => expect(container.querySelector('pre.shiki')).not.toBeNull())
    expect(lastSource()).toBe('```json\n{\n  "a": 1\n}\n{\n  "b": 2\n}\n```\n')
    expect(codeText(container)).toBe('{\n  "a": 1\n}\n{\n  "b": 2\n}')
  })

  it('json-renderer-003: invalid text gets the note and a fence with no language', async () => {
    const { container } = render(<JsonRenderer content="not json" />)
    await waitFor(() => expect(container.querySelector('pre')).not.toBeNull())
    expect(lastSource()).toBe(`*${NOTE}*\n\n\`\`\`\nnot json\n\`\`\`\n`)
    expect(container.textContent).toContain(NOTE)
    expect(codeText(container)).toBe('not json\n')
  })

  it('json-renderer-004: one bad JSON Lines record makes the whole text invalid, shown unchanged', async () => {
    const { container } = render(<JsonRenderer content={'{"a":1}\nnope'} />)
    await waitFor(() => expect(container.querySelector('pre')).not.toBeNull())
    expect(lastSource()).toBe(`*${NOTE}*\n\n\`\`\`\n{"a":1}\nnope\n\`\`\`\n`)
    expect(container.textContent).toContain(NOTE)
    expect(codeText(container)).toBe('{"a":1}\nnope\n')
  })

  it('json-renderer-005: whitespace-only text is invalid, shown unmodified', async () => {
    const { container } = render(<JsonRenderer content="   " />)
    await waitFor(() => expect(container.querySelector('pre')).not.toBeNull())
    expect(lastSource()).toBe(`*${NOTE}*\n\n\`\`\`\n   \n\`\`\`\n`)
    expect(container.textContent).toContain(NOTE)
  })

  it('json-renderer-006: the fence is longer than any backtick run in the body', async () => {
    const { container } = render(<JsonRenderer content={JSON.stringify({ s: 'a ```` b' })} />)
    await waitFor(() => expect(container.querySelector('pre.shiki')).not.toBeNull())
    const src = lastSource()
    expect(src.startsWith('`````json\n')).toBe(true)
    expect(src.endsWith('\n`````\n')).toBe(true)
    expect(codeText(container)).toContain('a ```` b')
  })

  it('json-renderer-007: a single unterminated line is invalid, not JSON Lines', async () => {
    const { container } = render(<JsonRenderer content={'{"a":1'} />)
    await waitFor(() => expect(container.querySelector('pre')).not.toBeNull())
    expect(lastSource()).toBe(`*${NOTE}*\n\n\`\`\`\n{"a":1\n\`\`\`\n`)
    expect(container.textContent).toContain(NOTE)
  })

  it('json-renderer-008: a body of exactly the limit still goes through the Markdown pipeline', async () => {
    const body = JSON.stringify('x'.repeat(JSON_HIGHLIGHT_LIMIT - 2))
    expect(body.length).toBe(524288)
    spy.mockResolvedValueOnce({ html: '<p data-testid="pipeline">stub</p>' } as Awaited<ReturnType<typeof processMarkdown>>)
    const { container } = render(<JsonRenderer content={body} />)
    expect(await screen.findByTestId('pipeline')).toBeInTheDocument()
    expect(spy).toHaveBeenCalledTimes(1)
    expect(lastSource().startsWith('```json\n')).toBe(true)
    expect(container.querySelector('pre.shiki')).toBeNull()
  })

  it('json-renderer-009: a body over the limit renders a plain pre.shiki > code, no pipeline, no note', () => {
    const body = JSON.stringify('x'.repeat(JSON_HIGHLIGHT_LIMIT - 1))
    expect(body.length).toBe(524289)
    const { container } = render(<JsonRenderer content={body} />)
    const root = container.firstElementChild as HTMLElement
    expect(root.tagName).toBe('DIV')
    expect(root.className).toBe('adh-mv-prose')
    expect(root.querySelector('pre.shiki > code')?.textContent).toBe(body)
    expect(container.querySelector('.adh-mv-json-note')).toBeNull()
    expect(container.textContent).not.toContain(NOTE)
    expect(spy).not.toHaveBeenCalled()
  })

  it('json-renderer-010: oversized invalid text shows the note paragraph, then the text unmodified', () => {
    const text = 'z'.repeat(JSON_HIGHLIGHT_LIMIT + 1)
    const { container } = render(<JsonRenderer content={text} />)
    const note = container.querySelector('p.adh-mv-json-note')!
    expect(note).toHaveTextContent(NOTE)
    expect(note.nextElementSibling?.tagName).toBe('PRE')
    expect(container.querySelector('pre.shiki > code')?.textContent).toBe(text)
    expect(spy).not.toHaveBeenCalled()
  })

  it('json-renderer-011: the limit measures the pretty-printed text, not the raw input', () => {
    const compact = JSON.stringify(Array.from({ length: 120000 }, () => 1)) // 240k chars, one line
    expect(compact.length).toBeLessThan(JSON_HIGHLIGHT_LIMIT)
    const { container } = render(<JsonRenderer content={compact} />)
    const shown = container.querySelector('pre.shiki > code')?.textContent ?? ''
    expect(shown.length).toBeGreaterThan(JSON_HIGHLIGHT_LIMIT)
    expect(shown.startsWith('[\n  1,\n  1,')).toBe(true)
    expect(spy).not.toHaveBeenCalled()
  })

  it('json-renderer-012: wrap reaches MarkdownRenderer on the small path and the root on the plain path', async () => {
    const small = render(<JsonRenderer content={'{"a":1}'} wrap />)
    await waitFor(() => expect(small.container.querySelector('pre.shiki')).not.toBeNull())
    expect(small.container.firstElementChild).toHaveClass('adh-mv-prose', 'adh-mv-prose--wrap')
    small.unmount()

    const big = render(<JsonRenderer content={JSON.stringify('x'.repeat(JSON_HIGHLIGHT_LIMIT))} wrap />)
    expect(big.container.firstElementChild).toHaveClass('adh-mv-prose', 'adh-mv-prose--wrap')
  })

  it('json-renderer-013: with wrap omitted the oversized root is exactly adh-mv-prose', () => {
    const { container } = render(<JsonRenderer content={JSON.stringify('x'.repeat(JSON_HIGHLIGHT_LIMIT))} />)
    expect((container.firstElementChild as HTMLElement).className).toBe('adh-mv-prose')
  })

  it("json-renderer-014: a Markdown pipeline failure shows MarkdownRenderer's error pane, nothing added", async () => {
    const err = vi.spyOn(console, 'error').mockImplementation(() => {})
    spy.mockRejectedValueOnce(new Error('boom'))
    const { container } = render(<JsonRenderer content={'{"a":1}'} />)
    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent('Failed to render document')
    expect(container.querySelector('.adh-mv-json-note')).toBeNull()
    expect(container.querySelector('pre')).toBeNull()
    err.mockRestore()
  })
})
