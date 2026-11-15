/// <reference types="@testing-library/jest-dom/vitest" />
/**
 * Conformance vectors T1-T83 of the topic-detail recipe, one `it` per vector, titled by its id.
 *
 * The behaviors also have focused suites beside this file (topicDetailPreview, topicDetailLink,
 * topicDetailBlocked, topicDetailDelete, topicDetailCheckable, topic-rail-prefetch,
 * topic-rail-busy, topic-rail-toolbar, railAutoFit); this file is the one place every vector is
 * named, so the recipe's vector table maps to a test of the same id.
 */
import type { ReactElement } from 'react'
import { act, cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import {
  COLLAPSED_RAIL,
  FULL_RAIL,
  LINK_FLASH_MS,
  MAX_FIT_RAIL,
  MIN_FIT_RAIL,
  TopicDetail,
  TopicRail,
  railPx,
  type TopicDetailItem,
} from '../blocks/topic-detail'

afterEach(() => {
  cleanup()
  vi.useRealTimers()
  vi.restoreAllMocks()
})

const ITEMS: TopicDetailItem[] = [
  { id: 'a', label: 'Alpha', sublabel: 'first' },
  { id: 'b', label: 'Beta' },
  { id: 'c', label: 'Gamma' },
]

type RailProps = Parameters<typeof TopicRail>[0]

function railProps(extra: Partial<RailProps> = {}): RailProps {
  return {
    items: ITEMS,
    selectedId: null,
    onSelect: () => {},
    emptyLabel: 'Nothing here yet.',
    collapsed: false,
    onToggle: () => {},
    ...extra,
  }
}

function rail(extra: Partial<RailProps> = {}): ReactElement {
  return <TopicRail {...railProps(extra)} />
}

function detail(
  items: TopicDetailItem[] = ITEMS,
  extra: Partial<Parameters<typeof TopicDetail>[0]> = {},
): ReactElement {
  return (
    <TopicDetail items={items} selectedId={null} onSelect={() => {}} {...extra}>
      <div>pane content</div>
    </TopicDetail>
  )
}

const row = (name: string | RegExp): HTMLElement =>
  screen.getByRole('button', { name: typeof name === 'string' ? new RegExp(`^${name}`) : name })
const toolbar = (): HTMLElement | null => document.querySelector('[data-htd-toolbar]')
const filterButton = (): HTMLElement => within(toolbar()!).getByRole('button', { name: 'Filter' })
const field = (): HTMLElement => screen.getByRole('combobox')
const typeInto = (el: HTMLElement, value: string): boolean => fireEvent.change(el, { target: { value } })
const key = (k: string, init: Record<string, unknown> = {}): boolean =>
  fireEvent.keyDown(field(), { key: k, ...init })
const options = (): (string | null)[] => screen.queryAllByRole('option').map((o) => o.textContent)
const gridEl = (container: HTMLElement): HTMLElement => container.firstElementChild as HTMLElement
const railWidthVar = (container: HTMLElement): string => gridEl(container).style.getPropertyValue('--rail-w')
const follows = (a: Node, b: Node): boolean => (a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING) !== 0

/** `scrollWidth` as the widest row at 10px a character, which is what max-content means for a
 *  column of rows; jsdom has no layout and answers 0. Returns the restore. */
function stubRowWidth(perChar = 10, extra?: (el: HTMLElement) => number | undefined): () => void {
  const real = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'scrollWidth')
  Object.defineProperty(HTMLElement.prototype, 'scrollWidth', {
    configurable: true,
    get(this: HTMLElement) {
      const special = extra?.(this)
      if (special !== undefined) return special
      const rows = [...this.querySelectorAll('[data-htd-row]')]
      return rows.reduce((w, r) => Math.max(w, (r.textContent ?? '').length * perChar), 0)
    },
  })
  return () => {
    if (real) Object.defineProperty(HTMLElement.prototype, 'scrollWidth', real)
    else delete (HTMLElement.prototype as unknown as Record<string, unknown>).scrollWidth
  }
}

