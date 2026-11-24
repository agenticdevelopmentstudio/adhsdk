// @vitest-environment jsdom
//
// MarkdownDocumentPane — a whole detail pane for one document: the shared Cancel/Save bar
// flush at the top, and the Source / Preview view in the padded body below it.
//
// The editor is mocked to a stand-in that reports what it was given; its own behaviour is
// covered by markdownDocumentEditor.test.tsx. What is under test here is the pane's layout:
// where the bar sits, when it shows, and what goes in the padded body.
/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'

const editorProps = vi.hoisted(() => ({ last: null as Record<string, unknown> | null }))

vi.mock('../components/MarkdownDocumentEditor', () => ({
  MarkdownDocumentEditor: (props: { value: string; readOnly?: boolean }) => {
    editorProps.last = props as unknown as Record<string, unknown>
    return <div data-testid="editor" data-readonly={String(!!props.readOnly)}>{props.value}</div>
  },
}))

import { MarkdownDocumentPane, MarkdownDocumentPaneBody } from '../components/MarkdownDocumentPane'
import type { MarkdownDocumentPaneProps } from '../components/MarkdownDocumentPane'

afterEach(cleanup)

function doc(over: Partial<MarkdownDocumentPaneProps['document']> = {}): MarkdownDocumentPaneProps['document'] {
  return {
    value: '# Hello',
    edit: () => {},
    dirty: false,
    saving: false,
    gone: false,
    changedElsewhere: false,
    conflict: null,
    saveError: null,
    save: async () => {},
    overwrite: async () => {},
    revert: () => {},
    takeTheirs: () => {},
    ...over,
  } as MarkdownDocumentPaneProps['document']
}

const pane = (container: HTMLElement) => container.querySelector('[data-slot="markdown-document-pane"]')!

describe('MarkdownDocumentPane', () => {
  it('pane-001: puts the Cancel/Save bar first, flush, outside the padded body', () => {
    const { container } = render(<MarkdownDocumentPane document={doc()} editable />)
    const bar = screen.getByRole('toolbar', { name: 'Editing actions' })
    expect(pane(container).firstElementChild).toContainElement(bar)
    const body = container.querySelector('[data-slot="markdown-document-pane-body"]')!
    expect(body).not.toContainElement(bar)
    expect(body.className).toContain('p-4')
    expect(screen.getByTestId('editor')).toHaveAttribute('data-readonly', 'false')
  })

  it('pane-002: shows a read-only document without the bar', () => {
    render(<MarkdownDocumentPane document={doc()} editable={false} />)
    expect(screen.queryByRole('toolbar', { name: 'Editing actions' })).toBeNull()
    expect(screen.getByTestId('editor')).toHaveAttribute('data-readonly', 'true')
  })

  it('pane-003: keeps the bar while a draft is pending after the document stops being editable', () => {
    render(<MarkdownDocumentPane document={doc({ dirty: true })} editable={false} />)
    expect(screen.getByRole('toolbar', { name: 'Editing actions' })).toBeInTheDocument()
  })

  it("pane-004: renders the host's own content in the body, above the editor", () => {
    const { container } = render(
      <MarkdownDocumentPane document={doc()} editable>
        <p>host actions</p>
      </MarkdownDocumentPane>,
    )
    const body = container.querySelector('[data-slot="markdown-document-pane-body"]')!
    expect(body.firstElementChild).toHaveTextContent('host actions')
    expect(body).toContainElement(screen.getByTestId('editor'))
  })

  it('pane-005: leaves the body empty until the document loads', () => {
    render(<MarkdownDocumentPane document={doc({ value: null })} editable={false} />)
    expect(screen.queryByTestId('editor')).toBeNull()
  })

  it('pane-006: keeps the bar while a conflict is pending after the document stops being editable', () => {
    render(<MarkdownDocumentPane document={doc({ conflict: { theirs: 'x' } as never })} editable={false} />)
    expect(screen.getByRole('toolbar', { name: 'Editing actions' })).toBeInTheDocument()
  })

  it('pane-007: hides the bar for a clean, conflict-free, non-editable document', () => {
    render(<MarkdownDocumentPane document={doc({ dirty: false, conflict: null })} editable={false} />)
    expect(screen.queryByRole('toolbar', { name: 'Editing actions' })).toBeNull()
  })

  it('pane-008: gives the editor the document value and its edit function as onChange', () => {
    const edit = vi.fn()
    render(<MarkdownDocumentPane document={doc({ value: '# Hello', edit })} editable />)
    expect(screen.getByTestId('editor')).toHaveTextContent('# Hello')
    expect(editorProps.last?.value).toBe('# Hello')
    expect(editorProps.last?.onChange).toBe(edit)
  })

  it('pane-009: forwards unconsumed props to the editor unchanged', () => {
    const extra = { defaultLayout: 'split' } as unknown as Partial<MarkdownDocumentPaneProps>
    render(<MarkdownDocumentPane document={doc()} editable {...extra} />)
    expect(editorProps.last?.defaultLayout).toBe('split')
    expect(editorProps.last).not.toHaveProperty('noun')
    expect(editorProps.last).not.toHaveProperty('messages')
    expect(editorProps.last).not.toHaveProperty('document')
  })

  it('pane-010: MarkdownDocumentPaneBody wraps its child in the body slot with no bar or editor', () => {
    const { container } = render(
      <MarkdownDocumentPaneBody>
        <p>loading</p>
      </MarkdownDocumentPaneBody>,
    )
    const body = container.querySelector('[data-slot="markdown-document-pane-body"]')!
    expect(body).toHaveTextContent('loading')
    expect(body.className).toContain('p-4')
    expect(body.className).toContain('gap-3')
    expect(screen.queryByRole('toolbar', { name: 'Editing actions' })).toBeNull()
    expect(screen.queryByTestId('editor')).toBeNull()
  })

  it('pane-011: the bar notices use "document" by default, then the noun, and messages override the wording', () => {
    const gone = doc({ gone: true })
    const first = render(<MarkdownDocumentPane document={gone} editable />)
    expect(screen.getByText('This document no longer exists.')).toBeInTheDocument()
    first.unmount()

    const second = render(<MarkdownDocumentPane document={gone} editable noun="note" />)
    expect(screen.getByText('This note no longer exists.')).toBeInTheDocument()
    second.unmount()

    render(<MarkdownDocumentPane document={gone} editable noun="note" messages={{ gone: 'It vanished.' }} />)
    expect(screen.getByText('It vanished.')).toBeInTheDocument()
    expect(screen.queryByText('This note no longer exists.')).toBeNull()
  })
})
