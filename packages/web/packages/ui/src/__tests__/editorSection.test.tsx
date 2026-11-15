/// <reference types="@testing-library/jest-dom/vitest" />
import type { ComponentProps } from 'react'
import { render, screen, cleanup, fireEvent, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { EditorSection } from '../blocks/editor-section'

afterEach(cleanup)

type Props = ComponentProps<typeof EditorSection>

const items = [
  { id: 'r1', label: 'Alpha' },
  { id: 'r2', label: 'Beta' },
]

function setup(over: Partial<Props> = {}) {
  const handlers = {
    onSelect: vi.fn(),
    onNew: vi.fn(),
    onDelete: vi.fn(),
    onCancel: vi.fn(),
    onSave: vi.fn(),
  }
  const props: Props = {
    title: 'Sites',
    createLabel: 'New site',
    items,
    selectedId: 'r1',
    dirty: false,
    emptyDetail: 'Pick a site',
    ...handlers,
    children: <form data-testid="form">record form</form>,
    ...over,
  }
  const view = render(<EditorSection {...props} />)
  return { ...view, ...handlers, props }
}

const btn = (name: string | RegExp) => screen.getByRole('button', { name }) as HTMLButtonElement
const toolbar = () => screen.getByRole('toolbar')

describe('EditorSection integration vectors', () => {
  it('T1 nothing selected shows the EmptyState titled emptyDetail and no children', () => {
    setup({ selectedId: null })
    expect(screen.getByText('Pick a site')).toBeInTheDocument()
    expect(screen.queryByTestId('form')).toBeNull()
  })

  it('T2 a selection shows children and no EmptyState', () => {
    setup({ selectedId: 'r1' })
    expect(screen.getByTestId('form')).toBeInTheDocument()
    expect(screen.queryByText('Pick a site')).toBeNull()
  })

  it('T3 the title and its badge sit in the toolbar leading slot', () => {
    setup({ title: 'Sites', titleBadge: <span data-testid="badge">3</span> })
    const lead = within(toolbar()).getByText('Sites')
    expect(lead.className).toContain('text-apt-gold')
    expect(lead.className).toContain('font-mono')
    expect(lead).toContainElement(within(toolbar()).getByTestId('badge'))
  })

  it('T4 Save is disabled while editing a clean draft', () => {
    setup({ dirty: false })
    expect(btn('Save').disabled).toBe(true)
  })

  it('T5 Save is enabled (gold) while editing a dirty draft', () => {
    setup({ dirty: true })
    const save = btn('Save')
    expect(save.disabled).toBe(false)
    expect(save.className).not.toContain('text-apt-text-muted')
  })

  it('T6 Cancel is disabled with nothing selected', () => {
    setup({ selectedId: null })
    expect(btn('Cancel').disabled).toBe(true)
  })

  it('T7 Delete is enabled while editing when canDelete is unset', () => {
    setup()
    expect(btn('Delete').disabled).toBe(false)
  })

  it('T8 canDelete false disables Delete for a new draft', () => {
    setup({ canDelete: false })
    expect(btn('Delete').disabled).toBe(true)
  })

  it('T9 busy disables Delete, Cancel and Save ("Saving…") but not New', () => {
    setup({ busy: true, dirty: true })
    expect(btn('Delete').disabled).toBe(true)
    expect(btn('Cancel').disabled).toBe(true)
    const save = btn(/Saving/)
    expect(save.disabled).toBe(true)
    expect(save.textContent).toContain('Saving…')
    expect(btn('New site').disabled).toBe(false)
  })

  it('T10 omitting onDelete renders no Delete button', () => {
    setup({ onDelete: undefined })
    expect(screen.queryByRole('button', { name: 'Delete' })).toBeNull()
  })

  it('T11 a warned row with a count shows an accent "⚠ N" badge carrying warnTitle', () => {
    setup({ items: [{ id: 'r1', label: 'Alpha', warn: true, warnCount: 5, warnTitle: 'five unconnected' }, items[1]!] })
    const badge = screen.getByLabelText('five unconnected')
    expect(badge.textContent).toBe('⚠ 5')
    expect(badge).toHaveAttribute('title', 'five unconnected')
  })

  it('T12 a warned row without a count shows a bare ⚠; other rows show none', () => {
    setup({ items: [{ id: 'r1', label: 'Alpha', warn: true }, items[1]!] })
    const warnings = screen.getAllByText('⚠')
    expect(warnings).toHaveLength(1)
    expect(screen.getByRole('button', { name: /Alpha/ })).toContainElement(warnings[0]!)
    expect(screen.getByRole('button', { name: /Beta/ }).textContent).not.toContain('⚠')
  })

  it('T13 error renders a red line under the toolbar; absent when unset', () => {
    const { unmount } = setup({ error: 'Save failed' })
    const line = screen.getByText('Save failed')
    expect(line.className).toContain('text-apt-red')
    expect(toolbar().compareDocumentPosition(line) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    unmount()
    setup()
    expect(screen.queryByText('Save failed')).toBeNull()
  })

  it.skip('T14 listHeader is hidden while the rail is collapsed (EditorSection exposes no collapse control and jsdom cannot drive the drag-resize)', () => {})

  it('T14 listHeader shows while the rail is expanded', () => {
    setup({ listHeader: <div data-testid="filters">filters</div> })
    expect(screen.getByTestId('filters')).toBeInTheDocument()
  })

  it('T15 an empty list shows the default "Nothing here yet." label', () => {
    setup({ items: [], selectedId: null })
    expect(screen.getByText('Nothing here yet.')).toBeInTheDocument()
  })

  it('T15 a supplied emptyList replaces the default', () => {
    setup({ items: [], selectedId: null, emptyList: 'No sites' })
    expect(screen.getByText('No sites')).toBeInTheDocument()
    expect(screen.queryByText('Nothing here yet.')).toBeNull()
  })

  it('T16 the warned row accessible name includes warnTitle after the label', () => {
    setup({ items: [{ id: 'r1', label: 'Alpha', warn: true, warnCount: 5, warnTitle: '5 project sites not yet connected' }, items[1]!] })
    expect(screen.getByRole('button', { name: /Alpha.*5 project sites not yet connected/ })).toBeInTheDocument()
  })

  it('T17 an explicit canDelete true is honored with nothing selected', () => {
    setup({ selectedId: null, canDelete: true })
    expect(btn('Delete').disabled).toBe(false)
  })

  it('T18 selecting a row calls onSelect with its id once', () => {
    const { onSelect } = setup()
    fireEvent.click(screen.getByRole('button', { name: /Beta/ }))
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect).toHaveBeenCalledWith('r2')
  })

  it('T19 toolbar intents reach their own callbacks once, in order, and nothing else fires', () => {
    const { onNew, onDelete, onCancel, onSave, onSelect } = setup({ dirty: true })
    const order: string[] = []
    onNew.mockImplementation(() => order.push('new'))
    onDelete.mockImplementation(() => order.push('delete'))
    onCancel.mockImplementation(() => order.push('cancel'))
    onSave.mockImplementation(() => order.push('save'))
    fireEvent.click(btn('New site'))
    fireEvent.click(btn('Delete'))
    fireEvent.click(btn('Cancel'))
    fireEvent.click(btn('Save'))
    expect(order).toEqual(['new', 'delete', 'cancel', 'save'])
    for (const fn of [onNew, onDelete, onCancel, onSave]) expect(fn).toHaveBeenCalledTimes(1)
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('T20 railWidth sizes the rail column through --rail-w; default is 240px', () => {
    const { container, unmount } = setup({ railWidth: 360 })
    const grid = container.querySelector('[style*="--rail-w"]') as HTMLElement
    expect(grid.style.getPropertyValue('--rail-w')).toBe('360px')
    unmount()
    const again = setup()
    const grid2 = again.container.querySelector('[style*="--rail-w"]') as HTMLElement
    expect(grid2.style.getPropertyValue('--rail-w')).toBe('240px')
  })
})
