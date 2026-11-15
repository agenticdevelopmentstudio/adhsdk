/**
 * Unit tests for MarkdownEditor (blocks) — the labelled body textarea + the
 * editor toolbar (built-in upload + quick-reference controls + an extras slot).
 * Uses the real EditorToolbar / MarkdownQuickReference / Popover (base-ui).
 */
import * as React from 'react'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { MarkdownEditor, MarkdownEditorToolbar } from '../blocks/markdown-editor'

function ControlledEditor({
  initial = '',
  ...rest
}: { initial?: string } & Partial<
  Omit<React.ComponentProps<typeof MarkdownEditor>, 'value' | 'onChange'>
> = {}): React.ReactElement {
  const [value, setValue] = React.useState(initial)
  return <MarkdownEditor value={value} onChange={setValue} {...rest} />
}

describe('MarkdownEditor — body textarea', () => {
  it('labels the textarea with the default "Markdown body" caption', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} />)
    const textarea = screen.getByLabelText('Markdown body')
    expect(textarea.tagName).toBe('TEXTAREA')
  })

  it('uses a custom label as the textarea accessible name', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} label="Notes" />)
    expect(screen.getByLabelText('Notes').tagName).toBe('TEXTAREA')
  })

  it('reports the typed value via onChange', () => {
    const onChange = vi.fn()
    render(<MarkdownEditor value="" onChange={onChange} />)
    fireEvent.change(screen.getByLabelText('Markdown body'), {
      target: { value: '# Title' },
    })
    expect(onChange).toHaveBeenCalledWith('# Title')
  })

  it('renders the controlled value and turns spell-check off by default', () => {
    render(<MarkdownEditor value="hello" onChange={vi.fn()} />)
    const textarea = screen.getByLabelText('Markdown body') as HTMLTextAreaElement
    expect(textarea.value).toBe('hello')
    expect(textarea).toHaveAttribute('spellcheck', 'false')
  })

  it('disables the textarea when disabled', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} disabled />)
    expect(screen.getByLabelText('Markdown body')).toBeDisabled()
  })
})

describe('MarkdownEditor — toolbar', () => {
  it('exposes a role="toolbar" with the default accessible name', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} />)
    expect(
      screen.getByRole('toolbar', { name: 'Markdown editor toolbar' }),
    ).toBeInTheDocument()
  })

  it('shows the quick-reference control by default', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} />)
    expect(
      screen.getByRole('button', { name: 'Markdown quick reference' }),
    ).toBeInTheDocument()
  })

  it('omits the quick-reference control when quickReference={false}', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} quickReference={false} />)
    expect(
      screen.queryByRole('button', { name: 'Markdown quick reference' }),
    ).toBeNull()
  })

  it('omits the toolbar entirely when there are no controls', () => {
    render(
      <MarkdownEditor value="" onChange={vi.fn()} quickReference={false} />,
    )
    expect(screen.queryByRole('toolbar')).toBeNull()
  })

  it('renders extra toolbar controls from the slot', () => {
    render(
      <MarkdownEditor
        value=""
        onChange={vi.fn()}
        toolbarExtras={<button type="button">Spell check</button>}
      />,
    )
    expect(screen.getByRole('button', { name: 'Spell check' })).toBeInTheDocument()
  })
})

describe('MarkdownEditor — readOnly', () => {
  it('shows the source selectable but not editable, without the editing aids', () => {
    render(<MarkdownEditor value="# Hi" onChange={vi.fn()} onUpload={vi.fn()} readOnly />)
    const textarea = screen.getByLabelText('Markdown body') as HTMLTextAreaElement
    expect(textarea).toHaveAttribute('readonly')
    expect(textarea).not.toBeDisabled()
    expect(textarea.value).toBe('# Hi')
    expect(screen.queryByRole('button', { name: /Upload \.md/ })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Markdown quick reference' })).toBeNull()
  })
})

describe('MarkdownEditor — chrome="none"', () => {
  it('renders the textarea alone, still named by its label', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} label="Notes" chrome="none" />)
    expect(screen.getByLabelText('Notes').tagName).toBe('TEXTAREA')
    expect(screen.queryByRole('toolbar')).toBeNull()
    expect(screen.getByText('Notes')).toHaveClass('sr-only')
  })
})

