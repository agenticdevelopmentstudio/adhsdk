import '@testing-library/jest-dom/vitest'
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { CrudTable, cellText, displayColumns } from '../CrudTable'
import { rowKey } from '../useCrudResource'
import type { CrudColumn, CrudTableMeta } from '../types'

const col = (name: string, overrides: Partial<CrudColumn> = {}): CrudColumn => ({
  name,
  type: 'string',
  required: false,
  nullable: false,
  serverManaged: false,
  ...overrides,
})

const meta: CrudTableMeta = {
  key: 'demo/widgets',
  schema: 'demo',
  table: 'widgets',
  basePath: '/v1/demo/widgets',
  itemPath: '/v1/demo/widgets/{id}',
  pkParams: ['id'],
  exposure: 'owner',
  columns: [
    col('id', { serverManaged: true }),
    col('name'),
    col('config', { type: 'object' }),
    col('a'),
    col('b'),
    col('c'),
    col('d'),
    col('e'),
  ],
}

const noHandlers = { canWrite: true, onNew: vi.fn(), onEdit: vi.fn(), onDelete: vi.fn() }

describe('displayColumns', () => {
  it('puts the primary key first, skips object columns, caps the count', () => {
    const names = displayColumns(meta).map((c) => c.name)
    expect(names[0]).toBe('id')
    expect(names).not.toContain('config')
    expect(names.length).toBe(6)
  })
})

describe('cellText', () => {
  it('renders null as an em dash and truncates long values', () => {
    expect(cellText({ name: null }, col('name'))).toBe('—')
    expect(cellText({ name: 'x'.repeat(100) }, col('name'))).toBe(`${'x'.repeat(80)}…`)
    expect(cellText({ active: false }, col('active', { type: 'boolean' }))).toBe('false')
  })
})

describe('CrudTable', () => {
  it('shows the loading state', () => {
    render(<CrudTable meta={meta} rows={[]} loading error={null} {...noHandlers} />)
    expect(screen.getByText('Loading…')).toBeInTheDocument()
  })

  it('shows the empty state', () => {
    render(<CrudTable meta={meta} rows={[]} loading={false} error={null} {...noHandlers} />)
    expect(screen.getByText('No rows yet.')).toBeInTheDocument()
  })

  it('shows a load error', () => {
    render(
      <CrudTable meta={meta} rows={[]} loading={false} error="Service unavailable" {...noHandlers} />,
    )
    expect(screen.getByRole('alert')).toHaveTextContent('Service unavailable')
  })

  it('renders rows and routes New/Edit/Delete to the callbacks', async () => {
    const user = userEvent.setup()
    const onNew = vi.fn()
    const onEdit = vi.fn()
    const onDelete = vi.fn()
    const rows = [{ id: 'w1', name: 'Widget one' }]
    render(
      <CrudTable
        meta={meta}
        rows={rows}
        loading={false}
        error={null}
        canWrite
        onNew={onNew}
        onEdit={onEdit}
        onDelete={onDelete}
      />,
    )
    expect(screen.getByText('Widget one')).toBeInTheDocument()
    expect(screen.getByText('1 row')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'New' }))
    expect(onNew).toHaveBeenCalled()
    await user.click(screen.getByRole('button', { name: 'Edit' }))
    expect(onEdit).toHaveBeenCalledWith(rows[0])
    await user.click(screen.getByRole('button', { name: 'Delete' }))
    expect(onDelete).toHaveBeenCalledWith(rows[0])
  })

  // The write-side gate the feature pages rely on: `billing` is catalog end to end, so a
  // non-admin gets this branch on every one of its tables.
  it('drops New and Delete and turns Edit into View when the viewer may not write', async () => {
    const user = userEvent.setup()
    const onEdit = vi.fn()
    const rows = [{ id: 'w1', name: 'Widget one' }]
    render(
      <CrudTable
        meta={meta}
        rows={rows}
        loading={false}
        error={null}
        canWrite={false}
        onNew={vi.fn()}
        onEdit={onEdit}
        onDelete={vi.fn()}
      />,
    )
    expect(screen.queryByRole('button', { name: 'New' })).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Delete' })).not.toBeInTheDocument()
    // The row is still reachable — read access is what the catalog tier grants.
    expect(screen.getByText('Read-only')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'View' }))
    expect(onEdit).toHaveBeenCalledWith(rows[0])
  })
})

