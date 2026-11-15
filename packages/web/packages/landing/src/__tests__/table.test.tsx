import type { ReactElement } from 'react'
import { describe, expect, it, vi } from 'vitest'
import { render } from '@testing-library/react'
import { Table } from '../index'

function renderThrowing(el: ReactElement): Error {
  const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
  try {
    render(el)
  } catch (e) {
    return e as Error
  } finally {
    spy.mockRestore()
  }
  throw new Error('expected render to throw')
}

describe('Table conformance vectors', () => {
  it('table-001 caption-required, columns-prop, rows-prop: caption hidden, two data rows', () => {
    const { container } = render(
      <Table
        caption="Run Results"
        columns={['Date', 'Status']}
        rows={[['2026-09-22', 'Pass'], ['2026-09-21', 'Fail']]}
      />,
    )
    const cap = container.querySelector('caption')!
    expect(cap.textContent).toBe('Run Results')
    expect(cap.className).toBe('lp-sr-only')
    expect(container.querySelectorAll('tbody tr')).toHaveLength(2)
  })

  it('table-002 column-headers-scoped: thead has th scope=col per column', () => {
    const { container } = render(<Table caption="c" columns={['Name', 'Role']} rows={[]} />)
    const ths = container.querySelectorAll('thead > tr > th')
    expect(Array.from(ths).map((t) => t.textContent)).toEqual(['Name', 'Role'])
    ths.forEach((t) => expect(t.getAttribute('scope')).toBe('col'))
  })

  it('table-003 tbody-rows: each row has a td per cell', () => {
    const { container } = render(
      <Table caption="c" columns={['Name', 'Role']} rows={[['Alice', 'Engineer'], ['Bob', 'Designer']]} />,
    )
    const trs = container.querySelectorAll('tbody > tr')
    expect(trs).toHaveLength(2)
    expect(Array.from(trs[0].querySelectorAll('td')).map((t) => t.textContent)).toEqual(['Alice', 'Engineer'])
    expect(Array.from(trs[1].querySelectorAll('td')).map((t) => t.textContent)).toEqual(['Bob', 'Designer'])
  })

  it('table-004 row-width-validation: short row throws with index, cells and columns', () => {
    const err = renderThrowing(<Table caption="c" columns={['A', 'B']} rows={[['1', '2'], ['3']]} />)
    expect(err.message).toBe('Table: row 1 has 1 cells but there are 2 columns')
  })

  it('table-005 caption-hidden-by-default: caption has lp-sr-only', () => {
    const { container } = render(<Table caption="Revenue" columns={['A']} rows={[['1']]} />)
    expect(container.querySelector('caption')!.getAttribute('class')).toBe('lp-sr-only')
  })

  it('table-006 visible-caption-option: showCaption drops lp-sr-only', () => {
    const { container } = render(<Table caption="Revenue" showCaption={true} columns={['A']} rows={[['1']]} />)
    const cap = container.querySelector('caption')!
    expect(cap.classList.contains('lp-sr-only')).toBe(false)
    expect(cap.textContent).toBe('Revenue')
  })

  it('table-007 scroll-container, table-class: wrapper and table classes', () => {
    const { container } = render(<Table caption="c" columns={['A']} rows={[['1']]} />)
    const wrap = container.firstElementChild!
    expect(wrap.tagName).toBe('DIV')
    expect(wrap.className).toBe('lp-table-scroll')
    expect(wrap.querySelector(':scope > table')!.className).toBe('lp-table')
  })

  it('table-008 row-width-validation: matching row does not throw', () => {
    const { container } = render(<Table caption="c" columns={['X', 'Y', 'Z']} rows={[['1', '2', '3']]} />)
    expect(Array.from(container.querySelectorAll('tbody td')).map((t) => t.textContent)).toEqual(['1', '2', '3'])
  })

  it('table-009 rows-prop: empty rows keep headers, no tbody rows', () => {
    const { container } = render(<Table caption="c" columns={['Name', 'Role']} rows={[]} />)
    expect(container.querySelectorAll('tbody tr')).toHaveLength(0)
    expect(container.querySelectorAll('thead th[scope="col"]')).toHaveLength(2)
  })

  it('table-010 columns-prop, row-width-validation: empty columns and rows', () => {
    const { container } = render(<Table caption="c" columns={[]} rows={[]} />)
    expect(container.querySelectorAll('thead > tr')).toHaveLength(1)
    expect(container.querySelectorAll('thead th')).toHaveLength(0)
    expect(container.querySelectorAll('tbody tr')).toHaveLength(0)
  })

  it('table-011 tbody-rows: null cell renders an empty td', () => {
    const { container } = render(<Table caption="c" columns={['A', 'B']} rows={[[null, 'x']]} />)
    const tds = container.querySelectorAll('tbody td')
    expect(tds).toHaveLength(2)
    expect(tds[0].textContent).toBe('')
    expect(tds[1].textContent).toBe('x')
  })

  it('table-012 tbody-rows, columns-prop: ReactNode content rendered as given', () => {
    const { container } = render(
      <Table
        caption="c"
        columns={['Name', <strong key="s">Status</strong>]}
        rows={[['Alice', <span key="a">Active</span>]]}
      />,
    )
    expect(container.querySelector('thead th strong')!.textContent).toBe('Status')
    expect(container.querySelector('tbody td span')!.textContent).toBe('Active')
  })

  it('table-013 reports-first-mismatched-row, row-width-validation: reports row 1, not 2', () => {
    const err = renderThrowing(
      <Table caption="c" columns={['A', 'B']} rows={[['1', '2'], ['3'], ['4', '5', '6']]} />,
    )
    expect(err.message).toBe('Table: row 1 has 1 cells but there are 2 columns')
  })

  it('table-014 row-width-validation, columns-prop: no columns, one-cell row throws', () => {
    const err = renderThrowing(<Table caption="c" columns={[]} rows={[['x']]} />)
    expect(err.message).toBe('Table: row 0 has 1 cells but there are 0 columns')
  })

  it('table-015 row-width-validation: too-long row throws', () => {
    const err = renderThrowing(<Table caption="c" columns={['A']} rows={[['1', '2']]} />)
    expect(err.message).toBe('Table: row 0 has 2 cells but there are 1 columns')
  })
})