describe('MarkdownEditorToolbar', () => {
  it('renders nothing when it has no controls', () => {
    const { container } = render(<MarkdownEditorToolbar quickReference={false} />)
    expect(container).toBeEmptyDOMElement()
  })
})

describe('MarkdownEditor — upload control', () => {
  it('renders the Upload .md control only when onUpload is provided', () => {
    const { rerender } = render(<MarkdownEditor value="" onChange={vi.fn()} />)
    expect(screen.queryByRole('button', { name: /Upload \.md/ })).toBeNull()
    rerender(<MarkdownEditor value="" onChange={vi.fn()} onUpload={vi.fn()} />)
    expect(screen.getByRole('button', { name: /Upload \.md/ })).toBeInTheDocument()
  })

  it('reads a chosen file and reports its text + name via onUpload', async () => {
    const onUpload = vi.fn()
    render(<MarkdownEditor value="" onChange={vi.fn()} onUpload={onUpload} />)
    // The hidden native input is the only way to pick a file; it is sr-only.
    const input = document.querySelector('input[type="file"]') as HTMLInputElement
    const file = new File(['# Hello'], 'notes.md', { type: 'text/markdown' })
    // jsdom's File.text() resolves the contents.
    fireEvent.change(input, { target: { files: [file] } })
    await waitFor(() => expect(onUpload).toHaveBeenCalledWith('# Hello', 'notes.md'))
  })
})

