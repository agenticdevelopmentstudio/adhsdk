/**
 * `CategoriesAndTags` conformance vectors cat-tag-001 .. cat-tag-014.
 *
 * The composition vectors replace `CategoryField` and `TagSetField` with probes that record
 * the props they were handed, so each vector can say what the block forwards. The focus
 * vector switches the probes to the real fields.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import * as React from 'react'
import { render, screen, cleanup } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'

const seen = vi.hoisted(() => ({
  category: [] as Array<Record<string, unknown>>,
  tags: [] as Array<Record<string, unknown>>,
  real: false,
}))

vi.mock('../blocks/category-field', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../blocks/category-field')>()
  return {
    ...actual,
    CategoryField: (props: Record<string, unknown>) => {
      if (seen.real) return React.createElement(actual.CategoryField, props as never)
      seen.category.push(props)
      return <div data-testid="category-field" />
    },
  }
})
vi.mock('../blocks/tag-set-field', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../blocks/tag-set-field')>()
  return {
    ...actual,
    TagSetField: (props: Record<string, unknown>) => {
      if (seen.real) return React.createElement(actual.TagSetField, props as never)
      seen.tags.push(props)
      return <div data-testid="tag-set-field" />
    },
  }
})

import { CategoriesAndTags } from '../blocks/categories-and-tags'
import { FIELD_LABEL_GROUP_CLASS } from '../blocks/field'
import type { CategoryTreeNode } from '../blocks/category-tree'

type Props = React.ComponentProps<typeof CategoriesAndTags>

const onCategoryChange = vi.fn()
const onTagsChange = vi.fn()

function base(): Props {
  return {
    category: {
      label: 'Type',
      noun: 'type',
      options: ['A', 'B'],
      value: 'A',
      onChange: onCategoryChange,
    },
    tags: {
      label: 'Tags',
      noun: 'tag',
      options: ['x', 'y'],
      value: ['x'],
      onChange: onTagsChange,
    },
  }
}

function lastCategory(): Record<string, unknown> {
  return seen.category[seen.category.length - 1]!
}
function lastTags(): Record<string, unknown> {
  return seen.tags[seen.tags.length - 1]!
}
function root(container: HTMLElement): HTMLElement {
  return container.querySelector('[data-slot="categories-and-tags"]') as HTMLElement
}

beforeEach(() => {
  seen.category.length = 0
  seen.tags.length = 0
  seen.real = false
})
afterEach(cleanup)

describe('CategoriesAndTags conformance vectors', () => {
  it('cat-tag-001: root carries data-slot and holds CategoryField before TagSetField', () => {
    const { container } = render(<CategoriesAndTags {...base()} />)
    const el = root(container)
    expect(el).not.toBeNull()
    const a = screen.getByTestId('category-field')
    const b = screen.getByTestId('tag-set-field')
    expect(el).toContainElement(a)
    expect(el).toContainElement(b)
    expect(a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    expect(lastCategory().layout).toBe('inline')
    expect(lastTags().layout).toBe('inline')
  })

  it('cat-tag-002: root class list carries FIELD_LABEL_GROUP_CLASS, not an inline style', () => {
    const { container } = render(<CategoriesAndTags {...base()} />)
    const el = root(container)
    expect(FIELD_LABEL_GROUP_CLASS).toBe('[--apt-field-label-w:6.5rem]')
    expect(el.classList.contains('[--apt-field-label-w:6.5rem]')).toBe(true)
    expect(el.getAttribute('style')).toBeNull()
  })

  it('cat-tag-003: CategoryField receives label, noun, options, value and the same onChange', () => {
    render(<CategoriesAndTags {...base()} />)
    const p = lastCategory()
    expect(p.label).toBe('Type')
    expect(p.noun).toBe('type')
    expect(p.options).toEqual(['A', 'B'])
    expect(p.value).toBe('A')
    expect(p.onChange).toBe(onCategoryChange)
  })

  it('cat-tag-004: CategoryField receives the same nodes array reference', () => {
    const nodes: CategoryTreeNode[] = [{ id: 'a', name: 'A', parentIds: [] }]
    const props = base()
    props.category.nodes = nodes
    render(<CategoriesAndTags {...props} />)
    expect(lastCategory().nodes).toBe(nodes)
  })

  it('cat-tag-005: CategoryField receives the same onRename reference', () => {
    const onRename = vi.fn()
    const props = base()
    props.category.onRename = onRename
    render(<CategoriesAndTags {...props} />)
    expect(lastCategory().onRename).toBe(onRename)
  })

  it('cat-tag-006: TagSetField receives label, noun, options, value and the same onChange', () => {
    render(<CategoriesAndTags {...base()} />)
    const p = lastTags()
    expect(p.label).toBe('Tags')
    expect(p.noun).toBe('tag')
    expect(p.options).toEqual(['x', 'y'])
    expect(p.value).toEqual(['x'])
    expect(p.onChange).toBe(onTagsChange)
  })

  it('cat-tag-007: disabled=true reaches both fields', () => {
    render(<CategoriesAndTags {...base()} disabled />)
    expect(lastCategory().disabled).toBe(true)
    expect(lastTags().disabled).toBe(true)
  })

  it('cat-tag-008: className is merged alongside the component classes', () => {
    const { container } = render(<CategoriesAndTags {...base()} className="custom-class" />)
    const el = root(container)
    expect(el.classList.contains('custom-class')).toBe(true)
    expect(el.classList.contains('flex')).toBe(true)
    expect(el.classList.contains('[--apt-field-label-w:6.5rem]')).toBe(true)
  })

  it('cat-tag-009: root spaces the rows with gap-3', () => {
    const { container } = render(<CategoriesAndTags {...base()} />)
    const el = root(container)
    expect(el.classList.contains('gap-3')).toBe(true)
    expect(el.classList.contains('flex-col')).toBe(true)
  })

  it.skip('cat-tag-010: omitting category.label or category.noun is a compile-time error', () => {
    // Compile-time only: vitest cannot assert a type error. The directives below are checked by
    // `tsc --noEmit` (an unused @ts-expect-error fails the build), so the vector is enforced there.
    const noLabel: Props = {
      ...base(),
      // @ts-expect-error label is required
      category: { noun: 'type', options: [], value: '', onChange: () => {} },
    }
    const noNoun: Props = {
      ...base(),
      // @ts-expect-error noun is required
      category: { label: 'Type', options: [], value: '', onChange: () => {} },
    }
    void noLabel
    void noNoun
  })

  it.skip('cat-tag-011: omitting tags.label or tags.noun is a compile-time error', () => {
    // Compile-time only; see cat-tag-010. Enforced by `tsc --noEmit` via @ts-expect-error.
    const noLabel: Props = {
      ...base(),
      // @ts-expect-error label is required
      tags: { noun: 'tag', options: [], value: [], onChange: () => {} },
    }
    const noNoun: Props = {
      ...base(),
      // @ts-expect-error noun is required
      tags: { label: 'Tags', options: [], value: [], onChange: () => {} },
    }
    void noLabel
    void noNoun
  })

  it('cat-tag-012: tabbing in from outside lands on the category row before the tags row', async () => {
    seen.real = true
    const user = userEvent.setup()
    render(
      <div>
        <button type="button">before</button>
        <CategoriesAndTags {...base()} />
      </div>,
    )
    screen.getByRole('button', { name: 'before' }).focus()
    await user.tab()
    const first = document.activeElement as HTMLElement
    const category = screen.getByRole('combobox', { name: 'Type' })
    const tagInput = screen.getByRole('combobox', { name: 'Add a tag' })
    expect(first).toBe(category)
    expect(
      category.compareDocumentPosition(tagInput) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy()
  })

  it('cat-tag-013: disabled omitted reaches both fields as false', () => {
    render(<CategoriesAndTags {...base()} />)
    expect(lastCategory().disabled).toBe(false)
    expect(lastTags().disabled).toBe(false)
  })

  it('cat-tag-014: a host label-width class replaces the default one', () => {
    const { container } = render(
      <CategoriesAndTags {...base()} className="[--apt-field-label-w:9rem]" />,
    )
    const el = root(container)
    expect(el.classList.contains('[--apt-field-label-w:9rem]')).toBe(true)
    expect(el.classList.contains('[--apt-field-label-w:6.5rem]')).toBe(false)
  })
})
