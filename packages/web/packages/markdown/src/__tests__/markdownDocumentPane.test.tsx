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

vi.mock('../components/MarkdownDocumentEditor', () => ({
  MarkdownDocumentEditor: ({ value, readOnly }: { value: string; readOnly?: boolean }) => (
    <div data-testid="editor" data-readonly={String(!!readOnly)}>{value}</div>
  ),
}))

import { MarkdownDocumentPane } from '../components/MarkdownDocumentPane'
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
  it('puts the Cancel/Save bar first, flush, outside the padded body', () => {
    const { container } = render(<MarkdownDocumentPane document={doc()} editable />)
    const bar = screen.getByRole('toolbar', { name: 'Editing actions' })
    expect(pane(container).firstElementChild).toContainElement(bar)
    const body = container.querySelector('[data-slot="markdown-document-pane-body"]')!
    expect(body).not.toContainElement(bar)
    expect(body.className).toContain('p-4')
    expect(screen.getByTestId('editor')).toHaveAttribute('data-readonly', 'false')
  })

  it('shows a read-only document without the bar', () => {
    render(<MarkdownDocumentPane document={doc()} editable={false} />)
    expect(screen.queryByRole('toolbar', { name: 'Editing actions' })).toBeNull()
    expect(screen.getByTestId('editor')).toHaveAttribute('data-readonly', 'true')
  })

  it('keeps the bar while a draft is pending after the document stops being editable', () => {
    render(<MarkdownDocumentPane document={doc({ dirty: true })} editable={false} />)
    expect(screen.getByRole('toolbar', { name: 'Editing actions' })).toBeInTheDocument()
  })

  it("renders the host's own content in the body, above the editor", () => {
    const { container } = render(
      <MarkdownDocumentPane document={doc()} editable>
        <p>host actions</p>
      </MarkdownDocumentPane>,
    )
    const body = container.querySelector('[data-slot="markdown-document-pane-body"]')!
    expect(body.firstElementChild).toHaveTextContent('host actions')
    expect(body).toContainElement(screen.getByTestId('editor'))
  })

  it('leaves the body empty until the document loads', () => {
    render(<MarkdownDocumentPane document={doc({ value: null })} editable={false} />)
    expect(screen.queryByTestId('editor')).toBeNull()
  })
})
