/** Conformance tests for List / ListItem (list-001..list-008). */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { List, ListItem } from '../components/list'

describe('List conformance vectors', () => {
  it('list-001 renders a ul with data-slot="list"', () => {
    const { container } = render(<List />)
    const el = container.firstElementChild as HTMLElement
    expect(el.tagName).toBe('UL')
    expect(el).toHaveAttribute('data-slot', 'list')
  })

  it('list-002 renders an li with data-slot="list-item"', () => {
    const { container } = render(<ul><ListItem /></ul>)
    const el = container.querySelector('li') as HTMLElement
    expect(el).toHaveAttribute('data-slot', 'list-item')
  })

  it('list-003 List merges className with base classes', () => {
    const { container } = render(<List className="custom-class" />)
    const el = container.firstElementChild as HTMLElement
    expect(el).toHaveClass('custom-class', 'flex', 'flex-col', 'border', 'rounded-lg')
  })

  it('list-004 ListItem merges className with base classes', () => {
    const { container } = render(<ul><ListItem className="custom-item" /></ul>)
    const el = container.querySelector('li') as HTMLElement
    expect(el).toHaveClass('custom-item', 'flex', 'items-center', 'gap-3')
  })

  it('list-005 List forwards id and role', () => {
    const { container } = render(<List id="test-list" role="region" />)
    const el = container.firstElementChild as HTMLElement
    expect(el).toHaveAttribute('id', 'test-list')
    expect(el).toHaveAttribute('role', 'region')
  })

  it('list-006 ListItem forwards id and data attributes', () => {
    const { container } = render(<ul><ListItem id="item-1" data-test="value" /></ul>)
    const el = container.querySelector('li') as HTMLElement
    expect(el).toHaveAttribute('id', 'item-1')
    expect(el).toHaveAttribute('data-test', 'value')
  })

  it('list-007 ListItem className px-6 replaces conflicting px-3', () => {
    const { container } = render(<ul><ListItem className="px-6" /></ul>)
    const el = container.querySelector('li') as HTMLElement
    expect(el).toHaveClass('px-6')
    expect(el).not.toHaveClass('px-3')
  })

  it('list-008 data-slot prop overrides the default', () => {
    const { container } = render(<List data-slot="custom" />)
    const el = container.firstElementChild as HTMLElement
    expect(el).toHaveAttribute('data-slot', 'custom')
  })
})
