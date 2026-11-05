import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { DocumentSaveBar, type DocumentSaveBarProps } from '../blocks/document-save-bar'

function doc(over: Partial<DocumentSaveBarProps['document']> = {}): DocumentSaveBarProps['document'] {
  return {
    dirty: false,
    saving: false,
    gone: false,
    changedElsewhere: false,
    conflict: null,
    saveError: null,
    save: vi.fn(async () => {}),
    overwrite: vi.fn(async () => {}),
    revert: vi.fn(),
    takeTheirs: vi.fn(),
    ...over,
  }
}

const button = (name: string) => screen.getByRole('button', { name }) as HTMLButtonElement

describe('DocumentSaveBar', () => {
  it('disables Save and Revert with nothing to save', () => {
    render(<DocumentSaveBar document={doc()} />)
    expect(button('Save').disabled).toBe(true)
    expect(button('Revert').disabled).toBe(true)
  })

  it('wires Save and Revert when dirty, and holds Save while saving', () => {
    const d = doc({ dirty: true })
    const { rerender } = render(<DocumentSaveBar document={d} />)
    fireEvent.click(button('Save'))
    fireEvent.click(button('Revert'))
    expect(d.save).toHaveBeenCalled()
    expect(d.revert).toHaveBeenCalled()
    rerender(<DocumentSaveBar document={{ ...d, saving: true }} />)
    expect(button('Save').disabled).toBe(true)
  })

  it('names the document in its default notices', () => {
    render(<DocumentSaveBar noun="note" document={doc({ gone: true, changedElsewhere: true })} />)
    expect(screen.getByRole('alert').textContent).toBe('This note no longer exists.')
    expect(screen.getByText('This note changed since it was opened.')).toBeTruthy()
  })

  it('takes host wording for any notice', () => {
    render(
      <DocumentSaveBar
        document={doc({ changedElsewhere: true })}
        messages={{ changedElsewhere: 'This file changed on disk.' }}
      />,
    )
    expect(screen.getByText('This file changed on disk.')).toBeTruthy()
  })

  it('offers Reload theirs and Overwrite on a conflict, and hides the changed notice under it', () => {
    const d = doc({ dirty: true, changedElsewhere: true, conflict: { text: 't', version: 'v9' } })
    render(<DocumentSaveBar noun="file" document={d} />)
    expect(screen.getByText('Someone else saved this file.')).toBeTruthy()
    expect(screen.getByRole('alert').textContent).toContain('Someone else saved this file.')
    expect(screen.queryByText(/changed since/)).toBeNull()
    fireEvent.click(button('Reload theirs'))
    fireEvent.click(button('Overwrite'))
    expect(d.takeTheirs).toHaveBeenCalled()
    expect(d.overwrite).toHaveBeenCalled()
  })

  it('shows a failed save inline as an alert', () => {
    render(<DocumentSaveBar document={doc({ saveError: 'disk full' })} />)
    expect(screen.getByRole('alert').textContent).toBe('Save failed: disk full')
  })
})
