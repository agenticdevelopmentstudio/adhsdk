import { render, screen, fireEvent, within } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { SelectionActions, type ListAction } from '../blocks/selection-actions'

// The strip on its own — the way a table with no details pane uses it. The
// ListWithDetailsPane tests cover it in place; these cover every conformance vector
// of the selection-actions recipe directly. One `it` per vector, titled by its id.

const GHOST_MARK = 'hover:bg-muted/50'
const DESTRUCTIVE_GHOST_MARK = 'hover:bg-destructive/10'

function openDelete(): HTMLElement {
  fireEvent.click(screen.getByRole('button', { name: /Delete/ }))
  return screen.getByRole('dialog')
}

function modalButton(dialog: HTMLElement, label: string): HTMLButtonElement {
  const found = Array.from(dialog.querySelectorAll('button')).find((b) => b.textContent?.trim() === label)
  if (!found) throw new Error(`no modal button labelled ${label}`)
  return found
}

describe('SelectionActions conformance vectors', () => {
  it('selection-actions-001: renders a Button with the action label', () => {
    const actions: ListAction[] = [{ id: 'a1', label: 'Archive', onClick: vi.fn() }]
    render(<SelectionActions selectedIds={[]} actions={actions} />)
    expect(screen.getByRole('button', { name: 'Archive' })).toBeInTheDocument()
  })

  it('selection-actions-002: passes the selected ids to the action onClick', () => {
    const onClick = vi.fn()
    render(
      <SelectionActions selectedIds={['row1', 'row2']} actions={[{ id: 'a1', label: 'Archive', onClick }]} />,
    )
    fireEvent.click(screen.getByRole('button', { name: 'Archive' }))
    expect(onClick).toHaveBeenCalledWith(['row1', 'row2'])
  })

  it('selection-actions-003: disables a requiresSelection action on an empty selection', () => {
    const onClick = vi.fn()
    render(
      <SelectionActions
        selectedIds={[]}
        actions={[{ id: 'a1', label: 'Archive', onClick, requiresSelection: true }]}
      />,
    )
    const btn = screen.getByRole('button', { name: 'Archive' })
    expect(btn).toBeDisabled()
    fireEvent.click(btn)
    expect(onClick).not.toHaveBeenCalled()
  })

  it('selection-actions-004: keeps a standalone action enabled and clickable on an empty selection', () => {
    const onClick = vi.fn()
    render(
      <SelectionActions
        selectedIds={[]}
        actions={[{ id: 'a1', label: 'New', onClick, requiresSelection: false }]}
      />,
    )
    const btn = screen.getByRole('button', { name: 'New' })
    expect(btn).not.toBeDisabled()
    fireEvent.click(btn)
    expect(onClick).toHaveBeenCalledWith([])
  })

  it('selection-actions-005: uses the ghost variant by default and honours an explicit variant', () => {
    render(
      <SelectionActions
        selectedIds={[]}
        actions={[
          { id: 'a1', label: 'Archive', onClick: vi.fn() },
          { id: 'a2', label: 'Warn', onClick: vi.fn(), variant: 'warning' },
        ]}
      />,
    )
    const archive = screen.getByRole('button', { name: 'Archive' })
    expect(archive.className).toContain(GHOST_MARK)
    expect(archive.className).not.toContain('bg-primary ')
    const warn = screen.getByRole('button', { name: 'Warn' })
    expect(warn.className).not.toContain(GHOST_MARK)
    expect(warn.className).toContain('text-apt-orange')
  })

  it('selection-actions-006: renders a separator before the action with dividerBefore', () => {
    render(
      <SelectionActions
        selectedIds={[]}
        actions={[{ id: 'a1', label: 'Archive', onClick: vi.fn(), dividerBefore: true }]}
      />,
    )
    const sep = screen.getByRole('separator')
    const btn = screen.getByRole('button', { name: 'Archive' })
    expect(sep.compareDocumentPosition(btn) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    expect(sep.nextElementSibling).toBe(btn)
  })

  it('selection-actions-007: renders no Delete button when onDelete is undefined', () => {
    render(<SelectionActions selectedIds={['a']} actions={[]} />)
    expect(screen.queryByRole('button', { name: /Delete/ })).toBeNull()
  })

  it('selection-actions-008: renders the Delete button when onDelete is provided', () => {
    render(<SelectionActions selectedIds={['a']} onDelete={vi.fn()} />)
    expect(screen.getByRole('button', { name: /Delete/ })).toBeInTheDocument()
  })

  it('selection-actions-009: disables Delete on an empty selection', () => {
    render(<SelectionActions selectedIds={[]} onDelete={vi.fn()} />)
    expect(screen.getByRole('button', { name: /Delete/ })).toBeDisabled()
  })

  it('selection-actions-010: enables Delete when a row is selected', () => {
    render(<SelectionActions selectedIds={['row1']} onDelete={vi.fn()} />)
    expect(screen.getByRole('button', { name: /Delete/ })).not.toBeDisabled()
  })

  it('selection-actions-011: styles Delete with the destructive-ghost variant', () => {
    render(<SelectionActions selectedIds={['row1']} onDelete={vi.fn()} />)
    const btn = screen.getByRole('button', { name: /Delete/ })
    expect(btn.className).toContain(DESTRUCTIVE_GHOST_MARK)
    expect(btn.className).not.toContain(GHOST_MARK)
  })

  it('selection-actions-012: Delete contains the Trash2 icon and the text "Delete"', () => {
    render(<SelectionActions selectedIds={['row1']} onDelete={vi.fn()} />)
    const btn = screen.getByRole('button', { name: /Delete/ })
    expect(btn.textContent?.trim()).toBe('Delete')
    const icon = btn.querySelector('svg')
    expect(icon).not.toBeNull()
    expect(icon!.getAttribute('class')).toContain('lucide-trash-2')
  })

  it('selection-actions-013: the confirmation AlertModal is destructive', () => {
    render(<SelectionActions selectedIds={['row1']} onDelete={vi.fn()} />)
    const dialog = openDelete()
    // destructive swaps the tone icon to the error glyph and paints the confirm button red.
    expect(dialog.querySelector('svg.text-apt-red')).not.toBeNull()
    expect(modalButton(dialog, 'Delete').className).toContain('text-destructive')
  })

  it('selection-actions-014: shows the default title "Delete selected?" without deleteConfirm', () => {
    render(<SelectionActions selectedIds={['row1']} onDelete={vi.fn()} />)
    const dialog = openDelete()
    expect(within(dialog).getByText('Delete selected?')).toBeInTheDocument()
  })

  it('selection-actions-015: shows the custom deleteConfirm title', () => {
    render(
      <SelectionActions selectedIds={['row1']} onDelete={vi.fn()} deleteConfirm={{ title: 'Remove items?' }} />,
    )
    const dialog = openDelete()
    expect(within(dialog).getByText('Remove items?')).toBeInTheDocument()
    expect(within(dialog).queryByText('Delete selected?')).toBeNull()
  })

  it('selection-actions-016: calls onDelete only after the user confirms', () => {
    const onDelete = vi.fn()
    render(<SelectionActions selectedIds={['row1']} onDelete={onDelete} />)
    const dialog = openDelete()
    expect(onDelete).not.toHaveBeenCalled()
    fireEvent.click(modalButton(dialog, 'Delete'))
    expect(onDelete).toHaveBeenCalledTimes(1)
    expect(onDelete).toHaveBeenCalledWith(['row1'])
  })

  it('selection-actions-017: Cancel closes the modal without calling onDelete', () => {
    const onDelete = vi.fn()
    render(<SelectionActions selectedIds={['row1']} onDelete={onDelete} />)
    openDelete()
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }))
    expect(onDelete).not.toHaveBeenCalled()
    expect(screen.queryByRole('dialog')).toBeNull()
  })

  it('selection-actions-018: the divider has role separator and vertical orientation', () => {
    render(
      <SelectionActions
        selectedIds={[]}
        actions={[{ id: 'a1', label: 'Archive', onClick: vi.fn(), dividerBefore: true }]}
      />,
    )
    const sep = screen.getByRole('separator')
    expect(sep).toHaveAttribute('aria-orientation', 'vertical')
  })

  it('selection-actions-019: the confirm button label is "Delete"', () => {
    render(<SelectionActions selectedIds={['row1']} onDelete={vi.fn()} />)
    const dialog = openDelete()
    expect(modalButton(dialog, 'Delete')).toBeInTheDocument()
  })

  it('selection-actions-020: the cancel button label is "Cancel"', () => {
    render(<SelectionActions selectedIds={['row1']} onDelete={vi.fn()} />)
    const dialog = openDelete()
    expect(modalButton(dialog, 'Cancel')).toBeInTheDocument()
  })

  it('selection-actions-021: the modal closes immediately on confirm', () => {
    const onDelete = vi.fn()
    render(<SelectionActions selectedIds={['row1']} onDelete={onDelete} />)
    const dialog = openDelete()
    fireEvent.click(modalButton(dialog, 'Delete'))
    expect(onDelete).toHaveBeenCalledWith(['row1'])
    expect(screen.queryByRole('dialog')).toBeNull()
  })

  it('selection-actions-022: onDelete receives selectedIds as they stand at confirmation', () => {
    const onDelete = vi.fn()
    const { rerender } = render(<SelectionActions selectedIds={['row1']} onDelete={onDelete} />)
    const dialog = openDelete()
    rerender(<SelectionActions selectedIds={['row1', 'row2']} onDelete={onDelete} />)
    fireEvent.click(modalButton(dialog, 'Delete'))
    expect(onDelete).toHaveBeenCalledWith(['row1', 'row2'])
    expect(onDelete).not.toHaveBeenCalledWith(['row1'])
  })

  it('selection-actions-023: duplicate action ids still render and invoke their own onClick', () => {
    const errors = vi.spyOn(console, 'error').mockImplementation(() => {})
    try {
      const onClickA = vi.fn()
      const onClickB = vi.fn()
      render(
        <SelectionActions
          selectedIds={['row1']}
          actions={[
            { id: 'a1', label: 'Archive', onClick: onClickA },
            { id: 'a1', label: 'Rename', onClick: onClickB },
          ]}
        />,
      )
      fireEvent.click(screen.getByRole('button', { name: 'Archive' }))
      expect(onClickA).toHaveBeenCalledTimes(1)
      expect(onClickB).not.toHaveBeenCalled()
      fireEvent.click(screen.getByRole('button', { name: 'Rename' }))
      expect(onClickB).toHaveBeenCalledTimes(1)
      expect(onClickA).toHaveBeenCalledTimes(1)
    } finally {
      errors.mockRestore()
    }
  })

  it('selection-actions-024: a title-only deleteConfirm shows the title and no description', () => {
    render(
      <SelectionActions selectedIds={['row1']} onDelete={vi.fn()} deleteConfirm={{ title: 'Remove items?' }} />,
    )
    const dialog = openDelete()
    expect(within(dialog).getByText('Remove items?')).toBeInTheDocument()
    expect(dialog.querySelector('[data-slot="dialog-description"]')).toBeNull()
    expect(dialog.getAttribute('aria-describedby')).toBeNull()
  })
})
