/// <reference types="@testing-library/jest-dom/vitest" />
import { afterEach, describe, it, expect, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { FilteredList } from '../FilteredList'

type Service = { id: string; name: string; baseUrl: string }

const services: Service[] = [
  { id: '1', name: 'Groq', baseUrl: 'https://api.groq.com/openai/v1' },
  { id: '2', name: 'OpenAI', baseUrl: 'https://api.openai.com/v1' },
  { id: '3', name: 'Anthropic', baseUrl: 'https://api.anthropic.com/v1' },
]

function setup(extra: Partial<React.ComponentProps<typeof FilteredList<Service>>> = {}) {
  const onSelect = vi.fn()
  const onHighlightChange = vi.fn()
  render(
    <FilteredList<Service>
      items={services}
      getId={(s) => s.id}
      getTitle={(s) => s.name}
      getDetails={(s) => s.baseUrl}
      onSelect={onSelect}
      onHighlightChange={onHighlightChange}
      {...extra}
    />,
  )
  return {
    input: screen.getByRole('combobox') as HTMLInputElement,
    onSelect,
    onHighlightChange,
  }
}

describe('FilteredList keyboard nav', () => {
  it('ArrowDown from empty highlight selects first item and fills input with its title', () => {
    const { input } = setup()
    expect(input.value).toBe('')
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    expect(input.value).toBe('Groq')
  })

  it('ArrowDown moves down through visible items', () => {
    const { input } = setup()
    fireEvent.keyDown(input, { key: 'ArrowDown' }) // Groq
    fireEvent.keyDown(input, { key: 'ArrowDown' }) // OpenAI
    expect(input.value).toBe('OpenAI')
  })

  it('ArrowUp moves up; from index 0 it clears the highlight back to the typed query', () => {
    const { input } = setup()
    fireEvent.change(input, { target: { value: 'a' } }) // filters to Anthropic + Groq + OpenAI? all contain 'a' lowercased
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    expect(input.value).not.toBe('a')
    fireEvent.keyDown(input, { key: 'ArrowUp' })
    expect(input.value).toBe('a')
  })

  it('Enter fires onSelect with the highlighted item', () => {
    const { input, onSelect } = setup()
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect.mock.calls[0][0]).toMatchObject({ id: '2', name: 'OpenAI' })
  })

  it('Enter without a highlight does not fire onSelect', () => {
    const { input, onSelect } = setup()
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('typing while highlighted clears the highlight and resumes filtering', () => {
    const { input } = setup()
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    expect(input.value).toBe('Groq')
    fireEvent.change(input, { target: { value: 'Anth' } })
    expect(input.value).toBe('Anth')
    // Only Anthropic matches.
    expect(screen.getAllByRole('option')).toHaveLength(1)
  })

  it('onHighlightChange fires with the item, then null when cleared', () => {
    const { input, onHighlightChange } = setup()
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    fireEvent.keyDown(input, { key: 'Escape' })
    const calls = onHighlightChange.mock.calls.map((c) => c[0])
    expect(calls).toContainEqual(expect.objectContaining({ id: '1' }))
    expect(calls).toContain(null)
  })

  it('clicking a row fires onSelect', () => {
    const { onSelect } = setup()
    fireEvent.click(screen.getByRole('button', { name: /OpenAI/ }))
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect.mock.calls[0][0]).toMatchObject({ id: '2' })
  })
})

type Fruit = { id: string; title: string; sub?: string; det?: string; extra?: string }

const fruits: Fruit[] = [
  { id: 'a', title: 'Apple', sub: 'red fruit', det: 'crunchy', extra: 'malus' },
  { id: 'b', title: 'Banana', sub: 'yellow fruit', det: 'soft', extra: 'musa' },
  { id: 'c', title: 'Cherry', sub: 'small fruit', det: 'sweet' },
  { id: 'd', title: 'Date', sub: 'brown fruit', det: 'sticky' },
  { id: 'e', title: 'Elderberry', sub: 'dark fruit', det: 'tart' },
]

type FruitProps = React.ComponentProps<typeof FilteredList<Fruit>>

function fruitList(extra: Partial<FruitProps> = {}): FruitProps {
  return {
    items: fruits,
    getId: (f) => f.id,
    getTitle: (f) => f.title,
    getSubtitle: (f) => f.sub,
    getDetails: (f) => f.det,
    getSearchableExtras: (f) => [f.extra],
    ...extra,
  }
}

function mount(extra: Partial<FruitProps> = {}) {
  const view = render(<FilteredList<Fruit> {...fruitList(extra)} />)
  const input = screen.getByRole('combobox') as HTMLInputElement
  const options = () => screen.queryAllByRole('option')
  const selected = () => options().filter((o) => o.getAttribute('aria-selected') === 'true')
  const down = () => fireEvent.keyDown(input, { key: 'ArrowDown' })
  return { ...view, input, options, selected, down }
}

describe('FilteredList conformance', () => {
  it('filtered-list-001 renders a text input with the placeholder "Filter…"', () => {
    const { input } = mount()
    expect(input.type).toBe('text')
    expect(input.placeholder).toBe('Filter…')
  })

  it('filtered-list-002 query filters on title, subtitle, details and extras, case-insensitively', () => {
    const { input, options } = mount()
    fireEvent.change(input, { target: { value: 'APPLE' } })
    expect(options().map((o) => o.textContent)).toEqual([expect.stringContaining('Apple')])
    fireEvent.change(input, { target: { value: 'yellow' } })
    expect(options()).toHaveLength(1)
    fireEvent.change(input, { target: { value: 'STICKY' } })
    expect(options()).toHaveLength(1)
    fireEvent.change(input, { target: { value: 'musa' } })
    expect(options()).toHaveLength(1)
    expect(options()[0].textContent).toContain('Banana')
  })

  it('filtered-list-003 ArrowDown with no highlight highlights the first item', () => {
    const { down, selected } = mount()
    down()
    expect(selected()).toHaveLength(1)
    expect(selected()[0].textContent).toContain('Apple')
  })

  it('filtered-list-004 ArrowDown on the first item highlights the second', () => {
    const { down, selected } = mount()
    down()
    down()
    expect(selected()[0].textContent).toContain('Banana')
  })

  it('filtered-list-005 ArrowDown on the last item keeps the highlight there', () => {
    const { down, selected } = mount()
    for (let i = 0; i < fruits.length + 3; i++) down()
    expect(selected()).toHaveLength(1)
    expect(selected()[0].textContent).toContain('Elderberry')
  })

  it('filtered-list-006 ArrowUp on the first item clears the highlight', () => {
    const { input, down, selected } = mount()
    down()
    fireEvent.keyDown(input, { key: 'ArrowUp' })
    expect(selected()).toHaveLength(0)
    expect(input).not.toHaveAttribute('aria-activedescendant')
  })

  it('filtered-list-007 ArrowUp on the second item highlights the first', () => {
    const { input, down, selected } = mount()
    down()
    down()
    fireEvent.keyDown(input, { key: 'ArrowUp' })
    expect(selected()[0].textContent).toContain('Apple')
  })

  it('filtered-list-008 Enter on a highlighted item calls onSelect with it', () => {
    const onSelect = vi.fn()
    const { input, down } = mount({ onSelect })
    down()
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect).toHaveBeenCalledWith(fruits[0])
  })

  it('filtered-list-009 Escape on a highlighted item clears the highlight and prevents default', () => {
    const { input, down, selected } = mount()
    down()
    const notPrevented = fireEvent.keyDown(input, { key: 'Escape' })
    expect(notPrevented).toBe(false)
    expect(selected()).toHaveLength(0)
  })

  it('filtered-list-010 typing resets the highlight', () => {
    const { input, down, selected } = mount()
    down()
    expect(selected()).toHaveLength(1)
    fireEvent.change(input, { target: { value: 'e' } })
    expect(selected()).toHaveLength(0)
    expect(input).not.toHaveAttribute('aria-activedescendant')
  })

  it('filtered-list-011 highlight clamps to the last item when the items prop shrinks', () => {
    const view = mount()
    for (let i = 0; i < 5; i++) view.down()
    expect(view.selected()[0].textContent).toContain('Elderberry')
    view.rerender(<FilteredList<Fruit> {...fruitList({ items: fruits.slice(0, 3) })} />)
    expect(view.options()).toHaveLength(3)
    expect(view.selected()).toHaveLength(1)
    expect(view.selected()[0].textContent).toContain('Cherry')
  })

  it('filtered-list-012 renders a role=listbox ul with every visible item as an li child', () => {
    const { options } = mount()
    const list = screen.getByRole('listbox')
    expect(list.tagName).toBe('UL')
    expect(options()).toHaveLength(fruits.length)
    options().forEach((o) => {
      expect(o.tagName).toBe('LI')
      expect(o.parentElement).toBe(list)
    })
  })

  it('filtered-list-013 default layout renders the title in an fl-title element', () => {
    const { container } = mount()
    const titles = Array.from(container.querySelectorAll('.fl-title')).map((t) => t.textContent)
    expect(titles).toEqual(fruits.map((f) => f.title))
  })

  it('filtered-list-014 default layout renders the subtitle in an fl-subtitle element', () => {
    const { container } = mount()
    const subs = Array.from(container.querySelectorAll('.fl-subtitle')).map((t) => t.textContent)
    expect(subs).toEqual(fruits.map((f) => f.sub))
  })

  it('filtered-list-015 each item wraps its content in a button when onSelect is provided', () => {
    const { options } = mount({ onSelect: () => {} })
    options().forEach((o) => {
      const btn = o.querySelector(':scope > button')
      expect(btn).not.toBeNull()
      expect(btn!.getAttribute('type')).toBe('button')
    })
  })

  it('filtered-list-016 hovering an item highlights it with aria-selected=true', () => {
    const { options } = mount()
    fireEvent.mouseEnter(options()[2])
    expect(options()[2]).toHaveAttribute('aria-selected', 'true')
    expect(options()[0]).toHaveAttribute('aria-selected', 'false')
  })

  describe('scroll', () => {
    afterEach(() => {
      delete (Element.prototype as { scrollIntoView?: unknown }).scrollIntoView
    })

    it('filtered-list-017 moving the highlight calls scrollIntoView({block:"nearest"}) on that item', () => {
      const spy = vi.fn()
      Object.defineProperty(Element.prototype, 'scrollIntoView', {
        value: spy,
        configurable: true,
        writable: true,
      })
      const { down, options } = mount()
      down()
      down()
      expect(spy).toHaveBeenLastCalledWith({ block: 'nearest' })
      expect(spy.mock.contexts.at(-1)).toBe(options()[1])
    })
  })

  it('filtered-list-018 the input shows the highlighted item title instead of the query', () => {
    const { input, down } = mount()
    fireEvent.change(input, { target: { value: 'fruit' } })
    down()
    expect(input.value).toBe('Apple')
  })

  it('filtered-list-019 aria-expanded is true when visible items exist', () => {
    const { input } = mount()
    expect(input).toHaveAttribute('aria-expanded', 'true')
  })

  it('filtered-list-020 aria-expanded is false when no items are visible', () => {
    const { input } = mount()
    fireEvent.change(input, { target: { value: 'zzz' } })
    expect(input).toHaveAttribute('aria-expanded', 'false')
  })

  it('filtered-list-021 aria-activedescendant matches the highlighted item id', () => {
    const { input, down, selected } = mount()
    down()
    expect(selected()[0].id).not.toBe('')
    expect(input.getAttribute('aria-activedescendant')).toBe(selected()[0].id)
  })

  it('filtered-list-022 item ids are unique and shaped {listId}-{itemId}', () => {
    const { options } = mount()
    const listId = screen.getByRole('listbox').id
    const ids = options().map((o) => o.id)
    expect(new Set(ids).size).toBe(fruits.length)
    expect(ids).toEqual(fruits.map((f) => `${listId}-${f.id}`))
  })

  it('filtered-list-023 a highlighted item has aria-selected=true', () => {
    const { down, options } = mount()
    down()
    expect(options()[0]).toHaveAttribute('aria-selected', 'true')
  })

  it('filtered-list-024 a non-highlighted item has aria-selected=false', () => {
    const { down, options } = mount()
    down()
    expect(options()[1]).toHaveAttribute('aria-selected', 'false')
    expect(options()[4]).toHaveAttribute('aria-selected', 'false')
  })

  it('filtered-list-025 onHighlightChange gets the new item, then null', () => {
    const onHighlightChange = vi.fn()
    const { input, down } = mount({ onHighlightChange })
    down()
    expect(onHighlightChange).toHaveBeenLastCalledWith(fruits[0])
    down()
    expect(onHighlightChange).toHaveBeenLastCalledWith(fruits[1])
    fireEvent.keyDown(input, { key: 'Escape' })
    expect(onHighlightChange).toHaveBeenLastCalledWith(null)
  })

  it('filtered-list-026 with zero items shows "No items." instead of the list', () => {
    mount({ items: [] })
    expect(screen.getByText('No items.')).toBeInTheDocument()
    expect(screen.queryByRole('listbox')).toBeNull()
  })

  it('filtered-list-027 emptyContent replaces the default no-matches message', () => {
    const { input } = mount({ emptyContent: <span>Nothing here</span> })
    fireEvent.change(input, { target: { value: 'zzz' } })
    expect(screen.getByText('Nothing here')).toBeInTheDocument()
    expect(screen.queryByText(/No matches for/)).toBeNull()
  })

  it('filtered-list-028 footer renders as the last list item', () => {
    mount({ footer: <span>+ Custom</span> })
    const items = Array.from(screen.getByRole('listbox').children)
    expect(items.at(-1)!.textContent).toBe('+ Custom')
    expect(items.at(-1)).toHaveClass('fl-footer')
  })

  it('filtered-list-029 the input is wrapped in a form with role=search', () => {
    const { input } = mount()
    const form = screen.getByRole('search')
    expect(form.tagName).toBe('FORM')
    expect(form.contains(input)).toBe(true)
  })

  it('filtered-list-030 form submission is prevented with or without a highlight', () => {
    const { down } = mount()
    const form = screen.getByRole('search')
    expect(fireEvent.submit(form)).toBe(false)
    down()
    expect(fireEvent.submit(form)).toBe(false)
  })

  it('filtered-list-031 the input carries the no-autofill attributes', () => {
    const { input } = mount()
    expect(input).toHaveAttribute('autocomplete', 'off')
    expect(input).toHaveAttribute('data-form-type', 'other')
    expect(input).toHaveAttribute('data-1p-ignore', 'true')
    expect(input).toHaveAttribute('data-lpignore', 'true')
    expect(input).toHaveAttribute('data-bwignore', 'true')
    expect(input).toHaveAttribute('data-protonpass-ignore', 'true')
  })

  it('filtered-list-032 autoFocus focuses the input on mount', () => {
    const { input } = mount({ autoFocus: true })
    expect(document.activeElement).toBe(input)
  })

  it('filtered-list-033 Escape with no highlight changes nothing and is not prevented', () => {
    const { input, selected } = mount()
    const notPrevented = fireEvent.keyDown(input, { key: 'Escape' })
    expect(notPrevented).toBe(true)
    expect(selected()).toHaveLength(0)
  })

  it('filtered-list-034 default layout renders details in an fl-details element', () => {
    const { container } = mount()
    const dets = Array.from(container.querySelectorAll('.fl-details')).map((t) => t.textContent)
    expect(dets).toEqual(fruits.map((f) => f.det))
  })

  it('filtered-list-035 renderItem output replaces the default title/subtitle/details layout', () => {
    const renderItem = vi.fn((f: Fruit) => <em data-testid="custom">{f.title.toUpperCase()}</em>)
    const { container } = mount({ renderItem })
    expect(renderItem).toHaveBeenCalledWith(fruits[0])
    expect(screen.getAllByTestId('custom')).toHaveLength(fruits.length)
    expect(container.querySelector('.fl-title')).toBeNull()
    expect(container.querySelector('.fl-subtitle')).toBeNull()
    expect(container.querySelector('.fl-details')).toBeNull()
  })

  it('filtered-list-036 with no visible items the keys do nothing and are not prevented', () => {
    const onSelect = vi.fn()
    const { input } = mount({ onSelect })
    fireEvent.change(input, { target: { value: 'zzz' } })
    for (const key of ['ArrowDown', 'ArrowUp', 'Enter', 'Escape']) {
      expect(fireEvent.keyDown(input, { key })).toBe(true)
    }
    expect(onSelect).not.toHaveBeenCalled()
    expect(input.value).toBe('zzz')
    expect(input).not.toHaveAttribute('aria-activedescendant')
  })

  it('filtered-list-037 default no-matches message is the list’s only item', () => {
    const { input } = mount()
    fireEvent.change(input, { target: { value: 'zzz' } })
    const items = Array.from(screen.getByRole('listbox').children)
    expect(items).toHaveLength(1)
    expect(items[0].textContent).toBe('No matches for “zzz”.')
  })

  it('filtered-list-038 every item li has role=option', () => {
    const { container } = mount()
    const lis = Array.from(container.querySelectorAll('ul > li'))
    expect(lis).toHaveLength(fruits.length)
    lis.forEach((li) => expect(li).toHaveAttribute('role', 'option'))
  })

  it('filtered-list-039 Enter with no highlight does not call onSelect; submit is still prevented', () => {
    const onSelect = vi.fn()
    const { input } = mount({ onSelect })
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).not.toHaveBeenCalled()
    expect(fireEvent.submit(screen.getByRole('search'))).toBe(false)
  })

  it('filtered-list-040 initialQuery sets the input value and filters on first render', () => {
    const { input, options } = mount({ initialQuery: 'app' })
    expect(input.value).toBe('app')
    expect(options()).toHaveLength(1)
    expect(options()[0].textContent).toContain('Apple')
  })

  it('filtered-list-041 className is added to the fl-root element', () => {
    const { container } = mount({ className: 'extra' })
    const root = container.firstElementChild as HTMLElement
    expect(root).toHaveClass('fl-root', 'extra')
    expect(root.className).toBe('fl-root extra')
  })

  it('filtered-list-042 custom match is used with the lower-cased, trimmed query', () => {
    const match = vi.fn((item: Fruit) => item.id === 'b')
    const { input, options } = mount({ match })
    fireEvent.change(input, { target: { value: '  ZZ ' } })
    expect(options()).toHaveLength(1)
    expect(options()[0].textContent).toContain('Banana')
    expect(match).toHaveBeenCalledWith(fruits[0], 'zz')
    expect(match.mock.calls.every((c) => c[1] === 'zz')).toBe(true)
  })

  it('filtered-list-043 Escape restores the typed query in the input', () => {
    const { input, down, options } = mount()
    fireEvent.change(input, { target: { value: 'ap' } })
    expect(options()).toHaveLength(1)
    down()
    expect(input.value).toBe('Apple')
    fireEvent.keyDown(input, { key: 'Escape' })
    expect(input.value).toBe('ap')
    expect(options().filter((o) => o.getAttribute('aria-selected') === 'true')).toHaveLength(0)
  })

  it('filtered-list-044 selecting by Enter keeps the title in the input and the item highlighted', () => {
    const onSelect = vi.fn()
    const { input, down, selected } = mount({ onSelect })
    down()
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(input.value).toBe('Apple')
    expect(selected()).toHaveLength(1)
  })

  it('filtered-list-045 footer is not rendered when there are no items', () => {
    mount({ items: [], footer: <span>+ Custom</span> })
    expect(screen.queryByText('+ Custom')).toBeNull()
  })

  it('filtered-list-046 no-matches message and footer both render, footer last', () => {
    const { input } = mount({ footer: <span>+ Custom</span> })
    fireEvent.change(input, { target: { value: 'zzz' } })
    const items = Array.from(screen.getByRole('listbox').children)
    expect(items).toHaveLength(2)
    expect(items[0].textContent).toContain('No matches for')
    expect(items[1].textContent).toBe('+ Custom')
  })

  it('filtered-list-047 clicking an item button calls onSelect with that item', () => {
    const onSelect = vi.fn()
    mount({ onSelect })
    fireEvent.click(screen.getByRole('button', { name: /Cherry/ }))
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect).toHaveBeenCalledWith(fruits[2])
  })

  it('filtered-list-048 each item button has tabIndex -1', () => {
    mount({ onSelect: () => {} })
    const buttons = screen.getAllByRole('button')
    expect(buttons).toHaveLength(fruits.length)
    buttons.forEach((b) => expect(b.tabIndex).toBe(-1))
  })
})