describe('TopicDetail conformance vectors: rows and panes', () => {
  it('T1: renders the rail on the left, the pane on the right, children in the pane', () => {
    const { container } = render(detail())
    const aside = screen.getByRole('complementary', { name: 'Topic list' })
    const pane = within(container).getByText('pane content').closest('section')!
    expect(pane).not.toBeNull()
    expect(follows(aside, pane)).toBe(true)
    expect(gridEl(container).className).toContain('grid')
    expect(gridEl(container).className).toContain('var(--rail-w)_minmax(0,1fr)')
  })

  it('T2: marks the selected row with aria-current, gold text and the gold bar', () => {
    render(rail({ selectedId: 'b' }))
    const selected = row('Beta')
    expect(selected).toHaveAttribute('aria-current', 'true')
    expect(selected.className).toContain('text-apt-gold')
    expect(selected.className).toContain('border-l-apt-gold')
    expect(row('Alpha')).not.toHaveAttribute('aria-current')
  })

  it('T3: clicking a row reports its id once', () => {
    const onSelect = vi.fn()
    render(rail({ selectedId: 'b', onSelect }))
    fireEvent.click(row('Gamma'))
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect).toHaveBeenCalledWith('c')
  })

  it('T4: clicking the already-selected row, not covered, fires onSelect again with the same id', () => {
    const onSelect = vi.fn()
    render(rail({ selectedId: 'b', onSelect }))
    fireEvent.click(row('Beta'))
    expect(onSelect).toHaveBeenCalledWith('b')
  })

  it('T5: covered, clicking the selected row does not call onSelect', () => {
    const onSelect = vi.fn()
    render(rail({ selectedId: 'b', onSelect, covered: true }))
    fireEvent.click(row('Beta'))
    expect(onSelect).not.toHaveBeenCalled()
    fireEvent.click(row('Gamma'))
    expect(onSelect).toHaveBeenCalledWith('c')
  })

  it('T6: a disabled row is a native disabled button, dimmed, and never selects', () => {
    const onSelect = vi.fn()
    render(rail({ items: [{ id: 'a', label: 'Alpha', disabled: true }], onSelect }))
    const btn = row('Alpha')
    expect(btn).toBeDisabled()
    expect(btn.className).toContain('text-apt-text-dim')
    expect(btn.className).toContain('cursor-default')
    fireEvent.click(btn)
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('T7: no rows shows the empty label in a paragraph', () => {
    render(detail([]))
    const p = screen.getByText('Nothing here yet.')
    expect(p.tagName).toBe('P')
    expect(p.closest('li')).not.toBeNull()
  })

  it('T8: railSlot sits above the topics with the gold bar, and the function gets the collapsed state', () => {
    const slot = vi.fn((collapsed: boolean) => <span>slot:{String(collapsed)}</span>)
    render(rail({ railSlot: slot, railSlotActive: true, collapsed: true }))
    expect(slot).toHaveBeenCalledWith(true)
    const li = screen.getByText('slot:true').closest('li')!
    expect(li.className).toContain('border-l-apt-gold')
    expect(li.className).toContain('min-h-[2.15rem]')
    expect(follows(li, document.querySelector('[data-htd-row]')!)).toBe(true)
  })

  it('T9: without railSlot there is no slot element and the list keeps its top padding', () => {
    render(rail())
    expect(document.querySelector('li.min-h-\\[2\\.15rem\\]')).toBeNull()
    const list = document.querySelector('ul')!
    expect(list.firstElementChild!.querySelector('[data-htd-row]')).not.toBeNull()
    expect(list.parentElement!.className).toContain('pt-2')
  })

  it('T10: labelSuffix sits on the label line at full size, and hides the stacked sublabel', () => {
    render(rail({ items: [{ id: 'a', label: 'A', labelSuffix: 'v2', sublabel: 'b.com' }] }))
    const btn = row(/A/)
    const label = within(btn).getByText('A')
    const suffix = within(btn).getByText('v2')
    expect(label.parentElement).toBe(suffix.parentElement)
    expect(label.parentElement!.className).toContain('flex')
    expect(label.className).not.toContain('text-[0.7rem]')
    expect(suffix.className).not.toContain('text-[0.7rem]')
    expect(suffix.className).toContain('shrink-0')
    expect(within(btn).queryByText('b.com')).toBeNull()
  })

  it('T11: an inline sublabel shares the line, dim, and shrinks first', () => {
    render(rail({ items: [{ id: 'a', label: 'A', sublabel: 'b.com', inlineSublabel: true }] }))
    const btn = row(/A/)
    const label = within(btn).getByText('A')
    const sub = within(btn).getByText('b.com')
    expect(label.parentElement).toBe(sub.parentElement)
    expect(sub.className).toContain('text-apt-text-dim')
    expect(sub.className).toContain('shrink')
    expect(sub.className).not.toContain('shrink-0')
    expect(label.className).toContain('flex-1')
  })

  it('T12: a plain sublabel is a second dim line', () => {
    render(rail({ items: [{ id: 'a', label: 'A', sublabel: 'b.com' }] }))
    const sub = within(row(/A/)).getByText('b.com')
    expect(sub.className).toContain('block')
    expect(sub.className).toContain('text-apt-text-dim')
    expect(sub.previousElementSibling).toBe(within(row(/A/)).getByText('A'))
  })

  it('T13: preview renders a preview block clamped to previewLines', () => {
    render(rail({ items: [{ id: 'a', label: 'A', preview: 'line one\nline two', previewLines: 2 }] }))
    const preview = document.querySelector('[data-htd-preview]')!
    expect(preview).toHaveTextContent('line one line two')
    expect(preview.className).toContain('line-clamp-2')
    expect(preview.className).toContain('whitespace-pre-line')
  })

  it('T14: previewLines 0 renders no preview, and 9 clamps to four lines', () => {
    const { rerender } = render(rail({ items: [{ id: 'a', label: 'A', preview: 'text', previewLines: 0 }] }))
    expect(document.querySelector('[data-htd-preview]')).toBeNull()
    rerender(rail({ items: [{ id: 'a', label: 'A', preview: 'text', previewLines: 9 }] }))
    expect(document.querySelector('[data-htd-preview]')!.className).toContain('line-clamp-4')
  })

  it('T15: a whitespace-only preview renders no block', () => {
    render(rail({ items: [{ id: 'a', label: 'A', preview: '   ' }] }))
    expect(document.querySelector('[data-htd-preview]')).toBeNull()
  })

  it('T16: a row without an icon, and one with icon={false}, get the neutral 16px ring', () => {
    render(
      rail({
        items: [
          { id: 'a', label: 'Alpha' },
          { id: 'b', label: 'Beta', icon: false },
        ],
      }),
    )
    for (const name of ['Alpha', 'Beta']) {
      const svg = row(name).querySelector('[data-htd-icon] svg')!
      expect(svg.getAttribute('class')).toContain('lucide-circle')
      expect(svg.getAttribute('width')).toBe('16')
    }
  })

  it('T17: hideItemIcons drops the icon expanded and keeps it collapsed', () => {
    const { rerender } = render(rail({ hideItemIcons: true }))
    expect(document.querySelector('[data-htd-icon]')).toBeNull()
    rerender(rail({ hideItemIcons: true, collapsed: true }))
    expect(document.querySelectorAll('[data-htd-icon]')).toHaveLength(ITEMS.length)
  })

  it('T18: collapsed rows show icons only, carry the label as aria-label, and tooltip on hover', async () => {
    const user = userEvent.setup()
    render(rail({ collapsed: true }))
    const btn = row('Alpha')
    expect(btn).toHaveAttribute('aria-label', 'Alpha')
    expect(btn).toHaveAttribute('data-htd-strip', 'collapsed')
    expect(btn.querySelector('[data-htd-label]')).toBeNull()
    await user.hover(btn)
    await waitFor(() => expect(document.querySelector('[data-slot="tooltip-content"]')).not.toBeNull(), {
      timeout: 1500,
    })
    expect(document.querySelector('[data-slot="tooltip-content"]')).toHaveTextContent('Alpha')
  })

  it('T19: dividerAfter draws a separator expanded, collapsed and covered, with the right inset', () => {
    const items: TopicDetailItem[] = [
      { id: 'a', label: 'Alpha', dividerAfter: true },
      { id: 'b', label: 'Beta' },
    ]
    const { rerender } = render(rail({ items }))
    expect(screen.getByRole('separator').className).toContain('mx-3')
    rerender(rail({ items, collapsed: true }))
    expect(screen.getByRole('separator').className).toContain('mx-2')
    rerender(rail({ items, covered: true }))
    expect(screen.getByRole('separator').className).toContain('mx-3')
  })

  it('T20: dividerLabel is a caption expanded and absent from the strips', () => {
    const items: TopicDetailItem[] = [
      { id: 'a', label: 'Alpha', dividerAfter: true, dividerLabel: 'Coming soon' },
      { id: 'b', label: 'Beta' },
    ]
    const { rerender } = render(rail({ items }))
    const caption = screen.getByText('Coming soon')
    expect(caption.className).toContain('uppercase')
    rerender(rail({ items, collapsed: true }))
    expect(screen.queryByText('Coming soon')).toBeNull()
    rerender(rail({ items, covered: true }))
    expect(screen.queryByText('Coming soon')).toBeNull()
  })

  it('T21: spacerAfter at position 2 of 5 puts rows 3 to 5 after a flexible spacer', () => {
    const five = ['a', 'b', 'c', 'd', 'e'].map((id, i) => ({ id, label: `R${i + 1}`, spacerAfter: i === 1 }))
    render(rail({ items: five }))
    const spacer = document.querySelector('li[aria-hidden].flex-1')!
    expect(spacer).not.toBeNull()
    expect(follows(row('R2'), spacer)).toBe(true)
    for (const name of ['R3', 'R4', 'R5']) expect(follows(spacer, row(name))).toBe(true)
    expect(follows(spacer, row('R1'))).toBe(false)
    expect(document.querySelectorAll('li[aria-hidden].flex-1')).toHaveLength(1)
  })

  it('T22: trailing is right-justified expanded and absent collapsed', () => {
    const items: TopicDetailItem[] = [{ id: 'a', label: 'Alpha', trailing: <em>badge</em> }]
    const { rerender } = render(rail({ items }))
    const trailing = screen.getByText('badge').closest('[data-htd-trailing]')!
    expect(trailing.className).toContain('ml-auto')
    rerender(rail({ items, collapsed: true }))
    expect(screen.queryByText('badge')).toBeNull()
  })

  it('T23: rowDisclosure shows a chevron on enabled non-link rows only', () => {
    render(
      rail({
        rowDisclosure: true,
        items: [
          { id: 'a', label: 'Alpha' },
          { id: 'b', label: 'Beta', disabled: true },
          { id: 'c', label: 'Gamma', onLink: () => {} },
        ],
      }),
    )
    const chevron = (name: string): Element | null => row(name).querySelector('svg.lucide-chevron-right')
    expect(chevron('Alpha')).not.toBeNull()
    expect(chevron('Beta')).toBeNull()
    expect(chevron('Gamma')).toBeNull()
  })
})

describe('TopicDetail conformance vectors: link rows', () => {
  const linkItems = (onLink: () => void): TopicDetailItem[] => [
    { id: 'acme', label: 'Acme' },
    { id: 'rockets', label: 'Rockets', onLink },
  ]

  it('T24: choosing a link row runs the link and does not call onSelect', () => {
    const onLink = vi.fn()
    const onSelect = vi.fn()
    render(detail(linkItems(onLink), { onSelect }))
    fireEvent.click(row('Rockets'))
    expect(onLink).toHaveBeenCalledTimes(1)
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('T25: choosing an ordinary row runs onSelect', () => {
    const onLink = vi.fn()
    const onSelect = vi.fn()
    render(detail(linkItems(onLink), { onSelect }))
    fireEvent.click(row('Acme'))
    expect(onSelect).toHaveBeenCalledWith('acme')
    expect(onLink).not.toHaveBeenCalled()
  })

  it('T26: a chosen link row is marked active, then released after 1000ms', () => {
    vi.useFakeTimers()
    render(detail(linkItems(vi.fn())))
    const link = row('Rockets')
    fireEvent.click(link)
    expect(link).toHaveAttribute('aria-current', 'true')
    act(() => void vi.advanceTimersByTime(LINK_FLASH_MS - 1))
    expect(link).toHaveAttribute('aria-current', 'true')
    act(() => void vi.advanceTimersByTime(1))
    expect(link).not.toHaveAttribute('aria-current')
  })

  it('T27: a link row without an icon shows the link glyph and no chevron', () => {
    render(rail({ rowDisclosure: true, items: linkItems(vi.fn()) }))
    const link = row('Rockets')
    expect(link.querySelector('[aria-label="link"]')).not.toBeNull()
    expect(link.querySelector('svg.lucide-chevron-right')).toBeNull()
  })
})

describe('TopicDetail conformance vectors: blocked rows', () => {
  const blocked: TopicDetailItem[] = [
    { id: 'a', label: 'Alpha', blocked: true },
    { id: 'b', label: 'Beta' },
  ]

  it('T28: a blocked row has a dot on its icon, data-blocked and "needs attention" in its name', () => {
    render(rail({ items: blocked }))
    const btn = row(/Alpha/)
    expect(btn).toHaveAttribute('data-blocked', 'true')
    expect(btn.querySelector('[data-htd-icon] [data-htd-blocked]')).not.toBeNull()
    expect(btn).toHaveAccessibleName(/needs attention/)
    expect(row('Beta').querySelector('[data-htd-blocked]')).toBeNull()
  })

  it('T29: collapsed, a blocked row is named "Alpha, needs attention"', () => {
    render(rail({ items: blocked, collapsed: true }))
    expect(screen.getByRole('button', { name: 'Alpha, needs attention' })).toHaveAttribute(
      'aria-label',
      'Alpha, needs attention',
    )
  })

  it('T30: with hideItemIcons a blocked row keeps a standalone dot and the sr-only text', () => {
    render(rail({ items: blocked, hideItemIcons: true }))
    const btn = row(/Alpha/)
    expect(btn.querySelector('[data-htd-icon]')).toBeNull()
    expect(btn.querySelector(':scope > [data-htd-blocked]')).not.toBeNull()
    expect(btn.querySelector('.sr-only')).toHaveTextContent('needs attention')
  })
})

describe('TopicDetail conformance vectors: row delete', () => {
  const deletable = (extra: Partial<TopicDetailItem> = {}): TopicDetailItem[] => [
    { id: 'a', label: 'Alpha', onDelete: vi.fn(), ...extra },
    { id: 'b', label: 'Beta' },
  ]

  it('T31: the trash button opens the confirm dialog without selecting the row', async () => {
    const onSelect = vi.fn()
    render(detail(deletable(), { onSelect }))
    const trash = screen.getByRole('button', { name: 'Delete Alpha' })
    fireEvent.pointerEnter(row('Alpha'))
    fireEvent.click(trash)
    expect(await screen.findByRole('dialog')).toBeInTheDocument()
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('T32: confirming runs an async onDelete, busy until it settles, then closes', async () => {
    let settle: () => void = () => {}
    const onDelete = vi.fn(() => new Promise<void>((resolve) => void (settle = resolve)))
    render(detail(deletable({ onDelete })))
    fireEvent.click(screen.getByRole('button', { name: 'Delete Alpha' }))
    fireEvent.click(await screen.findByRole('button', { name: /^Delete$/ }))
    expect(onDelete).toHaveBeenCalledTimes(1)
    expect(await screen.findByRole('status', { name: 'Working…' })).toBeInTheDocument()
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    await act(async () => settle())
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
  })

  it('T33: a rejecting onDelete keeps the dialog open with the busy state cleared', async () => {
    const onDelete = vi.fn().mockRejectedValue(new Error('nope'))
    render(detail(deletable({ onDelete })))
    fireEvent.click(screen.getByRole('button', { name: 'Delete Alpha' }))
    fireEvent.click(await screen.findByRole('button', { name: /^Delete$/ }))
    await waitFor(() => expect(onDelete).toHaveBeenCalledTimes(1))
    await waitFor(() => expect(screen.queryByRole('status', { name: 'Working…' })).toBeNull())
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /^Delete$/ })).toBeInTheDocument()
  })

  it('T34: deleteLabel names the trash button and the dialog title', async () => {
    render(detail(deletable({ deleteLabel: 'Workspace' })))
    fireEvent.click(screen.getByRole('button', { name: 'Delete Workspace' }))
    expect(await screen.findByText('Delete Workspace?')).toBeInTheDocument()
  })

  it('T35: deleteConfirm is the dialog body, defaulting to the cannot-be-undone line', async () => {
    const { unmount } = render(detail(deletable({ deleteConfirm: 'Permanent loss.' })))
    fireEvent.click(screen.getByRole('button', { name: 'Delete Alpha' }))
    expect(await screen.findByText('Permanent loss.')).toBeInTheDocument()
    unmount()
    cleanup()
    render(detail(deletable()))
    fireEvent.click(screen.getByRole('button', { name: 'Delete Alpha' }))
    expect(await screen.findByText("This action can't be undone.")).toBeInTheDocument()
  })

  it('T36: a disabled row with onDelete still has an enabled trash button', () => {
    render(detail(deletable({ disabled: true })))
    expect(row('Alpha')).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Delete Alpha' })).toBeEnabled()
  })

  it('T37: collapsed or covered rails render no trash button', () => {
    const { rerender } = render(rail({ items: deletable(), collapsed: true }))
    expect(screen.queryByRole('button', { name: /^Delete/ })).toBeNull()
    rerender(rail({ items: deletable(), covered: true }))
    expect(screen.queryByRole('button', { name: /^Delete/ })).toBeNull()
  })
})

describe('TopicDetail conformance vectors: batch mode', () => {
  it('T38: checkable shows a checkbox per expanded row and none in the strips', () => {
    const { rerender } = render(rail({ checkable: true, checkedIds: new Set() }))
    expect(screen.getAllByRole('checkbox')).toHaveLength(ITEMS.length)
    expect(screen.getByRole('checkbox', { name: 'Alpha' })).toBeInTheDocument()
    rerender(rail({ checkable: true, checkedIds: new Set(), collapsed: true }))
    expect(screen.queryAllByRole('checkbox')).toHaveLength(0)
    rerender(rail({ checkable: true, checkedIds: new Set(), covered: true }))
    expect(screen.queryAllByRole('checkbox')).toHaveLength(0)
  })

  it('T39: ticking an unticked box reports the id and does not select the row', () => {
    const onToggleChecked = vi.fn()
    const onSelect = vi.fn()
    render(rail({ checkable: true, checkedIds: new Set(), onToggleChecked, onSelect }))
    fireEvent.click(screen.getByRole('checkbox', { name: 'Beta' }))
    expect(onToggleChecked).toHaveBeenCalledWith('b')
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('T40: checkDisabled disables the box while the row stays selectable', () => {
    const onSelect = vi.fn()
    render(
      rail({
        checkable: true,
        checkedIds: new Set(),
        onSelect,
        items: [{ id: 'a', label: 'Alpha', checkDisabled: true }],
      }),
    )
    expect(screen.getByRole('checkbox', { name: 'Alpha' })).toHaveAttribute('aria-disabled', 'true')
    expect(row('Alpha')).toBeEnabled()
    fireEvent.click(row('Alpha'))
    expect(onSelect).toHaveBeenCalledWith('a')
  })
})

describe('TopicDetail conformance vectors: prefetch', () => {
  it('T41: resting on a row for 100ms calls onPrefetch once', () => {
    vi.useFakeTimers()
    const onPrefetch = vi.fn()
    render(rail({ onPrefetch }))
    fireEvent.pointerEnter(row('Alpha'))
    act(() => void vi.advanceTimersByTime(99))
    expect(onPrefetch).not.toHaveBeenCalled()
    act(() => void vi.advanceTimersByTime(1))
    expect(onPrefetch).toHaveBeenCalledTimes(1)
    expect(onPrefetch).toHaveBeenCalledWith('a')
  })

  it('T42: sweeping past rows fires nothing', () => {
    vi.useFakeTimers()
    const onPrefetch = vi.fn()
    render(rail({ onPrefetch }))
    for (const name of ['Alpha', 'Beta', 'Gamma']) {
      const btn = row(name)
      fireEvent.pointerEnter(btn)
      act(() => void vi.advanceTimersByTime(40))
      fireEvent.pointerLeave(btn)
    }
    act(() => void vi.advanceTimersByTime(300))
    expect(onPrefetch).not.toHaveBeenCalled()
  })

  it('T43: keyboard focus fires, and nothing fires without the prop', () => {
    vi.useFakeTimers()
    const onPrefetch = vi.fn()
    const { rerender } = render(rail({ onPrefetch }))
    fireEvent.focus(row('Beta'))
    act(() => void vi.advanceTimersByTime(100))
    expect(onPrefetch).toHaveBeenCalledWith('b')
    onPrefetch.mockClear()
    rerender(rail())
    fireEvent.focus(row('Beta'))
    act(() => void vi.advanceTimersByTime(300))
    expect(onPrefetch).not.toHaveBeenCalled()
  })

  it('T44: resting on the selected row does not arm a prefetch', () => {
    vi.useFakeTimers()
    const onPrefetch = vi.fn()
    render(rail({ onPrefetch, selectedId: 'a' }))
    fireEvent.pointerEnter(row('Alpha'))
    act(() => void vi.advanceTimersByTime(300))
    expect(onPrefetch).not.toHaveBeenCalled()
  })
})

describe('TopicDetail conformance vectors: selection style', () => {
  it('T45: hoverBar false removes the hover border class', () => {
    const { rerender } = render(rail())
    expect(row('Alpha').className).toContain('hover:border-l-apt-text')
    rerender(rail({ hoverBar: false }))
    expect(row('Alpha').className).not.toContain('hover:border-l-apt-text')
  })

  it('T46: marker selection in a root list draws a full-height gold bar and no gold border', () => {
    render(rail({ selectedId: 'a', selectionStyle: 'marker', isRoot: true }))
    const btn = row('Alpha')
    expect(btn.className).not.toContain('border-l-apt-gold')
    const bar = btn.querySelector(':scope > span[aria-hidden].absolute')!
    expect(bar).not.toBeNull()
    expect(bar.className).toContain('inset-y-0')
    expect(bar.className).toContain('bg-apt-gold')
  })
})

describe('TopicDetail conformance vectors: collapse and resize', () => {
  it('T47: the toggle collapses the rail to 48px and restores it', () => {
    const { container } = render(detail())
    expect(railWidthVar(container)).toBe(`${FULL_RAIL}px`)
    fireEvent.click(screen.getByRole('button', { name: 'Collapse topic list' }))
    expect(railWidthVar(container)).toBe(`${COLLAPSED_RAIL}px`)
    expect(COLLAPSED_RAIL).toBe(48)
    fireEvent.click(screen.getByRole('button', { name: 'Expand topic list' }))
    expect(railWidthVar(container)).toBe(`${FULL_RAIL}px`)
  })

  it('T48: controlled collapse reports the change and follows the prop', () => {
    const onCollapsedChange = vi.fn()
    const { container, rerender } = render(detail(ITEMS, { collapsed: true, onCollapsedChange }))
    fireEvent.click(screen.getByRole('button', { name: 'Expand topic list' }))
    expect(onCollapsedChange).toHaveBeenCalledWith(false)
    expect(railWidthVar(container)).toBe(`${COLLAPSED_RAIL}px`)
    rerender(detail(ITEMS, { collapsed: false, onCollapsedChange }))
    expect(railWidthVar(container)).toBe(`${FULL_RAIL}px`)
  })

  it('T49: dragging tracks 100px, collapses at 50px, and clamps 400px to 240px', () => {
    const proto = HTMLElement.prototype as unknown as Record<string, unknown>
    proto.setPointerCapture = () => {}
    proto.releasePointerCapture = () => {}
    try {
      const { container } = render(detail())
      const handle = screen.getByRole('separator', { name: 'Resize topic list' })
      fireEvent.pointerDown(handle, { pointerId: 1 })
      fireEvent.pointerMove(handle, { pointerId: 1, clientX: 100 })
      expect(railWidthVar(container)).toBe('100px')
      fireEvent.pointerMove(handle, { pointerId: 1, clientX: 50 })
      expect(railWidthVar(container)).toBe(`${COLLAPSED_RAIL}px`)
      fireEvent.pointerMove(handle, { pointerId: 1, clientX: 400 })
      expect(railWidthVar(container)).toBe(`${FULL_RAIL}px`)
      fireEvent.pointerUp(handle, { pointerId: 1 })
    } finally {
      delete proto.setPointerCapture
      delete proto.releasePointerCapture
    }
  })

  it('T50: the width transition is absent while dragging and present when idle', () => {
    const proto = HTMLElement.prototype as unknown as Record<string, unknown>
    proto.setPointerCapture = () => {}
    proto.releasePointerCapture = () => {}
    try {
      const { container } = render(detail())
      const transition = 'md:transition-[grid-template-columns]'
      expect(gridEl(container).className).toContain(transition)
      const handle = screen.getByRole('separator', { name: 'Resize topic list' })
      fireEvent.pointerDown(handle, { pointerId: 1 })
      expect(gridEl(container).className).not.toContain(transition)
      fireEvent.pointerUp(handle, { pointerId: 1 })
      expect(gridEl(container).className).toContain(transition)
      expect(gridEl(container).className).toContain('200ms*var(--apt-anim-scale,1)')
    } finally {
      delete proto.setPointerCapture
      delete proto.releasePointerCapture
    }
  })

  // jsdom evaluates no stylesheet, so a `max-md:` or `md:` rule never applies; the layout below
  // `md` is a real-browser fact.
  it.skip('T51: below md the grid is one column, rail above, toggle and handle hidden (needs real CSS media queries)', () => {})

  it('T52: panePadding false removes the inset and gap classes', () => {
    const { rerender } = render(detail())
    const section = (): HTMLElement => screen.getByText('pane content').closest('section')!
    expect(section().className).toContain('gap-6 px-6 py-4')
    rerender(detail(ITEMS, { panePadding: false }))
    expect(section().className).not.toMatch(/gap-6|px-6|py-4/)
  })
})

describe('TopicDetail conformance vectors: headers and toolbar', () => {
  it('T53: a titled rail has a header with the title and a toolbar named "Users tools"', () => {
    render(rail({ title: 'Users' }))
    const header = document.querySelector('[data-htd-header]')!
    expect(header).toHaveTextContent('Users')
    expect(screen.getByRole('toolbar', { name: 'Users tools' })).toBeInTheDocument()
  })

  it('T54: an untitled rail puts backSlot top-left, and leftControl wins when both are given', () => {
    const { rerender } = render(rail({ backSlot: <button type="button">Back</button> }))
    const header = (): Element => document.querySelector('[data-htd-header]')!
    expect(header().firstElementChild).toContainElement(screen.getByRole('button', { name: 'Back' }))
    rerender(
      rail({
        backSlot: <button type="button">Back</button>,
        leftControl: <button type="button">Lead</button>,
      }),
    )
    expect(screen.getByRole('button', { name: 'Lead' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Back' })).toBeNull()
  })

  it('T55: a titled rail with no tools still has the toolbar with the filter', () => {
    render(rail({ title: 'Topics' }))
    expect(toolbar()).not.toBeNull()
    expect(filterButton()).toBeInTheDocument()
  })

  it('T56: an untitled rail and a collapsed rail have no toolbar', () => {
    const { rerender } = render(rail())
    expect(toolbar()).toBeNull()
    rerender(rail({ title: 'Topics', collapsed: true }))
    expect(toolbar()).toBeNull()
  })

  it('T57: the toolbar reads filter, +, then the host tools', () => {
    render(
      rail({
        title: 'Topics',
        onNew: () => {},
        newLabel: 'New Topic',
        titleActions: <button type="button">Tools</button>,
      }),
    )
    const bar = within(toolbar()!)
    const plus = bar.getByRole('button', { name: 'New Topic' })
    const tools = bar.getByRole('button', { name: 'Tools' })
    expect(follows(filterButton(), plus)).toBe(true)
    expect(follows(plus, tools)).toBe(true)
  })

  it('T58: onNew renders a + named by newLabel, gold when newActive', () => {
    const onNew = vi.fn()
    const { rerender } = render(rail({ title: 'Topics', onNew, newLabel: 'New Topic' }))
    const plus = screen.getByRole('button', { name: 'New Topic' })
    expect(plus.className).toContain('text-apt-text-muted')
    fireEvent.click(plus)
    expect(onNew).toHaveBeenCalledTimes(1)
    rerender(rail({ title: 'Topics', onNew, newLabel: 'New Topic', newActive: true }))
    expect(screen.getByRole('button', { name: 'New Topic' }).className).toContain('text-apt-gold')
  })

  it('T59: onClose renders a button named by closeLabel', () => {
    const onClose = vi.fn()
    render(rail({ title: 'Topics', onClose, closeLabel: 'Dismiss' }))
    fireEvent.click(screen.getByRole('button', { name: 'Dismiss' }))
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('T60: headerSlot is a strip under the toolbar, hidden when collapsed', () => {
    const { rerender } = render(rail({ title: 'Topics', headerSlot: <p>strip</p> }))
    const strip = screen.getByText('strip').parentElement!
    expect(follows(toolbar()!, strip)).toBe(true)
    expect(strip.className).toContain('border-b')
    rerender(rail({ title: 'Topics', headerSlot: <p>strip</p>, collapsed: true }))
    expect(screen.queryByText('strip')).toBeNull()
  })

  it('T61: footer is pinned below the list with a top border', () => {
    render(rail({ footer: <p>foot</p> }))
    const foot = screen.getByText('foot').parentElement!
    expect(foot.className).toContain('border-t')
    expect(follows(document.querySelector('[data-htd-row]')!, foot)).toBe(true)
  })

  it('T62: busy shows a spinner by the title and announces "Loading", empty when not busy', () => {
    const { rerender } = render(rail({ title: 'Topics' }))
    expect(document.querySelector('[data-htd-busy]')).toBeNull()
    expect(screen.getByRole('status')).toHaveTextContent('')
    rerender(rail({ title: 'Topics', busy: true }))
    expect(document.querySelector('[data-htd-header] [data-htd-busy]')).not.toBeNull()
    expect(screen.getByRole('status')).toHaveTextContent('Loading')
  })

  it('T63: railLabel names the aside, defaulting to "Topic list"', () => {
    const { rerender } = render(rail())
    expect(screen.getByRole('complementary', { name: 'Topic list' })).toBeInTheDocument()
    rerender(rail({ railLabel: 'Notes' }))
    expect(screen.getByRole('complementary', { name: 'Notes' })).toBeInTheDocument()
  })

  it('T64: denseBottom uses pb-2 rather than pb-8', () => {
    const { rerender } = render(rail())
    const list = (): HTMLElement => document.querySelector('ul')!.parentElement!
    expect(list().className).toContain('pb-8')
    rerender(rail({ denseBottom: true }))
    expect(list().className).toContain('pb-2')
    expect(list().className).not.toContain('pb-8')
  })
})

describe('TopicDetail conformance vectors: filter', () => {
  it('T65: search.autoOpen opens the panel with the field focused', () => {
    render(rail({ title: 'Topics', search: { autoOpen: true } }))
    expect(field()).toHaveFocus()
    expect(document.querySelector('[data-htd-search]')).not.toBeNull()
  })

  it('T66: typing lists matches on label and sublabel and keeps every rail row', () => {
    render(rail({ title: 'Topics' }))
    fireEvent.click(filterButton())
    typeInto(field(), 'first')
    expect(options()).toEqual(['Alpha'])
    typeInto(field(), 'gam')
    expect(options()).toEqual(['Gamma'])
    expect(document.querySelectorAll('[data-htd-row]')).toHaveLength(ITEMS.length)
  })

  it('T67: the suggestion underlines "stan" in "İstanbul"', () => {
    render(rail({ title: 'Topics', items: [{ id: 'i', label: 'İstanbul' }] }))
    fireEvent.click(filterButton())
    typeInto(field(), 'stan')
    const match = screen.getByRole('option').querySelector('[data-htd-match]')!
    expect(match).toHaveTextContent(/^stan$/)
    expect(match.className).toContain('underline')
  })

  it('T68: Down at the last option wraps to the first, with the caret left alone', () => {
    render(rail({ title: 'Topics' }))
    fireEvent.click(filterButton())
    typeInto(field(), 'a')
    const selectedOption = (): string | undefined =>
      screen.getAllByRole('option').find((o) => o.getAttribute('aria-selected') === 'true')?.textContent ?? undefined
    expect(options()).toEqual(['Alpha', 'Beta', 'Gamma'])
    key('ArrowDown')
    key('ArrowDown')
    expect(selectedOption()).toBe('Gamma')
    const notCancelled = key('ArrowDown')
    expect(notCancelled).toBe(false)
    expect(selectedOption()).toBe('Alpha')
  })

  it('T69: Enter selects the highlighted row, closes the panel and clears the query', () => {
    const onSelect = vi.fn()
    render(rail({ title: 'Topics', onSelect }))
    fireEvent.click(filterButton())
    typeInto(field(), 'bet')
    key('Enter')
    expect(onSelect).toHaveBeenCalledWith('b')
    expect(screen.queryByRole('combobox')).toBeNull()
    fireEvent.click(filterButton())
    expect(field()).toHaveValue('')
  })

  it('T70: choosing the already-selected row does not call onSelect', () => {
    const onSelect = vi.fn()
    render(rail({ title: 'Topics', onSelect, selectedId: 'b' }))
    fireEvent.click(filterButton())
    typeInto(field(), 'bet')
    key('Enter')
    expect(onSelect).not.toHaveBeenCalled()
    expect(screen.queryByRole('combobox')).toBeNull()
  })

  it('T71: a disabled row that matches is not offered', () => {
    render(rail({ title: 'Topics', items: [...ITEMS, { id: 'd', label: 'Delta', disabled: true }] }))
    fireEvent.click(filterButton())
    typeInto(field(), 'ta')
    expect(options()).toEqual(['Beta'])
  })

  it('T72: with no match the panel says so and Enter keeps the field open', () => {
    const onSelect = vi.fn()
    render(rail({ title: 'Topics', onSelect }))
    fireEvent.click(filterButton())
    typeInto(field(), 'zzz')
    expect(screen.getByText('Nothing matches “zzz”.')).toBeInTheDocument()
    key('Enter')
    expect(field()).toBeInTheDocument()
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('T73: Escape closes, selects nothing, refocuses the button and does not reach a dialog', () => {
    const onSelect = vi.fn()
    const { container } = render(rail({ title: 'Topics', onSelect }))
    const dialogEscape = vi.fn()
    container.addEventListener('keydown', dialogEscape)
    fireEvent.click(filterButton())
    typeInto(field(), 'beta')
    key('Escape')
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(onSelect).not.toHaveBeenCalled()
    expect(filterButton()).toHaveFocus()
    expect(dialogEscape).not.toHaveBeenCalled()
  })

  it('T74: focus leaving closes the panel, but Tab onto the clear button keeps it open', async () => {
    const user = userEvent.setup()
    render(rail({ title: 'Topics' }))
    await user.click(filterButton())
    await user.tab()
    expect(screen.getByRole('button', { name: 'Clear filter' })).toHaveFocus()
    expect(screen.getByRole('combobox')).toBeInTheDocument()
    await user.tab()
    expect(screen.queryByRole('combobox')).toBeNull()
  })

  it('T75: Enter while an IME is composing chooses nothing', () => {
    const onSelect = vi.fn()
    render(rail({ title: 'Topics', onSelect }))
    fireEvent.click(filterButton())
    typeInto(field(), 'beta')
    key('Enter', { isComposing: true, keyCode: 229 })
    expect(onSelect).not.toHaveBeenCalled()
    expect(field()).toBeInTheDocument()
  })

  it('T76: live narrows the rail rows, keeps the selected row and leaves Enter to the host', () => {
    const onSelect = vi.fn()
    render(rail({ title: 'Topics', onSelect, selectedId: 'c', search: { live: true } }))
    fireEvent.click(filterButton())
    const box = screen.getByRole('searchbox')
    typeInto(box, 'beta')
    const labels = [...document.querySelectorAll('[data-htd-row]')].map((r) => r.textContent)
    expect(labels).toEqual(['Beta', 'Gamma'])
    expect(screen.queryByRole('listbox')).toBeNull()
    fireEvent.keyDown(box, { key: 'Enter' })
    expect(onSelect).not.toHaveBeenCalled()
    expect(screen.getByRole('searchbox')).toBeInTheDocument()
  })

  it('T77: a controlled query reports each keystroke, survives a blur, and clears once on Escape', () => {
    const onQueryChange = vi.fn()
    const host = (query: string): ReactElement => (
      <>
        <TopicRail {...railProps({ title: 'Topics', search: { query, onQueryChange } })} />
        <button type="button">Elsewhere</button>
      </>
    )
    const { rerender } = render(host(''))
    fireEvent.click(filterButton())
    typeInto(field(), 'g')
    typeInto(field(), 'ga')
    expect(onQueryChange.mock.calls).toEqual([['g'], ['ga']])
    rerender(host('ga'))
    onQueryChange.mockClear()
    fireEvent.blur(field(), { relatedTarget: screen.getByRole('button', { name: 'Elsewhere' }) })
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(onQueryChange).not.toHaveBeenCalled()
    fireEvent.click(filterButton())
    key('Escape')
    expect(onQueryChange.mock.calls).toEqual([['']])
  })

  it('T78: pending shows "Searching…" and offers no suggestions', () => {
    render(rail({ title: 'Topics', search: { query: 'a', onQueryChange: () => {}, pending: true, autoOpen: true } }))
    expect(screen.getByText('Searching…')).toBeInTheDocument()
    expect(screen.queryByRole('option')).toBeNull()
  })

  it('T79: the filter button is gold while a query is set and the panel is closed', () => {
    render(rail({ title: 'Topics', search: { query: 'be', onQueryChange: () => {} } }))
    expect(filterButton().className).toContain('text-apt-gold')
    cleanup()
    render(rail({ title: 'Topics' }))
    expect(filterButton().className).toContain('text-apt-text-muted')
  })
})

describe('TopicDetail conformance vectors: auto-fit', () => {
  it('T80: onFit reports the measured width inside railPx(150)..railPx(420)', () => {
    const restore = stubRowWidth(10)
    try {
      const onFit = vi.fn()
      render(rail({ items: [{ id: 'long', label: 'x'.repeat(30) }], onFit }))
      expect(onFit).toHaveBeenCalledWith(300)
      for (const [w] of onFit.mock.calls as number[][]) {
        expect(w).toBeGreaterThanOrEqual(railPx(MIN_FIT_RAIL))
        expect(w).toBeLessThanOrEqual(railPx(MAX_FIT_RAIL))
      }
      cleanup()
      const tooWide = vi.fn()
      render(rail({ items: [{ id: 'long', label: 'x'.repeat(90) }], onFit: tooWide }))
      expect(tooWide).toHaveBeenLastCalledWith(railPx(MAX_FIT_RAIL))
    } finally {
      restore()
    }
  })

  it('T81: no report while collapsed or while a query narrows the rows, and a full re-measure after clear', () => {
    const restore = stubRowWidth(10)
    try {
      const long: TopicDetailItem = { id: 'long', label: 'x'.repeat(30) }
      const onFit = vi.fn()
      const collapsed = render(rail({ items: [long], onFit, collapsed: true }))
      expect(onFit).not.toHaveBeenCalled()
      collapsed.unmount()
      const host = (query: string, items: TopicDetailItem[]): ReactElement =>
        rail({ title: 'Topics', items, onFit, search: { query, onQueryChange: () => {} } })
      const { rerender } = render(host('', [long, ...ITEMS]))
      expect(onFit).toHaveBeenCalledTimes(1)
      rerender(host('be', [ITEMS[1]!]))
      expect(onFit).toHaveBeenCalledTimes(1)
      rerender(host('', [long, ...ITEMS]))
      expect(onFit).toHaveBeenCalledTimes(2)
      expect(onFit).toHaveBeenLastCalledWith(300)
    } finally {
      restore()
    }
  })

  it('T82: re-fits wide enough for the toolbar when the host tools outgrow the rows', () => {
    const restore = stubRowWidth(10, (el) =>
      el.hasAttribute('data-htd-toolbar') ? (el.querySelector('[data-htd-tool-actions]') ? 260 : 40) : undefined,
    )
    try {
      const onFit = vi.fn()
      const { rerender } = render(rail({ title: 'Platforms', onFit }))
      expect(onFit).toHaveBeenLastCalledWith(railPx(MIN_FIT_RAIL))
      rerender(rail({ title: 'Platforms', onFit, titleActions: <button type="button">Auto Configure</button> }))
      expect(onFit).toHaveBeenLastCalledWith(260)
    } finally {
      restore()
    }
  })

  it('T83: description and leadsTo change nothing that is rendered', () => {
    const { container, rerender } = render(rail({ items: [{ id: 'a', label: 'Alpha' }] }))
    const before = container.innerHTML
    rerender(
      rail({ items: [{ id: 'a', label: 'Alpha', description: 'What it is for.', leadsTo: 'list' }] }),
    )
    expect(container.innerHTML).toBe(before)
    expect(screen.queryByText('What it is for.')).toBeNull()
  })
})
