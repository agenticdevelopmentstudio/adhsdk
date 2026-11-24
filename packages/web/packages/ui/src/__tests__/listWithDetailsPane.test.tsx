import { render, screen, fireEvent, waitFor, cleanup, act } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import '@testing-library/jest-dom/vitest'
import { ListWithDetailsPane } from '../blocks/list-with-details-pane'
import type { DataTableColumn } from '../components/data-table'

interface Row { id: string; name: string }
const ROWS: Row[] = [{ id: 'a', name: 'Ada' }, { id: 'b', name: 'Babbage' }]
const COLS: DataTableColumn<Row>[] = [{ key: 'name', header: 'Name' }]

function setup(extra: Partial<React.ComponentProps<typeof ListWithDetailsPane<Row>>> = {}) {
  const onDelete = vi.fn()
  render(<ListWithDetailsPane<Row> columns={COLS} rows={ROWS} getRowId={(r) => r.id}
    renderDetail={(r) => <div>detail:{r.name}</div>} emptyDetail={<div>pick one</div>}
    onDelete={onDelete} deleteConfirm={{ title: 'Delete rows?' }} ariaLabel="Rows" {...extra} />)
  return { onDelete }
}

describe('ListWithDetailsPane', () => {
  it('shows the empty-detail hint when nothing is selected', () => {
    setup(); expect(screen.getByText('pick one')).toBeTruthy()
  })
  it('renders the detail for a single selected row', () => {
    setup()
    fireEvent.click(screen.getByText('Ada').closest('[role="row"]')!)
    expect(screen.getByText('detail:Ada')).toBeTruthy()
  })
  it('disables Delete until a row is selected, then confirms before onDelete', () => {
    const { onDelete } = setup()
    // Get the toolbar Delete button (the first one, before the dialog opens)
    const toolbarDel = screen.getByRole('button', { name: 'Delete' })
    expect(toolbarDel).toBeDisabled()

    // Select a row
    fireEvent.click(screen.getByText('Ada').closest('[role="row"]')!)
    expect(toolbarDel).not.toBeDisabled()

    // Click toolbar Delete — should NOT call onDelete yet (needs confirm)
    fireEvent.click(toolbarDel)
    expect(onDelete).not.toHaveBeenCalled()

    // The confirm dialog should now be open — find and click its Delete button
    const dialog = screen.getByRole('dialog')
    const dialogButtons = dialog.querySelectorAll('button')
    const confirmBtn = Array.from(dialogButtons).find(
      (b) => b.textContent?.trim() === 'Delete'
    )
    expect(confirmBtn).toBeTruthy()
    fireEvent.click(confirmBtn!)
    expect(onDelete).toHaveBeenCalledWith(['a'])
  })
  it('filters rows by the filter box', () => {
    setup()
    fireEvent.change(screen.getByPlaceholderText('Filter…'), { target: { value: 'bab' } })
    expect(screen.queryByText('Ada')).toBeNull()
    expect(screen.getByText('Babbage')).toBeTruthy()
  })
  it('shows the multi-select hint when >1 selected', () => {
    setup()
    fireEvent.click(screen.getByText('Ada').closest('[role="row"]')!)
    fireEvent.click(screen.getByText('Babbage').closest('[role="row"]')!, { altKey: true })
    expect(screen.getByText(/select a single row/i)).toBeTruthy()
  })
  it('disables a requiresSelection action until a row is selected', () => {
    const onClick = vi.fn()
    setup({ actions: [{ id: 'approve', label: 'Approve', onClick, requiresSelection: true }] })
    const approve = screen.getByRole('button', { name: 'Approve' })
    expect(approve).toBeDisabled()
    fireEvent.click(screen.getByText('Ada').closest('[role="row"]')!)
    expect(approve).not.toBeDisabled()
  })
  it('prunes stale selected id when row is removed from rows out-of-band', () => {
    const onDelete = vi.fn()
    const { rerender } = render(
      <ListWithDetailsPane<Row> columns={COLS} rows={ROWS} getRowId={(r) => r.id}
        renderDetail={(r) => <div>detail:{r.name}</div>} emptyDetail={<div>pick one</div>}
        onDelete={onDelete} deleteConfirm={{ title: 'Delete rows?' }} ariaLabel="Rows" />
    )
    // Select Ada (id='a')
    fireEvent.click(screen.getByText('Ada').closest('[role="row"]')!)
    const toolbarDel = screen.getByRole('button', { name: 'Delete' })
    expect(toolbarDel).not.toBeDisabled()

    // Remove Ada from rows out-of-band — only Babbage remains
    rerender(
      <ListWithDetailsPane<Row> columns={COLS} rows={[{ id: 'b', name: 'Babbage' }]} getRowId={(r) => r.id}
        renderDetail={(r) => <div>detail:{r.name}</div>} emptyDetail={<div>pick one</div>}
        onDelete={onDelete} deleteConfirm={{ title: 'Delete rows?' }} ariaLabel="Rows" />
    )
    // Delete should be disabled — stale 'a' is pruned
    expect(toolbarDel).toBeDisabled()

    // Now select Babbage and confirm delete — only 'b' should be passed, not phantom 'a'
    fireEvent.click(screen.getByText('Babbage').closest('[role="row"]')!)
    expect(toolbarDel).not.toBeDisabled()
    fireEvent.click(toolbarDel)
    const dialog = screen.getByRole('dialog')
    const confirmBtn = Array.from(dialog.querySelectorAll('button')).find(
      (b) => b.textContent?.trim() === 'Delete'
    )!
    fireEvent.click(confirmBtn)
    expect(onDelete).toHaveBeenCalledWith(['b'])
    expect(onDelete).toHaveBeenCalledTimes(1)
  })
})