describe('crud-table conformance vectors', () => {
  const base = { meta, rows: [] as Record<string, unknown>[], loading: false, error: null, ...noHandlers }
  const manyMeta: CrudTableMeta = {
    ...meta,
    pkParams: ['id', 'id2'],
    columns: [col('id'), col('id2'), col('name'), col('a'), col('b'), col('c'), col('d'), col('config', { type: 'object' })],
  }
  const headers = (): string[] =>
    screen.getAllByRole('columnheader').map((h) => h.textContent ?? '')

  it('T1 render-pk-then-scalar-columns, cap-columns: 2 pk then 4 scalars, object column absent', () => {
    render(<CrudTable {...base} meta={manyMeta} rows={[{ id: '1', id2: '2' }]} />)
    expect(headers()).toEqual(['id', 'id2', 'name', 'a', 'b', 'c', ''])
    expect(screen.queryByText('config')).toBeNull()
    expect(displayColumns(manyMeta)).toHaveLength(6)
  })

  it('T2 header-columns-by-name: header text is the column name', () => {
    const m: CrudTableMeta = { ...meta, columns: [col('id'), col('createdAt')] }
    render(<CrudTable {...base} meta={m} rows={[{ id: '1' }]} />)
    expect(screen.getByRole('columnheader', { name: 'createdAt' })).toHaveTextContent('createdAt')
  })

  it('T3 format-null-cells: a null cell renders an em dash', () => {
    render(<CrudTable {...base} rows={[{ id: 'w1', status: null, name: null }]} />)
    expect(screen.getAllByText('—').length).toBeGreaterThan(0)
  })

  it('T4 stringify-non-string-cells: a number cell renders its JSON form', () => {
    expect(cellText({ count: 3 }, col('count', { type: 'integer' }))).toBe('3')
    const m: CrudTableMeta = { ...meta, columns: [col('id'), col('count', { type: 'integer' })] }
    render(<CrudTable {...base} meta={m} rows={[{ id: 'w1', count: 3 }]} />)
    expect(screen.getByText('3')).toBeInTheDocument()
  })

  it('T5 truncate-long-cells: a 200-char cell shows 80 chars and an ellipsis', () => {
    const long = 'y'.repeat(200)
    render(<CrudTable {...base} rows={[{ id: 'w1', name: long }]} />)
    expect(screen.getByText(`${'y'.repeat(80)}…`)).toBeInTheDocument()
  })

  it('T6 show-loading-state: spinner in the body and count reads Loading…', () => {
    render(<CrudTable {...base} loading />)
    expect(screen.getByRole('status', { name: 'Loading' })).toBeInTheDocument()
    expect(screen.getByText('Loading…')).toBeInTheDocument()
  })

  it('T7 show-error: the error text is shown through ErrorText', () => {
    render(<CrudTable {...base} error="Boom" />)
    expect(screen.getByRole('alert')).toHaveTextContent('Boom')
  })

  it('T8 show-empty-state: No rows yet. and no table', () => {
    render(<CrudTable {...base} />)
    expect(screen.getByText('No rows yet.')).toBeInTheDocument()
    expect(screen.queryByRole('table')).toBeNull()
  })

  it('T9 offer-new-action: New calls onNew', async () => {
    const onNew = vi.fn()
    render(<CrudTable {...base} onNew={onNew} />)
    await userEvent.setup().click(screen.getByRole('button', { name: 'New' }))
    expect(onNew).toHaveBeenCalledTimes(1)
  })

  it('T10 offer-per-row-edit-delete: Edit and Delete receive that row', async () => {
    const user = userEvent.setup()
    const onEdit = vi.fn()
    const onDelete = vi.fn()
    const rows = [{ id: 'a', name: 'A' }, { id: 'b', name: 'B' }]
    render(<CrudTable {...base} rows={rows} onEdit={onEdit} onDelete={onDelete} />)
    await user.click(screen.getAllByRole('button', { name: 'Edit' })[1]!)
    await user.click(screen.getAllByRole('button', { name: 'Delete' })[0]!)
    expect(onEdit).toHaveBeenCalledWith(rows[1])
    expect(onDelete).toHaveBeenCalledWith(rows[0])
  })

  it('T11 show-row-count: one row reads "1 row"', () => {
    render(<CrudTable {...base} rows={[{ id: 'a' }]} />)
    expect(screen.getByText('1 row')).toBeInTheDocument()
  })

  it('T12 show-row-count: three rows read "3 rows"', () => {
    render(<CrudTable {...base} rows={[{ id: 'a' }, { id: 'b' }, { id: 'c' }]} />)
    expect(screen.getByText('3 rows')).toBeInTheDocument()
  })

  it('T13 show-row-count, show-empty-state: 0 rows count beside the empty body', () => {
    render(<CrudTable {...base} />)
    expect(screen.getByText('0 rows')).toBeInTheDocument()
    expect(screen.getByText('No rows yet.')).toBeInTheDocument()
  })

  it('T14 body-precedence: loading shows the spinner and the error line together', () => {
    render(<CrudTable {...base} loading error="Boom" rows={[{ id: 'a' }]} />)
    expect(screen.getByRole('status', { name: 'Loading' })).toBeInTheDocument()
    expect(screen.getByRole('alert')).toHaveTextContent('Boom')
    expect(screen.queryByRole('table')).toBeNull()
  })

  it('T15 retain-rows-on-error: rows still render under an error, no empty placeholder', () => {
    render(<CrudTable {...base} error="Boom" rows={[{ id: 'a', name: 'Kept' }]} />)
    expect(screen.getByRole('table')).toBeInTheDocument()
    expect(screen.getByText('Kept')).toBeInTheDocument()
    expect(screen.queryByText('No rows yet.')).toBeNull()
  })

  it('T16 cap-columns: 8 pk columns and no scalars show only the first 6', () => {
    const names = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8']
    const m: CrudTableMeta = { ...meta, pkParams: names, columns: names.map((n) => col(n)) }
    expect(displayColumns(m).map((c) => c.name)).toEqual(names.slice(0, 6))
    render(<CrudTable {...base} meta={m} rows={[{ p1: 1 }]} />)
    expect(headers()).toEqual([...names.slice(0, 6), ''])
  })

  it('T17 composite-row-key: pk values are URI-encoded and joined with /', () => {
    const m: CrudTableMeta = { ...meta, pkParams: ['orgId', 'userId'] }
    expect(rowKey(m, { orgId: 'a/b', userId: 'c' })).toBe('a%2Fb/c')
  })

  it('T18 composite-row-key: no pkParams gives an empty key, so rows fall back to their index', () => {
    const m: CrudTableMeta = { ...meta, pkParams: [], columns: [col('name')] }
    expect(rowKey(m, { name: 'x' })).toBe('')
    const err = vi.spyOn(console, 'error').mockImplementation(() => undefined)
    render(<CrudTable {...base} meta={m} rows={[{ name: 'x' }, { name: 'y' }]} />)
    expect(screen.getByText('x')).toBeInTheDocument()
    expect(screen.getByText('y')).toBeInTheDocument()
    expect(err).not.toHaveBeenCalled()
    err.mockRestore()
  })

  it('T19 offer-per-row-edit-delete: Delete calls onDelete directly, with no dialog', async () => {
    const onDelete = vi.fn()
    const rows = [{ id: 'a' }]
    render(<CrudTable {...base} rows={rows} onDelete={onDelete} />)
    await userEvent.setup().click(screen.getByRole('button', { name: 'Delete' }))
    expect(onDelete).toHaveBeenCalledWith(rows[0])
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(screen.queryByRole('alertdialog')).toBeNull()
  })

  it('T20 label-row-actions-header: trailing th has aria-label and no text', () => {
    render(<CrudTable {...base} rows={[{ id: 'a' }]} />)
    const th = screen.getByRole('columnheader', { name: 'Row actions' })
    expect(th).toHaveAttribute('aria-label', 'Row actions')
    expect(th.textContent).toBe('')
  })

  it('T21 truncate-long-cells: exactly 80 chars is not truncated', () => {
    const exact = 'z'.repeat(80)
    expect(cellText({ name: exact }, col('name'))).toBe(exact)
    render(<CrudTable {...base} rows={[{ id: 'a', name: exact }]} />)
    expect(screen.getByText(exact)).toBeInTheDocument()
  })

  it('T22 displayColumns and cellText are callable pure functions', () => {
    expect(typeof displayColumns).toBe('function')
    expect(typeof cellText).toBe('function')
    expect(displayColumns(meta)[0]!.name).toBe('id')
    expect(cellText({ name: null }, col('name'))).toBe('—')
  })

  it('T23 read-only-mode: no New or Delete, a Read-only badge, default note, View calls onEdit', async () => {
    const onEdit = vi.fn()
    const rows = [{ id: 'a' }]
    render(<CrudTable {...base} canWrite={false} rows={rows} onEdit={onEdit} />)
    expect(screen.queryByRole('button', { name: 'New' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Delete' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Edit' })).toBeNull()
    expect(screen.getByText('Read-only')).toBeInTheDocument()
    expect(
      screen.getByText('Shared platform data — only an administrator can change it.'),
    ).toBeInTheDocument()
    await userEvent.setup().click(screen.getByRole('button', { name: 'View' }))
    expect(onEdit).toHaveBeenCalledWith(rows[0])
  })

  it('T24 read-only-mode: readOnlyNote replaces the default note', () => {
    render(<CrudTable {...base} canWrite={false} readOnlyNote="Papers are curated." />)
    expect(screen.getByText('Papers are curated.')).toBeInTheDocument()
    expect(screen.queryByText(/only an administrator/)).toBeNull()
  })

  it('T25 offer-new-action, offer-per-row-edit-delete: writable shows New, Edit and Delete', () => {
    render(<CrudTable {...base} rows={[{ id: 'a' }, { id: 'b' }]} />)
    expect(screen.getByRole('button', { name: 'New' })).toBeInTheDocument()
    expect(screen.getAllByRole('button', { name: 'Edit' })).toHaveLength(2)
    expect(screen.getAllByRole('button', { name: 'Delete' })).toHaveLength(2)
  })

  it('T26 minimum-contrast-ratio: text uses apt-* token classes with no inline color adjustment', () => {
    const { container } = render(<CrudTable {...base} rows={[{ id: 'a', name: 'N' }]} />)
    expect(screen.getByText('N').className).toContain('text-apt-text')
    expect(screen.getByRole('columnheader', { name: 'id' }).className).toContain('text-apt-text-muted')
    expect(screen.getByText('1 row').className).toContain('text-apt-text-dim')
    expect(container.querySelectorAll('[style]')).toHaveLength(0)
  })
})
