/// <reference types="@testing-library/jest-dom/vitest" />
import type { ComponentProps } from 'react'
import { render, screen, cleanup, fireEvent, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { MIN_FIT_RAIL, TopicRail } from '../blocks/topic-detail'
// Through the barrel, as a host reaches it: the export is half of what makes it shareable.
import { ListToolButton } from '../blocks'

afterEach(cleanup)

const props = {
  items: [
    { id: 'a', label: 'Alpha', sublabel: 'first' },
    { id: 'b', label: 'Beta' },
    { id: 'c', label: 'Gamma' },
  ],
  selectedId: null,
  onSelect: () => {},
  emptyLabel: 'Nothing here yet.',
  collapsed: false,
  onToggle: () => {},
  title: 'Topics',
}

const toolbar = () => document.querySelector('[data-htd-toolbar]') as HTMLElement | null
const header = () => document.querySelector('[data-htd-header]') as HTMLElement
const rowLabels = () => screen.queryAllByRole('button').map((b) => b.textContent).filter((t) => t && /Alpha|Beta|Gamma/.test(t))
const filterButton = () => within(toolbar()!).getByRole('button', { name: 'Filter' })
const popover = () => document.querySelector('[data-htd-search]') as HTMLElement
// Type into the open field: the suggestions follow every keystroke, and Return chooses the
// highlighted one (Mike, 2026-11-06).
const type = (value: string) => fireEvent.change(field(), { target: { value } })
const field = () => screen.getByRole('combobox')
const key = (k: string, init: Record<string, unknown> = {}) => fireEvent.keyDown(field(), { key: k, ...init })
const suggestions = () => screen.queryAllByRole('option').map((o) => o.textContent)
const highlighted = () => screen.getAllByRole('option').find((o) => o.getAttribute('aria-selected') === 'true')?.textContent
// Type a query and press Return: the first match is selected (Mike, 2026-11-06).
const typeAndChoose = (value: string) => {
  type(value)
  key('Enter')
}

// Mike, 2026-09-24: the page-wide filter strip was clunky, so each list carries its own operations
// on a toolbar row under its title. Mike, 2026-11-06: every titled list has that toolbar, with the
// filter always its leftmost tool — then `+`, then the list's own tools right-justified.
describe('the topic list toolbar', () => {
  it('is on every titled list, with the filter, even one that passes no tools at all', () => {
    render(<TopicRail {...props} />)
    expect(toolbar()).not.toBeNull()
    fireEvent.click(filterButton())
    type('gam')
    expect(suggestions()).toEqual(['Gamma'])
  })

  it('is not on an untitled list', () => {
    render(<TopicRail {...props} title={undefined} />)
    expect(toolbar()).toBeNull()
  })

  it('carries the + and the list tools, and the title row no longer does', () => {
    const onNew = vi.fn()
    render(<TopicRail {...props} onNew={onNew} newLabel="New Topic" titleActions={<button type="button">Tools</button>} />)
    const bar = toolbar()!
    fireEvent.click(within(bar).getByRole('button', { name: 'New Topic' }))
    expect(onNew).toHaveBeenCalledOnce()
    expect(within(bar).getByRole('button', { name: 'Tools' })).toBeInTheDocument()
    expect(within(header()).queryByRole('button', { name: 'New Topic' })).toBeNull()
    expect(within(header()).queryByRole('button', { name: 'Tools' })).toBeNull()
  })

  it('opens its filter, focused, on mount when the host asks — and closes it like any other', () => {
    render(<TopicRail {...props} search={{ autoOpen: true }} />)
    expect(screen.getByRole('combobox', { name: 'Filter' })).toHaveFocus()
    key('Escape')
    expect(screen.queryByRole('combobox')).toBeNull()
  })

  it('is not shown on a collapsed icon strip', () => {
    render(<TopicRail {...props} collapsed onNew={() => {}} search={{}} />)
    expect(toolbar()).toBeNull()
  })

  it.each<[string, Pick<ComponentProps<typeof TopicRail>, 'onNew' | 'search' | 'titleActions'>]>([
    ['no other tools', {}],
    ['a +', { onNew: () => {} }],
    ['a + and its own tools', { onNew: () => {}, titleActions: <button type="button">Tools</button> }],
    ['a customised filter', { search: { placeholder: 'Find' } }],
  ])('puts the filter first, left-justified, with %s', (_, tools) => {
    render(<TopicRail {...props} newLabel="New Topic" {...tools} />)
    const buttons = within(toolbar()!).getAllByRole('button')
    expect(buttons[0]).toHaveAttribute('aria-expanded', 'false')
    // Its slot opens the row: nothing — not even the spacer — comes before it.
    expect(toolbar()!.firstElementChild).toContainElement(buttons[0]!)
  })

  it('reads filter, then +, then the list tools', () => {
    render(<TopicRail {...props} onNew={() => {}} newLabel="New Topic" titleActions={<button type="button">Tools</button>} />)
    const bar = within(toolbar()!)
    const follows = (a: Node, b: Node) => (a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING) !== 0
    expect(follows(filterButton(), bar.getByRole('button', { name: 'New Topic' }))).toBe(true)
    expect(follows(bar.getByRole('button', { name: 'New Topic' }), bar.getByRole('button', { name: 'Tools' }))).toBe(true)
  })
})

// A host's own tool on the toolbar — the Manage features puzzle piece, a bucket's settings gear —
// reads as one of the list's tools only while it is drawn exactly like the rail's own. The puzzle
// piece copied the class literal and the gear used a ghost Button, drawn larger and brighter.
describe('ListToolButton', () => {
  it("draws a host's tool exactly like the rail's own, keeping the props the host adds", () => {
    const tool = (
      <ListToolButton label="Manage workspace features" aria-haspopup="dialog">
        <span aria-hidden>⧉</span>
      </ListToolButton>
    )
    render(<TopicRail {...props} onNew={() => {}} newLabel="New Topic" search={{}} titleActions={tool} />)
    const host = within(toolbar()!).getByRole('button', { name: 'Manage workspace features' })
    expect(host.className).toBe(within(toolbar()!).getByRole('button', { name: 'New Topic' }).className)
    expect(host.className).toBe(filterButton().className)
    expect(host).toHaveAttribute('aria-haspopup', 'dialog')
  })

  it('is a plain button named by its label, muted until active turns it gold', () => {
    const { rerender } = render(<ListToolButton label="Bucket settings" />)
    const button = screen.getByRole('button', { name: 'Bucket settings' })
    // Not a submit: a host's toolbar may well sit inside a form.
    expect(button).toHaveAttribute('type', 'button')
    expect(button).toHaveAttribute('title', 'Bucket settings')
    expect(button).toHaveClass('text-apt-text-muted')
    rerender(<ListToolButton label="Bucket settings" active />)
    expect(button).toHaveClass('text-apt-gold')
    expect(button).not.toHaveClass('text-apt-text-muted')
  })
})

// Mike, 2026-11-06: "typing in the filter should show up autocomplete style list that the arrows
// operate in filled with the content of the topic list, pressing return selects that item in the
// list and dismisses the filter list".
describe('topic list filter', () => {
  it('pops a focused field over the toolbar', () => {
    render(<TopicRail {...props} search={{ placeholder: 'Search topics' }} />)
    expect(screen.queryByRole('combobox')).toBeNull()
    fireEvent.click(within(toolbar()!).getByRole('button', { name: 'Search topics' }))
    expect(screen.getByRole('combobox', { name: 'Search topics' })).toHaveFocus()
  })

  it('is a magnifying glass, and the panel keeps its glass exactly where the button was', () => {
    render(<TopicRail {...props} />)
    const slot = filterButton().parentElement!
    const glass = filterButton().querySelector('svg')!
    expect(glass.getAttribute('class')).toMatch(/lucide-search/)
    fireEvent.click(filterButton())
    const panelGlass = popover().firstElementChild!
    // Same `w-4` slot as the button's, first in the panel, and the same icon.
    expect(slot.className).toMatch(/\bw-4\b/)
    expect(panelGlass.className).toMatch(/\bw-4\b/)
    expect(panelGlass.querySelector('svg')!.getAttribute('class')).toMatch(/lucide-search/)
    // Exactly the toolbar: as wide as the rail, no wider, and never placed by hand.
    expect(popover().className).toMatch(/\binset-0\b/)
    expect(popover().getAttribute('style')).toBeNull()
  })

  it('lists the matching topics as you type, on label and sublabel, and leaves the rail whole', () => {
    render(<TopicRail {...props} />)
    fireEvent.click(filterButton())
    expect(screen.queryByRole('listbox')).toBeNull()
    type('a')
    expect(suggestions()).toEqual(['Alpha', 'Beta', 'Gamma'])
    type('FIRST')
    expect(suggestions()).toEqual(['Alpha'])
    type('mm')
    expect(suggestions()).toEqual(['Gamma'])
    expect(rowLabels()).toHaveLength(3)
    expect(field()).toHaveAttribute('aria-expanded', 'true')
    expect(field()).toHaveAttribute('aria-controls', screen.getByRole('listbox').id)
  })

  it('underlines the letters each suggestion matched on', () => {
    render(<TopicRail {...props} />)
    fireEvent.click(filterButton())
    type('MM')
    const match = screen.getByRole('option', { name: 'Gamma' }).querySelector('[data-htd-match]')
    expect(match).toHaveTextContent(/^mm$/)
    expect(match).toHaveClass('underline')
    // Matched on its sublabel: nothing in the label to underline.
    type('first')
    expect(screen.getByRole('option', { name: 'Alpha' }).querySelector('[data-htd-match]')).toBeNull()
  })

  it('underlines the right letters when case-folding changes the label’s length', () => {
    // 'İ' folds to two code units, so a position in the folded label is one off in the label.
    render(<TopicRail {...props} items={[{ id: 'i', label: 'İstanbul' }]} />)
    fireEvent.click(filterButton())
    type('stan')
    expect(screen.getByRole('option').querySelector('[data-htd-match]')).toHaveTextContent(/^stan$/)
    type('i̇s')
    expect(screen.getByRole('option').querySelector('[data-htd-match]')).toHaveTextContent(/^İs$/)
  })

  it('sizes a host’s icons like the rows do', () => {
    render(<TopicRail {...props} items={[{ id: 'a', label: 'Alpha', icon: <svg data-testid="icon" /> }]} />)
    fireEvent.click(filterButton())
    type('al')
    expect(screen.getByRole('option')).toHaveClass('[&_svg]:h-4', '[&_svg]:w-4')
  })

  it("hides the rail's rows under the list while it is up, and only then", () => {
    render(<TopicRail {...props} />)
    const list = () => document.querySelector('[data-htd-row]')!.closest('.overflow-y-auto')!
    expect(list()).not.toHaveClass('invisible')
    fireEvent.click(filterButton())
    expect(list()).not.toHaveClass('invisible')
    type('a')
    expect(list()).toHaveClass('invisible')
    // Nothing matches: the rows stay hidden under the message that says so.
    type('zzz')
    expect(list()).toHaveClass('invisible')
    type('')
    expect(list()).not.toHaveClass('invisible')
    type('a')
    key('Escape')
    expect(list()).not.toHaveClass('invisible')
  })

  it('shows the rows again with the chosen topic selected, scrolled into view', () => {
    const scrolled: string[] = []
    const real = HTMLElement.prototype.scrollIntoView
    HTMLElement.prototype.scrollIntoView = function (this: HTMLElement) {
      if (this.matches('[data-htd-row]')) scrolled.push(this.textContent ?? '')
    }
    try {
      let selected: string | null = null
      const rail = () => <TopicRail {...props} selectedId={selected} onSelect={(id) => (selected = id)} />
      const { rerender } = render(rail())
      fireEvent.click(filterButton())
      typeAndChoose('gam')
      // The host selects it on its own next render.
      rerender(rail())
      const list = document.querySelector('[data-htd-row]')!.closest('.overflow-y-auto')!
      expect(list).not.toHaveClass('invisible')
      expect(screen.getByRole('button', { name: /Gamma/ })).toHaveAttribute('aria-current', 'true')
      expect(scrolled).toEqual([expect.stringContaining('Gamma')])
      // Once: a later selection is the host's own business.
      rerender(<TopicRail {...props} selectedId="a" />)
      expect(scrolled).toHaveLength(1)
    } finally {
      HTMLElement.prototype.scrollIntoView = real
    }
  })

  it('hangs the list under the toolbar, as wide as the rail', () => {
    render(<TopicRail {...props} />)
    fireEvent.click(filterButton())
    type('a')
    const list = screen.getByRole('listbox')
    expect(toolbar()).toContainElement(list)
    expect(list.className).toMatch(/\btop-full\b/)
    expect(list.className).toMatch(/\bleft-0\b/)
    expect(list.className).toMatch(/\bright-0\b/)
  })

  it('moves the highlight with Up and Down, wrapping at either end', () => {
    render(<TopicRail {...props} />)
    fireEvent.click(filterButton())
    type('a')
    expect(highlighted()).toBe('Alpha')
    key('ArrowDown')
    expect(highlighted()).toBe('Beta')
    key('ArrowDown')
    key('ArrowDown')
    expect(highlighted()).toBe('Alpha')
    key('ArrowUp')
    expect(highlighted()).toBe('Gamma')
    expect(field()).toHaveAttribute('aria-activedescendant', screen.getAllByRole('option')[2]!.id)
  })

  it('keeps the caret where it is: the arrows are cancelled', () => {
    render(<TopicRail {...props} />)
    fireEvent.click(filterButton())
    type('a')
    expect(fireEvent.keyDown(field(), { key: 'ArrowDown' })).toBe(false)
  })

  it('starts the highlight over on every keystroke', () => {
    render(<TopicRail {...props} />)
    fireEvent.click(filterButton())
    type('a')
    key('ArrowDown')
    key('ArrowDown')
    type('am')
    expect(suggestions()).toEqual(['Gamma'])
    expect(highlighted()).toBe('Gamma')
  })

  it('Return selects the highlighted topic and dismisses the filter', () => {
    const onSelect = vi.fn()
    render(<TopicRail {...props} onSelect={onSelect} />)
    fireEvent.click(filterButton())
    type('a')
    key('ArrowDown')
    key('Enter')
    expect(onSelect).toHaveBeenCalledExactlyOnceWith('b')
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(screen.queryByRole('listbox')).toBeNull()
    expect(rowLabels()).toHaveLength(3)
    // Nothing is left behind: the next open starts empty.
    fireEvent.click(filterButton())
    expect(field()).toHaveValue('')
  })

  it('a click selects a suggestion too', () => {
    const onSelect = vi.fn()
    render(<TopicRail {...props} onSelect={onSelect} />)
    fireEvent.click(filterButton())
    type('a')
    fireEvent.click(screen.getByRole('option', { name: 'Gamma' }))
    expect(onSelect).toHaveBeenCalledExactlyOnceWith('c')
    expect(screen.queryByRole('combobox')).toBeNull()
  })

  it('does not toggle off the topic already selected', () => {
    const onSelect = vi.fn()
    render(<TopicRail {...props} selectedId="b" onSelect={onSelect} />)
    fireEvent.click(filterButton())
    typeAndChoose('beta')
    expect(onSelect).not.toHaveBeenCalled()
    expect(screen.queryByRole('combobox')).toBeNull()
  })

  it('runs a link row through onSelect, as its row would', () => {
    const onSelect = vi.fn()
    const items = [...props.items, { id: 'l', label: 'Elsewhere', onLink: () => {} }]
    render(<TopicRail {...props} items={items} selectedId="l" onSelect={onSelect} />)
    fireEvent.click(filterButton())
    typeAndChoose('else')
    expect(onSelect).toHaveBeenCalledExactlyOnceWith('l')
  })

  it('never offers a disabled topic', () => {
    const items = [...props.items, { id: 'd', label: 'Delta', disabled: true }]
    render(<TopicRail {...props} items={items} />)
    fireEvent.click(filterButton())
    type('ta')
    expect(suggestions()).toEqual(['Beta'])
  })

  it('says when nothing matches, offers nothing to choose, and Return leaves the field open', () => {
    const onSelect = vi.fn()
    render(<TopicRail {...props} onSelect={onSelect} />)
    fireEvent.click(filterButton())
    typeAndChoose('zzz')
    expect(screen.queryByRole('listbox')).toBeNull()
    expect(screen.getByText('Nothing matches “zzz”.')).toHaveAttribute('role', 'status')
    expect(field()).toHaveAttribute('aria-expanded', 'false')
    expect(field()).toBeInTheDocument()
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('Escape dismisses the filter and selects nothing', () => {
    const onSelect = vi.fn()
    render(<TopicRail {...props} onSelect={onSelect} />)
    fireEvent.click(filterButton())
    type('beta')
    key('Escape')
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(onSelect).not.toHaveBeenCalled()
    fireEvent.click(filterButton())
    expect(field()).toHaveValue('')
  })

  it('✕ dismisses the filter', () => {
    render(<TopicRail {...props} />)
    fireEvent.click(filterButton())
    type('beta')
    fireEvent.click(screen.getByRole('button', { name: 'Clear filter' }))
    expect(screen.queryByRole('combobox')).toBeNull()
  })

  it('leaves Return to an IME composing its candidate', () => {
    const onSelect = vi.fn()
    render(<TopicRail {...props} onSelect={onSelect} />)
    fireEvent.click(filterButton())
    type('beta')
    key('Enter', { keyCode: 229 })
    expect(field()).toBeInTheDocument()
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('filters the rail itself, with no list, when the host asks for live', () => {
    render(<TopicRail {...props} search={{ live: true }} />)
    fireEvent.click(filterButton())
    const box = screen.getByRole('searchbox')
    fireEvent.change(box, { target: { value: 'beta' } })
    expect(rowLabels()).toEqual([expect.stringContaining('Beta')])
    expect(screen.queryByRole('listbox')).toBeNull()
    fireEvent.keyDown(box, { key: 'Escape' })
    expect(rowLabels()).toEqual([expect.stringContaining('Beta')])
  })

  it('live leaves Return to the host, with the field still open and focused', () => {
    const onKeyDown = vi.fn((e: { defaultPrevented: boolean }) => e.defaultPrevented)
    render(
      <div onKeyDown={(e) => onKeyDown(e)}>
        <TopicRail {...props} search={{ live: true }} />
      </div>,
    )
    fireEvent.click(filterButton())
    const box = screen.getByRole('searchbox')
    fireEvent.change(box, { target: { value: 'beta' } })
    fireEvent.keyDown(box, { key: 'Enter' })
    expect(onKeyDown).toHaveLastReturnedWith(false)
    expect(screen.getByRole('searchbox')).toHaveFocus()
  })

  it('live keeps the selected row whatever the query, and says when nothing matches', () => {
    render(<TopicRail {...props} selectedId="c" search={{ live: true }} />)
    fireEvent.click(filterButton())
    fireEvent.change(screen.getByRole('searchbox'), { target: { value: 'beta' } })
    expect(rowLabels()).toHaveLength(2)
    fireEvent.change(screen.getByRole('searchbox'), { target: { value: 'zzz' } })
    expect(rowLabels()).toHaveLength(1)
    cleanup()
    render(<TopicRail {...props} search={{ live: true }} />)
    fireEvent.click(filterButton())
    fireEvent.change(screen.getByRole('searchbox'), { target: { value: 'zzz' } })
    expect(screen.getByText('Nothing matches “zzz”.')).toBeInTheDocument()
  })

  it('hands a controlled host every keystroke, offers the rows it narrows to, and clears on close', () => {
    const onQueryChange = vi.fn()
    const onSelect = vi.fn()
    const { rerender } = render(<TopicRail {...props} onSelect={onSelect} search={{ query: '', onQueryChange }} />)
    fireEvent.click(filterButton())
    type('gam')
    expect(onQueryChange).toHaveBeenLastCalledWith('gam')
    // The host matched on more than the label: its rows are the suggestions, as given.
    rerender(<TopicRail {...props} items={[props.items[0]!]} onSelect={onSelect} search={{ query: 'gam', onQueryChange }} />)
    expect(suggestions()).toEqual(['Alpha'])
    key('Enter')
    expect(onSelect).toHaveBeenCalledExactlyOnceWith('a')
    expect(onQueryChange).toHaveBeenLastCalledWith('')
  })

  it('keeps a controlled query when focus leaves, and clears it once on Escape, ✕ or a pick', () => {
    const onQueryChange = vi.fn()
    const host = (query: string) => (
      <>
        <TopicRail {...props} search={{ query, onQueryChange }} />
        <button type="button">Platform</button>
      </>
    )
    const { rerender } = render(host(''))
    // Reaching for the host's other filter: the text filter must survive the blur.
    fireEvent.click(filterButton())
    rerender(host('gam'))
    onQueryChange.mockClear()
    fireEvent.blur(field(), { relatedTarget: screen.getByRole('button', { name: 'Platform' }) })
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(onQueryChange).not.toHaveBeenCalled()
    const closers: (() => void)[] = [
      () => key('Escape'),
      () => fireEvent.click(screen.getByRole('button', { name: 'Clear filter' })),
      () => key('Enter'),
    ]
    for (const close of closers) {
      fireEvent.click(filterButton())
      onQueryChange.mockClear()
      close()
      expect(onQueryChange.mock.calls).toEqual([['']])
    }
  })

  it('does not offer the open topic a controlled host keeps in its rows unless it matches', () => {
    const onSelect = vi.fn()
    // The resource explorer keeps its open entity among the rows whatever the query.
    const host = (query: string, items: typeof props.items) => (
      <TopicRail {...props} items={items} selectedId="a" onSelect={onSelect} search={{ query, onQueryChange: () => {} }} />
    )
    const { rerender } = render(host('', props.items))
    fireEvent.click(filterButton())
    rerender(host('gam', [props.items[0]!, props.items[2]!]))
    expect(suggestions()).toEqual(['Gamma'])
    key('Enter')
    expect(onSelect).toHaveBeenCalledExactlyOnceWith('c')
    // It is still offered when it does match.
    fireEvent.click(filterButton())
    rerender(host('alp', [props.items[0]!]))
    expect(suggestions()).toEqual(['Alpha'])
  })

  it('offers nothing while a controlled host says its rows are still catching up', () => {
    const onSelect = vi.fn()
    // Notebook and Research narrow their rows 200ms after the field changes, and read them after.
    const host = (query: string, items: typeof props.items, pending: boolean) => (
      <TopicRail {...props} items={items} onSelect={onSelect} search={{ query, onQueryChange: () => {}, pending }} />
    )
    const { rerender } = render(host('', props.items, false))
    fireEvent.click(filterButton())
    rerender(host('gam', props.items, true))
    expect(suggestions()).toEqual([])
    expect(screen.getByText('Searching…')).toHaveAttribute('role', 'status')
    key('Enter')
    expect(onSelect).not.toHaveBeenCalled()
    rerender(host('gam', [props.items[2]!], false))
    expect(suggestions()).toEqual(['Gamma'])
    key('Enter')
    expect(onSelect).toHaveBeenCalledExactlyOnceWith('c')
  })

  it('keeps the highlight on the topic the arrows reached when the host rows change', () => {
    const onSelect = vi.fn()
    const host = (items: typeof props.items) => (
      <TopicRail {...props} items={items} onSelect={onSelect} search={{ query: 'a', onQueryChange: () => {} }} />
    )
    const { rerender } = render(host(props.items))
    fireEvent.click(filterButton())
    key('ArrowDown')
    expect(highlighted()).toBe('Beta')
    // The host's answer lands with a row ahead of Beta: the highlight stays on Beta.
    rerender(host([{ id: 'z', label: 'Zeta' }, ...props.items]))
    expect(highlighted()).toBe('Beta')
    key('Enter')
    expect(onSelect).toHaveBeenCalledExactlyOnceWith('b')
  })

  it('leaves the empty label to the host when the query is controlled', () => {
    // The host's list is empty while a new query's read is in flight, and only the host knows
    // that — the notebook's "Loading…" used to be replaced by "Nothing matches".
    render(<TopicRail {...props} items={[]} emptyLabel="Loading…" search={{ query: 'beta', onQueryChange: () => {} }} />)
    expect(screen.getByText('Loading…')).toBeInTheDocument()
    expect(screen.queryByText(/Nothing matches/)).toBeNull()
  })
})

// Closing the pop-over unmounts the field that has focus, and focus used to fall to <body>; the
// field's own blur closed it on Tab onto ✕, so Clear was out of the keyboard's reach.
describe('the search pop-over and the keyboard', () => {
  const closers: [string, () => void][] = [
    ['Escape', () => key('Escape')],
    ['Enter', () => key('Enter')],
    ['✕', () => fireEvent.click(screen.getByRole('button', { name: 'Clear filter' }))],
  ]
  it('lets only a MOVING pointer take the highlight, and keeps the field through a press on the list', () => {
    render(<TopicRail {...props} search={{}} />)
    fireEvent.click(filterButton())
    type('a')
    key('ArrowDown')
    expect(highlighted()).toBe('Beta')
    const options = screen.getAllByRole('option')
    // The arrows scrolled an option under a resting pointer: enter, but no move.
    fireEvent.mouseEnter(options[2]!)
    fireEvent.mouseOver(options[2]!)
    expect(highlighted()).toBe('Beta')
    fireEvent.mouseMove(options[2]!)
    expect(highlighted()).toBe('Gamma')
    // A press on the list's own padding must not take focus from the field.
    expect(fireEvent.mouseDown(screen.getByRole('listbox'))).toBe(false)
  })

  it('stops Escape even for a listener on the React root itself (a dialog under the App Router)', () => {
    const { container } = render(<TopicRail {...props} search={{}} />)
    // Added after React's own root listener, on the same node, as Base UI's document listener is.
    const dialogEscape = vi.fn()
    container.addEventListener('keydown', dialogEscape)
    fireEvent.click(filterButton())
    key('Escape')
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(dialogEscape).not.toHaveBeenCalled()
  })

  it.each(closers)('hands focus back to the filter button when %s closes the field', (_, close) => {
    render(<TopicRail {...props} search={{}} />)
    fireEvent.click(filterButton())
    expect(field()).toHaveFocus()
    type('a')
    close()
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(filterButton()).toHaveFocus()
  })

  it('stays closed after Enter chooses', async () => {
    // Enter's keypress goes to the filter button the focus was just handed to, and a button takes it
    // as a click — which would reopen the field Enter closed.
    const user = userEvent.setup()
    const onSelect = vi.fn()
    render(<TopicRail {...props} onSelect={onSelect} search={{}} />)
    await user.click(filterButton())
    await user.keyboard('gam{ArrowUp}{Enter}')
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(filterButton()).toHaveFocus()
    expect(onSelect).toHaveBeenCalledExactlyOnceWith('c')
  })

  it('stays open when Tab moves from the field onto ✕', async () => {
    const user = userEvent.setup()
    render(<TopicRail {...props} search={{}} />)
    await user.click(filterButton())
    await user.tab()
    expect(screen.getByRole('button', { name: 'Clear filter' })).toHaveFocus()
    expect(screen.getByRole('combobox')).toBeInTheDocument()
  })

  it('closes when focus leaves it, dismissed as Escape would', async () => {
    const user = userEvent.setup()
    render(<TopicRail {...props} search={{}} />)
    await user.click(filterButton())
    await user.keyboard('beta')
    await user.tab() // onto ✕, still inside
    await user.tab() // out, onto the list
    expect(screen.queryByRole('combobox')).toBeNull()
    await user.click(filterButton())
    expect(field()).toHaveValue('')
  })
})

describe('the search panel', () => {
  it("hides the browser's own clear button, leaving the panel's one ✕", () => {
    render(<TopicRail {...props} search={{}} />)
    fireEvent.click(filterButton())
    expect(field().className).toContain('[&::-webkit-search-cancel-button]:appearance-none')
    expect(within(popover()).getAllByRole('button')).toHaveLength(1)
  })
})

// A menu-detail cascade's child menu is an `overflow-hidden` box that hugs its rows. The list
// overhung it, its last options clipped out of reach, and `scrollIntoView` scrolled the box
// itself, pushing the menu's title and the field away with no scrollbar to bring them back.
describe('the suggestions inside a clipping box', () => {
  it('scroll the list alone as the arrows walk it', () => {
    const scrolled: Element[] = []
    const realInto = HTMLElement.prototype.scrollIntoView
    HTMLElement.prototype.scrollIntoView = function (this: HTMLElement) {
      scrolled.push(this)
    }
    const tops = new WeakMap<Element, number>()
    const stubs = {
      offsetTop: function (this: HTMLElement) {
        return this.matches('[role="option"]') ? Number(this.dataset.index) * 30 : 0
      },
      offsetHeight: function (this: HTMLElement) {
        return this.matches('[role="option"]') ? 30 : 0
      },
      clientHeight: function (this: HTMLElement) {
        return this.matches('[role="listbox"]') ? 60 : 0
      },
    }
    const reals = Object.fromEntries(
      Object.keys(stubs).map((k) => [k, Object.getOwnPropertyDescriptor(HTMLElement.prototype, k)]),
    )
    const realScrollTop = Object.getOwnPropertyDescriptor(Element.prototype, 'scrollTop')
    for (const [k, get] of Object.entries(stubs)) Object.defineProperty(HTMLElement.prototype, k, { configurable: true, get })
    Object.defineProperty(Element.prototype, 'scrollTop', {
      configurable: true,
      get(this: Element) {
        return tops.get(this) ?? 0
      },
      set(this: Element, v: number) {
        tops.set(this, v)
      },
    })
    try {
      render(<TopicRail {...props} search={{}} />)
      fireEvent.click(filterButton())
      type('a')
      const list = screen.getByRole('listbox')
      key('ArrowDown')
      key('ArrowDown')
      expect(highlighted()).toBe('Gamma')
      expect(list.scrollTop).toBe(30)
      key('ArrowDown') // wraps to the first
      expect(list.scrollTop).toBe(0)
      expect(scrolled).toEqual([])
    } finally {
      HTMLElement.prototype.scrollIntoView = realInto
      for (const [k, d] of Object.entries(reals)) {
        if (d) Object.defineProperty(HTMLElement.prototype, k, d)
        else delete (HTMLElement.prototype as unknown as Record<string, unknown>)[k]
      }
      if (realScrollTop) Object.defineProperty(Element.prototype, 'scrollTop', realScrollTop)
    }
  })

  it('are no taller than the room left in the box that clips them', () => {
    const real = Element.prototype.getBoundingClientRect
    Element.prototype.getBoundingClientRect = function (this: Element) {
      if (this.hasAttribute('data-clip')) return { top: 0, bottom: 200 } as DOMRect
      if (this.matches('[role="listbox"]')) return { top: 120, bottom: 400 } as DOMRect
      return real.call(this)
    }
    try {
      render(
        <div data-clip style={{ overflowY: 'hidden' }}>
          <TopicRail {...props} search={{}} />
        </div>,
      )
      fireEvent.click(filterButton())
      type('a')
      expect(screen.getByRole('listbox').style.maxHeight).toBe('min(18rem, 80px)')
    } finally {
      Element.prototype.getBoundingClientRect = real
    }
  })
})

// A rail filtering its own rows measured just the MATCHES when something else made it
// re-measure, and kept that width after the query cleared, ellipsising the full list.
describe('auto-fit while a live rail filters its own rows', () => {
  it('never measures the matches, and measures the whole list again once the query clears', () => {
    // jsdom has no layout: a column of rows is as wide as its widest row, at 10px a character.
    const real = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'scrollWidth')
    Object.defineProperty(HTMLElement.prototype, 'scrollWidth', {
      configurable: true,
      get(this: HTMLElement) {
        const rows = [...this.querySelectorAll('[data-htd-row]')]
        return rows.reduce((w, r) => Math.max(w, (r.textContent ?? '').length * 10), 0)
      },
    })
    try {
      const long = { id: 'long', label: 'x'.repeat(30) } // 300px, inside the fit range
      const wider = { id: 'wider', label: 'y'.repeat(35) } // 350px, and no match for "beta"
      const onFit = vi.fn()
      const rail = (items: typeof props.items) => <TopicRail {...props} items={items} onFit={onFit} search={{ live: true }} />
      const { rerender } = render(rail([long, ...props.items]))
      fireEvent.click(filterButton())
      fireEvent.change(screen.getByRole('searchbox'), { target: { value: 'beta' } })
      // A new row lands while the query hides it — a searched Personas rail's `+`. The rail
      // used to measure the one match here, and nothing measured it again once it cleared.
      rerender(rail([long, ...props.items, wider]))
      fireEvent.click(screen.getByRole('button', { name: 'Clear filter' }))
      expect(onFit.mock.calls.map(([w]) => w)).toEqual([300, 350])
    } finally {
      if (real) Object.defineProperty(HTMLElement.prototype, 'scrollWidth', real)
      else delete (HTMLElement.prototype as unknown as Record<string, unknown>).scrollWidth
    }
  })

  it("never measures a controlled host's matches either, and measures the list once the query clears", () => {
    const real = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'scrollWidth')
    Object.defineProperty(HTMLElement.prototype, 'scrollWidth', {
      configurable: true,
      get(this: HTMLElement) {
        const rows = [...this.querySelectorAll('[data-htd-row]')]
        return rows.reduce((w, r) => Math.max(w, (r.textContent ?? '').length * 10), 0)
      },
    })
    try {
      const long = { id: 'long', label: 'x'.repeat(30) } // 300px
      const onFit = vi.fn()
      // The host narrows its own rows to the query, as the resource explorer does.
      const rail = (query: string, items: typeof props.items) => (
        <TopicRail {...props} items={items} onFit={onFit} search={{ query, onQueryChange: () => {} }} />
      )
      const { rerender } = render(rail('', [long, ...props.items]))
      rerender(rail('b', [props.items[1]!]))
      rerender(rail('be', [props.items[1]!, { id: 'z', label: 'Bezel' }]))
      // While the query narrows the rows, the rail (and the field typed in) keeps its width.
      expect(onFit.mock.calls.map(([w]) => w)).toEqual([300])
      rerender(rail('', [long, ...props.items]))
      expect(onFit.mock.calls.map(([w]) => w)).toEqual([300, 300])
    } finally {
      if (real) Object.defineProperty(HTMLElement.prototype, 'scrollWidth', real)
      else delete (HTMLElement.prototype as unknown as Record<string, unknown>).scrollWidth
    }
  })
})

// A rail fitted to its rows alone clipped a host's tools at its edge: the Platforms rail's
// Refresh and Auto Configure read "⚙ Auto C…".
describe("auto-fit and the list toolbar's tools", () => {
  it('is wide enough for the toolbar when its tools outgrow the rows', () => {
    const real = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'scrollWidth')
    Object.defineProperty(HTMLElement.prototype, 'scrollWidth', {
      configurable: true,
      get(this: HTMLElement) {
        // The toolbar's max-content: 260px with the host's tools in it, 40px without.
        if (this.hasAttribute('data-htd-toolbar')) return this.querySelector('[data-htd-tool-actions]') ? 260 : 40
        const rows = [...this.querySelectorAll('[data-htd-row]')]
        return rows.reduce((w, r) => Math.max(w, (r.textContent ?? '').length * 10), 0)
      },
    })
    try {
      const onFit = vi.fn()
      const { rerender } = render(<TopicRail {...props} title="Platforms" onFit={onFit} />)
      expect(onFit).toHaveBeenLastCalledWith(MIN_FIT_RAIL)
      rerender(<TopicRail {...props} title="Platforms" onFit={onFit} titleActions={<button>Auto Configure</button>} />)
      expect(onFit).toHaveBeenLastCalledWith(260)
    } finally {
      if (real) Object.defineProperty(HTMLElement.prototype, 'scrollWidth', real)
      else delete (HTMLElement.prototype as unknown as Record<string, unknown>).scrollWidth
    }
  })
})