describe('MarkdownEditor — conformance vectors T1-T14', () => {
  const uploadInput = (): HTMLInputElement =>
    document.querySelector('input[type="file"]') as HTMLInputElement

  it('T1 label-textarea: default label "Markdown body" names a TEXTAREA', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} />)
    expect(screen.getByLabelText('Markdown body').tagName).toBe('TEXTAREA')
  })

  it('T2 label-textarea: label="Notes" is the textarea accessible name', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} label="Notes" />)
    expect(screen.getByRole('textbox', { name: 'Notes' }).tagName).toBe('TEXTAREA')
  })

  it('T3 controlled-value: typing "# Title" calls onChange with "# Title"', () => {
    const onChange = vi.fn()
    render(<MarkdownEditor value="" onChange={onChange} />)
    fireEvent.change(screen.getByLabelText('Markdown body'), { target: { value: '# Title' } })
    expect(onChange).toHaveBeenCalledWith('# Title')
  })

  it('T4 default-spellcheck-off: spellcheck="false" by default, enabled on request', () => {
    const { unmount } = render(<MarkdownEditor value="" onChange={vi.fn()} />)
    expect(screen.getByLabelText('Markdown body')).toHaveAttribute('spellcheck', 'false')
    unmount()
    render(<MarkdownEditor value="" onChange={vi.fn()} spellCheck />)
    expect(screen.getByLabelText('Markdown body')).toHaveAttribute('spellcheck', 'true')
  })

  it('T5 show-toolbar-when-controls-exist: default render has the named toolbar', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} />)
    expect(screen.getByRole('toolbar', { name: 'Markdown editor toolbar' })).toBeInTheDocument()
  })

  it('T6 show-toolbar-when-controls-exist, include-quick-reference: quickReference={false} leaves no toolbar and no quick-reference button', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} quickReference={false} />)
    expect(screen.queryByRole('toolbar')).toBeNull()
    expect(screen.queryByRole('button', { name: 'Markdown quick reference' })).toBeNull()
  })

  it('T7 upload-on-demand: Upload .md is absent without onUpload and present with it', () => {
    const { rerender } = render(<MarkdownEditor value="" onChange={vi.fn()} />)
    expect(screen.queryByRole('button', { name: /Upload \.md/ })).toBeNull()
    rerender(<MarkdownEditor value="" onChange={vi.fn()} onUpload={vi.fn()} />)
    expect(screen.getByRole('button', { name: /Upload \.md/ })).toBeInTheDocument()
  })

  it('T8 upload-on-demand, reset-file-input: the same file chosen twice fires onUpload twice', async () => {
    const onUpload = vi.fn()
    render(<MarkdownEditor value="" onChange={vi.fn()} onUpload={onUpload} />)
    const input = uploadInput()
    const file = new File(['# Hello'], 'notes.md', { type: 'text/markdown' })
    fireEvent.change(input, { target: { files: [file] } })
    await waitFor(() => expect(onUpload).toHaveBeenCalledTimes(1))
    // the control cleared the native input after the first selection
    expect(input.value).toBe('')
    fireEvent.change(input, { target: { files: [file] } })
    await waitFor(() => expect(onUpload).toHaveBeenCalledTimes(2))
    expect(onUpload).toHaveBeenNthCalledWith(1, '# Hello', 'notes.md')
    expect(onUpload).toHaveBeenNthCalledWith(2, '# Hello', 'notes.md')
  })

  it('T9 accept-markdown-and-text-files: the native input accepts md, markdown, txt and both MIME types', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} onUpload={vi.fn()} />)
    const accept = (uploadInput().getAttribute('accept') ?? '').split(',')
    for (const entry of ['.md', '.markdown', '.txt', 'text/markdown', 'text/plain']) {
      expect(accept).toContain(entry)
    }
  })

  it('T10 include-quick-reference: clicking the Markdown control opens the quick-reference popover', async () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} />)
    expect(screen.queryByText('Headings')).toBeNull()
    fireEvent.click(screen.getByRole('button', { name: 'Markdown quick reference' }))
    expect(await screen.findByText('Headings')).toBeInTheDocument()
  })

  it('T11 slot-extra-controls: toolbarExtras renders inside the toolbar, ahead of the built-ins', () => {
    render(
      <MarkdownEditor value="" onChange={vi.fn()} onUpload={vi.fn()}
        toolbarExtras={<button type="button">Spell check</button>} />,
    )
    const toolbar = screen.getByRole('toolbar')
    const extra = screen.getByRole('button', { name: 'Spell check' })
    expect(toolbar.contains(extra)).toBe(true)
    const upload = screen.getByRole('button', { name: /Upload \.md/ })
    expect(extra.compareDocumentPosition(upload) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('T12 propagate-disabled: the textarea and Upload .md button are disabled', () => {
    render(<MarkdownEditor value="" onChange={vi.fn()} onUpload={vi.fn()} disabled />)
    expect(screen.getByLabelText('Markdown body')).toBeDisabled()
    expect(screen.getByRole('button', { name: /Upload \.md/ })).toBeDisabled()
  })

  it('T13 fill-parent-height: rows=16 by default; fill drops rows and adds flex-1 / resize-none to textarea and flex-1 to root', () => {
    const { unmount } = render(<MarkdownEditor value="" onChange={vi.fn()} />)
    expect(screen.getByLabelText('Markdown body')).toHaveAttribute('rows', '16')
    unmount()
    const filled = render(<MarkdownEditor value="" onChange={vi.fn()} fill />)
    const ta = screen.getByLabelText('Markdown body')
    expect(ta).not.toHaveAttribute('rows')
    expect(ta.className).toContain('flex-1')
    expect(ta.className).toContain('resize-none')
    expect((filled.container.firstElementChild as HTMLElement).className).toContain('flex-1')
  })

  it('T14 forward-textarea-props: placeholder, textareaClassName and className are forwarded', () => {
    const { container } = render(
      <MarkdownEditor value="" onChange={vi.fn()} placeholder="Write here"
        textareaClassName="x-ta" className="x-root" />,
    )
    const ta = screen.getByPlaceholderText('Write here')
    expect(ta).toHaveClass('x-ta')
    expect(container.firstElementChild).toHaveClass('x-root')
  })
})

describe('MarkdownEditor — controlled round-trip', () => {
  it('reflects edits back into the textarea', () => {
    render(<ControlledEditor />)
    const textarea = screen.getByLabelText('Markdown body') as HTMLTextAreaElement
    fireEvent.change(textarea, { target: { value: 'edited' } })
    expect(textarea.value).toBe('edited')
  })
})