// ---------------------------------------------------------------------------------------------
// Conformance vectors T1-T25 (cookbook/ui/blocks/list-with-details-pane/integration-test-vectors.md)
// ---------------------------------------------------------------------------------------------
describe('ListWithDetailsPane conformance vectors', () => {
  interface PRow { id: string; name: string; age: number }
  const PROWS: PRow[] = [
    { id: 'a', name: 'Ada', age: 36 },
    { id: 'b', name: 'Babbage', age: 79 },
  ]
  const PCOLS: DataTableColumn<PRow>[] = [
    { key: 'name', header: 'Name' },
    { key: 'age', header: 'Age' },
  ]
  type Props = React.ComponentProps<typeof ListWithDetailsPane<PRow>>

  function node(extra: Partial<Props> = {}) {
    return (
      <ListWithDetailsPane<PRow> columns={PCOLS} rows={PROWS} getRowId={(r) => r.id}
        renderDetail={(r) => <div>detail:{r.name}</div>} emptyDetail={<div>pick one</div>}
        onDelete={vi.fn()} deleteConfirm={{ title: 'Delete rows?' }} ariaLabel="Rows" {...extra} />
    )
  }
  function mount(extra: Partial<Props> = {}) {
    return render(node(extra))
  }
  const rowEl = (name: string): HTMLElement => screen.getByText(name).closest('[role="row"]') as HTMLElement
  const selectRow = (name: string): void => { fireEvent.click(rowEl(name)) }
  const toolbarDelete = (): HTMLElement => screen.getByRole('button', { name: 'Delete' })
  function confirmDialog(label: 'Delete' | 'Cancel'): void {
    const dialog = screen.getByRole('dialog')
    const btn = Array.from(dialog.querySelectorAll('button')).find((b) => b.textContent?.trim() === label)!
    fireEvent.click(btn)
  }
  const urlParam = (k: string): string | null => new URLSearchParams(window.location.search).get(k)

  beforeEach(() => {
    cleanup()
    window.history.replaceState(null, '', '/')
    try { window.localStorage.clear() } catch { /* shim may be absent */ }
  })

  it('T1 filter-rows: typing ada narrows the table to matching rows', () => {
    mount()
    fireEvent.change(screen.getByPlaceholderText('Filter…'), { target: { value: 'ada' } })
    expect(screen.getByText('Ada')).toBeTruthy()
    expect(screen.queryByText('Babbage')).toBeNull()
  })

  it('T2 own-selection: selection persists across filter changes', () => {
    mount()
    selectRow('Ada')
    fireEvent.change(screen.getByPlaceholderText('Filter…'), { target: { value: 'bab' } })
    expect(screen.queryByText('Ada')).toBeNull()
    expect(toolbarDelete()).not.toBeDisabled()
    fireEvent.change(screen.getByPlaceholderText('Filter…'), { target: { value: '' } })
    expect(rowEl('Ada')).toHaveAttribute('aria-selected', 'true')
  })

  it('T3 disable-selection-actions: Delete and requiresSelection actions are disabled with 0 rows selected', () => {
    mount({ actions: [{ id: 'go', label: 'Go', onClick: vi.fn(), requiresSelection: true }] })
    expect(toolbarDelete()).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Go' })).toBeDisabled()
  })

  it('T4 disable-selection-actions: Delete and requiresSelection actions are enabled with >=1 row selected', () => {
    const onClick = vi.fn()
    mount({ actions: [{ id: 'go', label: 'Go', onClick, requiresSelection: true }] })
    selectRow('Ada')
    expect(toolbarDelete()).not.toBeDisabled()
    const go = screen.getByRole('button', { name: 'Go' })
    expect(go).not.toBeDisabled()
    fireEvent.click(go)
    expect(onClick).toHaveBeenCalledWith(['a'])
  })

  it('T5 confirm-delete: confirm calls onDelete(selectedIds) and clears the selection at once', () => {
    const onDelete = vi.fn()
    mount({ onDelete })
    selectRow('Ada')
    expect(screen.getByText('detail:Ada')).toBeTruthy()
    fireEvent.click(toolbarDelete())
    expect(screen.getByRole('dialog')).toBeTruthy()
    expect(onDelete).not.toHaveBeenCalled()
    confirmDialog('Delete')
    expect(onDelete).toHaveBeenCalledWith(['a'])
    // rows is unchanged (the caller has not removed anything), yet the selection is already empty
    expect(screen.getByText('Ada')).toBeTruthy()
    expect(screen.queryByText('detail:Ada')).toBeNull()
    expect(screen.getByText('pick one')).toBeTruthy()
    expect(toolbarDelete()).toBeDisabled()
  })

  it('T6 render-detail-states: pane shows emptyDetail, renderDetail(row), then the multi-select hint', () => {
    mount()
    expect(screen.getByText('pick one')).toBeTruthy()
    selectRow('Ada')
    expect(screen.getByText('detail:Ada')).toBeTruthy()
    fireEvent.click(rowEl('Babbage'), { altKey: true })
    expect(screen.getByText('Select a single row to see details.')).toBeTruthy()
    expect(screen.queryByText('detail:Ada')).toBeNull()
  })

  it('T6 render-detail-states: emptyDetail defaults to "Select a row to see details."', () => {
    mount({ emptyDetail: undefined })
    expect(screen.getByText('Select a row to see details.')).toBeTruthy()
  })

  it('T7 render-divider-before-action: dividerBefore renders a separator immediately before the button', () => {
    mount({ actions: [
      { id: 'one', label: 'One', onClick: vi.fn() },
      { id: 'two', label: 'Two', onClick: vi.fn(), dividerBefore: true },
    ] })
    const two = screen.getByRole('button', { name: 'Two' })
    expect(two.previousElementSibling).toHaveAttribute('role', 'separator')
    const one = screen.getByRole('button', { name: 'One' })
    expect(one.previousElementSibling?.getAttribute('role')).not.toBe('separator')
  })

  it('T8 support-url-driven-selection: selecting a row writes ?id= via replaceState; a remount restores it', () => {
    const push = vi.spyOn(window.history, 'pushState')
    const replace = vi.spyOn(window.history, 'replaceState')
    const { unmount } = mount({ paramKey: 'id' })
    replace.mockClear()
    selectRow('Babbage')
    expect(urlParam('id')).toBe('b')
    expect(replace).toHaveBeenCalled()
    expect(push).not.toHaveBeenCalled()
    expect(screen.getByText('detail:Babbage')).toBeTruthy()
    unmount()
    mount({ paramKey: 'id' })
    expect(screen.getByText('detail:Babbage')).toBeTruthy()
    expect(rowEl('Babbage')).toHaveAttribute('aria-selected', 'true')
    push.mockRestore()
    replace.mockRestore()
  })

  it('T8 support-url-driven-selection: a 0-or-many selection clears the parameter', () => {
    mount({ paramKey: 'id' })
    selectRow('Ada')
    expect(urlParam('id')).toBe('a')
    fireEvent.click(rowEl('Babbage'), { altKey: true })
    expect(urlParam('id')).toBeNull()
  })

  it('T9 clear-stale-deep-link: an id missing from loaded rows is cleared from selection and URL', () => {
    window.history.replaceState(null, '', '/?id=deleted-id')
    mount({ paramKey: 'id' })
    expect(urlParam('id')).toBeNull()
    expect(screen.getByText('pick one')).toBeTruthy()
    expect(toolbarDelete()).toBeDisabled()
  })

  it('T10 persist-column-widths: a dragged width is stored under columnWidthsKey and restored on remount', () => {
    const headerRow = (): HTMLElement => screen.getAllByRole('row')[0] as HTMLElement
    const { unmount } = mount({ autoSizeColumns: true, columnWidthsKey: 'lwdp-test' })
    const handle = screen.getByRole('separator', { name: 'Resize column name' })
    ;(handle as HTMLElement & { setPointerCapture: (id: number) => void }).setPointerCapture = () => {}
    fireEvent.pointerDown(handle, { pointerId: 1, clientX: 0 })
    act(() => {
      window.dispatchEvent(new MouseEvent('pointermove', { clientX: 321 }))
      window.dispatchEvent(new MouseEvent('pointerup', { clientX: 321 }))
    })
    expect(headerRow().style.gridTemplateColumns.startsWith('321px')).toBe(true)
    const stored = JSON.parse(window.localStorage.getItem('data-table-cols:lwdp-test') ?? '{}') as Record<string, number>
    expect(stored.name).toBe(321)
    unmount()
    mount({ autoSizeColumns: true, columnWidthsKey: 'lwdp-test' })
    expect(headerRow().style.gridTemplateColumns.startsWith('321px')).toBe(true)
  })

  it('T11 support-row-reordering: reorder is forwarded to DataTable, with or without a filter', () => {
    const cols: DataTableColumn<PRow>[] = [
      { key: 'name', header: 'Name', render: (r, ctx) => <span {...ctx.dragHandleProps} data-testid={`grip-${r.id}`}>{r.name}</span> },
    ]
    const { unmount } = mount({ columns: cols })
    expect(screen.getByTestId('grip-a')).not.toHaveAttribute('role')
    unmount()
    mount({ columns: cols, reorder: { onDrop: vi.fn(), describeRow: (id) => id } })
    expect(screen.getByTestId('grip-a')).toHaveAttribute('role', 'button')
    // the component forwards reorder unconditionally: still live while a filter is active
    fireEvent.change(screen.getByPlaceholderText('Filter…'), { target: { value: 'ada' } })
    expect(screen.getByTestId('grip-a')).toHaveAttribute('role', 'button')
  })

  it('T12 clear-stale-deep-link: no pruning while loading with empty rows', () => {
    window.history.replaceState(null, '', '/?id=some-id')
    mount({ paramKey: 'id', rows: [], loading: true })
    expect(urlParam('id')).toBe('some-id')
  })

  it('T12 clear-stale-deep-link: the id survives the load and is pruned only once rows arrive without it', () => {
    window.history.replaceState(null, '', '/?id=a')
    const { rerender } = mount({ paramKey: 'id', rows: [], loading: true })
    expect(urlParam('id')).toBe('a')
    rerender(node({ paramKey: 'id', rows: PROWS, loading: false }))
    expect(urlParam('id')).toBe('a')
    expect(screen.getByText('detail:Ada')).toBeTruthy()
    rerender(node({ paramKey: 'id', rows: [PROWS[1]!], loading: false }))
    expect(urlParam('id')).toBeNull()
  })

  it('T13 use-list-header: the toolbar is the shared ListHeader with the filter left and actions right', () => {
    mount({ actions: [{ id: 'go', label: 'Go', onClick: vi.fn() }] })
    const bar = screen.getByRole('toolbar', { name: 'Rows actions' })
    const filter = screen.getByPlaceholderText('Filter…')
    const go = screen.getByRole('button', { name: 'Go' })
    expect(bar.contains(filter)).toBe(true)
    expect(bar.contains(go)).toBe(true)
    expect(filter.compareDocumentPosition(go) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('T14 render-details-header-bar: the divider is a header bar titled detailsLabel (default "Details")', () => {
    const { unmount } = mount()
    const title = screen.getByText('Details')
    const bar = title.closest('[role="separator"]') as HTMLElement
    expect(bar).toBeTruthy()
    expect(bar).toHaveAttribute('tabindex', '0')
    expect(bar.querySelector('button[aria-label="Details"]')).toBeTruthy()
    unmount()
    mount({ detailsLabel: 'Inspector' })
    const bar2 = screen.getByText('Inspector').closest('[role="separator"]') as HTMLElement
    expect(bar2.querySelector('button[aria-label="Inspector"]')).toBeTruthy()
  })

  it('T15 move-selection-by-keyboard: ArrowDown then ArrowUp move the selection', () => {
    mount()
    const grid = screen.getByRole('grid')
    fireEvent.focus(grid)
    fireEvent.keyDown(grid, { key: 'ArrowDown' })
    expect(rowEl('Babbage')).toHaveAttribute('aria-selected', 'true')
    expect(screen.getByText('detail:Babbage')).toBeTruthy()
    fireEvent.keyDown(grid, { key: 'ArrowUp' })
    expect(rowEl('Ada')).toHaveAttribute('aria-selected', 'true')
    expect(rowEl('Babbage')).toHaveAttribute('aria-selected', 'false')
  })

  it('T16 auto-size-columns: autoSizeColumns is forwarded, giving content-sized tracks and resize handles', () => {
    const { unmount } = mount()
    expect(screen.queryByRole('separator', { name: 'Resize column name' })).toBeNull()
    expect(screen.getAllByRole('row')[0]!.style.gridTemplateColumns).toBe('1fr 1fr')
    unmount()
    mount({ autoSizeColumns: true })
    expect(screen.getAllByRole('row')[0]!.style.gridTemplateColumns).toBe('max-content max-content minmax(0,1fr)')
    expect(screen.getByRole('separator', { name: 'Resize column name' })).toBeTruthy()
  })

  it('T17 omit-delete-without-handler: no Delete button without onDelete', () => {
    mount({ onDelete: undefined })
    expect(screen.queryByRole('button', { name: 'Delete' })).toBeNull()
  })

  it('T18 forward-loading-state: loading shows the table loading state, not emptyLabel', () => {
    mount({ rows: [], loading: true, emptyLabel: 'Nothing here' })
    expect(screen.getByRole('status')).toHaveTextContent('Loading…')
    expect(screen.queryByText('Nothing here')).toBeNull()
  })

  it('T19 support-url-driven-selection, own-selection: URL selection seeds even when filterText hides the row', () => {
    window.history.replaceState(null, '', '/?id=a')
    mount({ paramKey: 'id', filterText: 'bab', onFilterTextChange: vi.fn() })
    expect(screen.queryByText('Ada')).toBeNull()
    expect(screen.getByText('Babbage')).toBeTruthy()
    expect(screen.getByText('detail:Ada')).toBeTruthy()
    expect(urlParam('id')).toBe('a')
  })

  it('T20 clear-stale-deep-link: no pruning while rows is empty, even with loading false', () => {
    window.history.replaceState(null, '', '/?id=gone')
    mount({ paramKey: 'id', rows: [], loading: false })
    expect(urlParam('id')).toBe('gone')
  })

  it('T21 confirm-delete: Cancel closes the modal, skips onDelete and leaves selection and URL alone', async () => {
    const onDelete = vi.fn()
    mount({ onDelete, paramKey: 'id' })
    selectRow('Ada')
    fireEvent.click(toolbarDelete())
    confirmDialog('Cancel')
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
    expect(onDelete).not.toHaveBeenCalled()
    expect(screen.getByText('detail:Ada')).toBeTruthy()
    expect(urlParam('id')).toBe('a')
    expect(toolbarDelete()).not.toBeDisabled()
  })

  it('T22 confirm-delete, support-url-driven-selection: confirming clears the selection and the id parameter', () => {
    const onDelete = vi.fn()
    mount({ onDelete, paramKey: 'id' })
    selectRow('Ada')
    expect(urlParam('id')).toBe('a')
    fireEvent.click(toolbarDelete())
    confirmDialog('Delete')
    expect(onDelete).toHaveBeenCalledWith(['a'])
    expect(urlParam('id')).toBeNull()
    expect(screen.getByText('pick one')).toBeTruthy()
  })

  it('T23 render-detail-states: a selected row hidden by the filter still shows its details', () => {
    mount()
    selectRow('Ada')
    fireEvent.change(screen.getByPlaceholderText('Filter…'), { target: { value: 'bab' } })
    expect(screen.queryByText('Ada')).toBeNull()
    expect(screen.getByText('detail:Ada')).toBeTruthy()
  })

  it('T24 filter-rows: default filter is a case-insensitive substring over each column value', () => {
    mount({ rows: [{ id: 'a', name: 'Ada', age: 36 }] })
    const box = screen.getByPlaceholderText('Filter…')
    fireEvent.change(box, { target: { value: 'ADA' } })
    expect(screen.getByText('Ada')).toBeTruthy()
    fireEvent.change(box, { target: { value: '36' } })
    expect(screen.getByText('Ada')).toBeTruthy()
    fireEvent.change(box, { target: { value: 'zzz' } })
    expect(screen.queryByText('Ada')).toBeNull()
  })

  it('T25 filter-rows: a controlled filterText drives the table and the box; the spy gets typed text', () => {
    const onFilterTextChange = vi.fn()
    mount({ filterText: 'ada', onFilterTextChange })
    expect(screen.getByText('Ada')).toBeTruthy()
    expect(screen.queryByText('Babbage')).toBeNull()
    const box = screen.getByPlaceholderText('Filter…') as HTMLInputElement
    expect(box.value).toBe('ada')
    fireEvent.change(box, { target: { value: 'adam' } })
    expect(onFilterTextChange).toHaveBeenCalledWith('adam')
    expect(box.value).toBe('ada')
  })

  it('T24 filter-rows: a custom filterRow replaces the default', () => {
    mount({ filterRow: (r, q) => r.name.toLowerCase().startsWith(q) })
    fireEvent.change(screen.getByPlaceholderText('Filter…'), { target: { value: 'b' } })
    expect(screen.queryByText('Ada')).toBeNull()
    expect(screen.getByText('Babbage')).toBeTruthy()
  })
})
