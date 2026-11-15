import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, fireEvent, renderHook, act } from '@testing-library/react'
import { SearchDialog } from '../SearchDialog'
import { createSearchIndex } from '@adh-sdk/model'
import { useSearchState } from '@adh-sdk/model'
import type { SiteEntry, SearchState } from '@adh-sdk/model'

const entries: SiteEntry[] = [
  {
    slug: '/guides/install',
    section: 'guides',
    raw: '',
    html: '',
    headings: [],
    frontmatter: { title: 'Install', summary: 'How to install' },
  },
  {
    slug: '/api/auth',
    section: 'api',
    raw: '',
    html: '',
    headings: [],
    frontmatter: { title: 'Authentication', summary: 'API auth' },
  },
]

function makeState() {
  const index = createSearchIndex(entries)
  return renderHook(() => useSearchState(index))
}

describe('SearchDialog', () => {
  it('renders nothing when closed', () => {
    const { result } = makeState()
    const { container } = render(
      <SearchDialog open={false} onClose={() => {}} state={result.current} onSelect={() => {}} />,
    )
    expect(container.querySelector('.awt-search-dialog')).toBeNull()
  })

  it('renders panel and input when open', () => {
    const { result } = makeState()
    const { container } = render(
      <SearchDialog open={true} onClose={() => {}} state={result.current} onSelect={() => {}} />,
    )
    expect(container.querySelector('.awt-search-dialog')).not.toBeNull()
    expect(container.querySelector('.awt-search-dialog__input')).not.toBeNull()
  })

  it('calls onClose when backdrop clicked', () => {
    const { result } = makeState()
    const onClose = vi.fn()
    const { container } = render(
      <SearchDialog open={true} onClose={onClose} state={result.current} onSelect={() => {}} />,
    )
    fireEvent.click(container.querySelector('.awt-search-dialog__backdrop')!)
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('shows results after typing', () => {
    const { result } = makeState()
    act(() => {
      result.current.setQuery('install')
    })
    const { container } = render(
      <SearchDialog open={true} onClose={() => {}} state={result.current} onSelect={() => {}} />,
    )
    const titles = Array.from(container.querySelectorAll('.awt-search-dialog__result-title')).map(
      (n) => n.textContent,
    )
    expect(titles).toContain('Install')
  })

  it('calls onSelect with entry on Enter', () => {
    const { result } = makeState()
    act(() => {
      result.current.setQuery('install')
    })
    const onSelect = vi.fn()
    const { container } = render(
      <SearchDialog open={true} onClose={() => {}} state={result.current} onSelect={onSelect} />,
    )
    const input = container.querySelector('.awt-search-dialog__input') as HTMLInputElement
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect.mock.calls[0][0].slug).toBe('/guides/install')
  })

  it('calls onClose on Escape', () => {
    const { result } = makeState()
    const onClose = vi.fn()
    const { container } = render(
      <SearchDialog open={true} onClose={onClose} state={result.current} onSelect={() => {}} />,
    )
    const input = container.querySelector('.awt-search-dialog__input') as HTMLInputElement
    fireEvent.keyDown(input, { key: 'Escape' })
    expect(onClose).toHaveBeenCalled()
  })

  it('shows empty state when no results', () => {
    const { result } = makeState()
    act(() => {
      result.current.setQuery('xyzzy-no-match')
    })
    const { container } = render(
      <SearchDialog open={true} onClose={() => {}} state={result.current} onSelect={() => {}} />,
    )
    expect(container.querySelector('.awt-search-dialog__empty')).not.toBeNull()
  })
})

// ---------------------------------------------------------------------------
// Conformance vectors (cookbook/controls/search-dialog/conformance-test-vectors.md)
// ---------------------------------------------------------------------------

function mkEntry(slug: string, section: string | undefined, title: string, summary?: string): SiteEntry {
  return {
    slug,
    section,
    raw: '',
    html: '',
    headings: [],
    frontmatter: summary === undefined ? { title } : { title, summary },
  } as SiteEntry
}

function fakeState(over: Partial<SearchState> & { entries?: SiteEntry[] } = {}): SearchState {
  const { entries: es = [], ...rest } = over
  return {
    query: '',
    setQuery: vi.fn(),
    results: es.map((entry) => ({ entry, score: 0 })),
    selectedIndex: 0,
    setSelectedIndex: vi.fn(),
    handleKey: vi.fn(),
    reset: vi.fn(),
    ...rest,
  }
}

const interleaved = [
  mkEntry('/a', 'guides', 'A'),
  mkEntry('/b', 'api', 'B'),
  mkEntry('/c', 'api', 'C'),
  mkEntry('/d', 'guides', 'D'),
]

function openDialog(
  state: SearchState,
  extra: Partial<React.ComponentProps<typeof SearchDialog>> = {},
) {
  const onClose = vi.fn()
  const onSelect = vi.fn()
  const utils = render(
    <SearchDialog open={true} onClose={onClose} state={state} onSelect={onSelect} {...extra} />,
  )
  const input = utils.container.querySelector('input') as HTMLInputElement
  return { ...utils, onClose, onSelect, input }
}

describe('SearchDialog conformance vectors', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('search-dialog-001 returns null when closed', () => {
    const { container } = render(
      <SearchDialog open={false} onClose={() => {}} state={fakeState()} onSelect={() => {}} />,
    )
    expect(container.firstChild).toBeNull()
  })

  it('search-dialog-002 open dialog has role dialog and aria-modal', () => {
    const { container } = openDialog(fakeState())
    const root = container.firstElementChild as HTMLElement
    expect(root.getAttribute('role')).toBe('dialog')
    expect(root.getAttribute('aria-modal')).toBe('true')
  })

  it('search-dialog-003 backdrop click calls onClose', () => {
    const { container, onClose } = openDialog(fakeState())
    fireEvent.click(container.querySelector('.awt-search-dialog__backdrop')!)
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('search-dialog-004 focuses the input after opening (deferred by requestAnimationFrame)', () => {
    vi.stubGlobal('requestAnimationFrame', (cb: FrameRequestCallback) => {
      cb(0)
      return 0
    })
    const state = fakeState()
    const { rerender, container } = render(
      <SearchDialog open={false} onClose={() => {}} state={state} onSelect={() => {}} />,
    )
    rerender(<SearchDialog open={true} onClose={() => {}} state={state} onSelect={() => {}} />)
    expect(document.activeElement).toBe(container.querySelector('input'))
  })

  it('search-dialog-005 resets search state on open (query cleared, selectedIndex 0)', () => {
    const { result } = makeState()
    act(() => {
      result.current.setQuery('install')
      result.current.setSelectedIndex(1)
    })
    const resetSpy = vi.fn(() => result.current.reset())
    const wrapped = { ...result.current, reset: resetSpy }
    const { rerender } = render(
      <SearchDialog open={false} onClose={() => {}} state={wrapped} onSelect={() => {}} />,
    )
    expect(resetSpy).not.toHaveBeenCalled()
    act(() => {
      rerender(<SearchDialog open={true} onClose={() => {}} state={wrapped} onSelect={() => {}} />)
    })
    expect(resetSpy).toHaveBeenCalledTimes(1)
    expect(result.current.query).toBe('')
    expect(result.current.results).toEqual([])
    expect(result.current.selectedIndex).toBe(0)
  })

  it('search-dialog-006 input row is a form with the search icon and the input', () => {
    const { container } = openDialog(fakeState())
    const form = container.querySelector('form')!
    expect(form).not.toBeNull()
    expect(form.querySelector('svg')).not.toBeNull()
    expect(form.querySelector('input')).not.toBeNull()
  })

  it('search-dialog-007 renders the Esc hint', () => {
    const { container } = openDialog(fakeState())
    expect(container.querySelector('kbd')!.textContent).toBe('Esc')
  })

  it('search-dialog-008 default placeholder', () => {
    const { input } = openDialog(fakeState())
    expect(input.placeholder).toBe('Search documentation...')
  })

  it('search-dialog-009 custom placeholder', () => {
    const { input } = openDialog(fakeState(), { placeholder: 'Find items' })
    expect(input.placeholder).toBe('Find items')
  })

  it('search-dialog-010 Escape in the input calls onClose', () => {
    const state = fakeState()
    const { input, onClose } = openDialog(state)
    fireEvent.keyDown(input, { key: 'Escape' })
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(state.handleKey).not.toHaveBeenCalled()
  })

  it('search-dialog-011 Enter selects the highlighted result', () => {
    const es = [mkEntry('/x', 'guides', 'X'), mkEntry('/y', 'guides', 'Y')]
    const { input, onSelect } = openDialog(fakeState({ query: 'q', entries: es, selectedIndex: 1 }))
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect).toHaveBeenCalledWith(es[1])
  })

  it('search-dialog-012 Enter with selectedIndex -1 invokes nothing', () => {
    const es = [mkEntry('/x', 'guides', 'X')]
    const { input, onSelect, onClose } = openDialog(
      fakeState({ query: 'q', entries: es, selectedIndex: -1 }),
    )
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).not.toHaveBeenCalled()
    expect(onClose).not.toHaveBeenCalled()
  })

  it('search-dialog-013 other keys are delegated to state.handleKey', () => {
    const state = fakeState()
    const { input } = openDialog(state)
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    expect(state.handleKey).toHaveBeenCalledTimes(1)
    expect((state.handleKey as ReturnType<typeof vi.fn>).mock.calls[0][0].key).toBe('ArrowDown')
  })

  it('search-dialog-014 typing calls setQuery for each keystroke and updates the input', () => {
    const setQuery = vi.fn()
    function Harness() {
      const s = useSearchState(createSearchIndex(entries))
      return (
        <SearchDialog
          open={true}
          onClose={() => {}}
          state={{
            ...s,
            setQuery: (q) => {
              setQuery(q)
              s.setQuery(q)
            },
          }}
          onSelect={() => {}}
        />
      )
    }
    const { container } = render(<Harness />)
    const input = container.querySelector('input') as HTMLInputElement
    for (const v of ['t', 'te', 'tes', 'test']) fireEvent.change(input, { target: { value: v } })
    expect(setQuery.mock.calls.map((c) => c[0])).toEqual(['t', 'te', 'tes', 'test'])
    expect(input.value).toBe('test')
  })

  it('search-dialog-015 no results section when the query is empty', () => {
    const { container } = openDialog(fakeState({ query: '', entries: interleaved }))
    expect(container.querySelector('.awt-search-dialog__results')).toBeNull()
  })

  it('search-dialog-016 results section rendered when querying', () => {
    const { container } = openDialog(fakeState({ query: 'docs', entries: interleaved }))
    expect(container.querySelector('.awt-search-dialog__results')).not.toBeNull()
    const none = openDialog(fakeState({ query: 'docs' }))
    expect(none.container.querySelector('.awt-search-dialog__empty')).not.toBeNull()
  })

  it('search-dialog-017 only the top 20 of 50 results are rendered', () => {
    const many = Array.from({ length: 50 }, (_, i) => mkEntry(`/p${i}`, 'guides', `T${i}`))
    const { container } = openDialog(fakeState({ query: 'q', entries: many }))
    const titles = Array.from(container.querySelectorAll('.awt-search-dialog__result-title')).map(
      (n) => n.textContent,
    )
    expect(titles).toHaveLength(20)
    expect(titles[0]).toBe('T0')
    expect(titles[19]).toBe('T19')
  })

  it('search-dialog-018 groups by section in first-occurrence order', () => {
    const { container } = openDialog(fakeState({ query: 'q', entries: interleaved }))
    const labels = Array.from(container.querySelectorAll('.awt-search-dialog__section-label')).map(
      (n) => n.textContent,
    )
    expect(labels).toEqual(['guides', 'api'])
  })

  it('search-dialog-019 result without a section is grouped under other', () => {
    const { container } = openDialog(
      fakeState({ query: 'q', entries: [mkEntry('/n', undefined, 'N')] }),
    )
    expect(container.querySelector('.awt-search-dialog__section-label')!.textContent).toBe('other')
  })

  it('search-dialog-020 sectionLabels maps the section name', () => {
    const { container } = openDialog(fakeState({ query: 'q', entries: interleaved }), {
      sectionLabels: { guides: 'How-To Guides' },
    })
    const labels = Array.from(container.querySelectorAll('.awt-search-dialog__section-label')).map(
      (n) => n.textContent,
    )
    expect(labels).toEqual(['How-To Guides', 'api'])
  })

  it('search-dialog-021 section shown verbatim when no label is provided', () => {
    const { container } = openDialog(
      fakeState({ query: 'q', entries: [mkEntry('/b', 'api', 'B')] }),
      { sectionLabels: {} },
    )
    expect(container.querySelector('.awt-search-dialog__section-label')!.textContent).toBe('api')
  })

  it('search-dialog-022 empty state message uses curly quotes', () => {
    const { container } = openDialog(fakeState({ query: 'xyzabc' }))
    expect(container.querySelector('.awt-search-dialog__empty')!.textContent).toBe(
      'No results for “xyzabc”',
    )
  })

  it('search-dialog-023 each result shows its title', () => {
    const { container } = openDialog(fakeState({ query: 'q', entries: interleaved }))
    const titles = Array.from(container.querySelectorAll('.awt-search-dialog__result-title')).map(
      (n) => n.textContent,
    )
    expect(titles.sort()).toEqual(['A', 'B', 'C', 'D'])
  })

  it('search-dialog-024 a result with a summary shows it after the title', () => {
    const { container } = openDialog(
      fakeState({ query: 'q', entries: [mkEntry('/s', 'guides', 'Title', 'Some summary')] }),
    )
    const body = container.querySelector('.awt-search-dialog__result-body')!
    expect(body.children[0].textContent).toBe('Title')
    expect(body.children[1].className).toBe('awt-search-dialog__result-summary')
    expect(body.children[1].textContent).toBe('Some summary')
  })

  it('search-dialog-025 a result without a summary renders no summary element', () => {
    const { container } = openDialog(
      fakeState({ query: 'q', entries: [mkEntry('/s', 'guides', 'Title')] }),
    )
    expect(container.querySelector('.awt-search-dialog__result-summary')).toBeNull()
  })

  it('search-dialog-026 results are button type=button', () => {
    const { container } = openDialog(fakeState({ query: 'q', entries: interleaved }))
    const rows = container.querySelectorAll('.awt-search-dialog__result')
    expect(rows).toHaveLength(4)
    rows.forEach((r) => {
      expect(r.tagName).toBe('BUTTON')
      expect(r.getAttribute('type')).toBe('button')
    })
  })

  it('search-dialog-027 clicking a result calls onSelect with its entry', () => {
    const { container, onSelect } = openDialog(fakeState({ query: 'q', entries: interleaved }))
    const rows = container.querySelectorAll('.awt-search-dialog__result')
    fireEvent.click(rows[2])
    // grouped position 2 is B (guides: A, D; api: B, C)
    expect(onSelect).toHaveBeenCalledWith(interleaved[1])
  })

  it('search-dialog-028 highlights the row at grouped position selectedIndex', () => {
    const { container } = openDialog(
      fakeState({ query: 'q', entries: interleaved, selectedIndex: 2 }),
    )
    const rows = Array.from(container.querySelectorAll('.awt-search-dialog__result'))
    const selected = rows.filter((r) => r.classList.contains('awt-search-dialog__result--selected'))
    expect(selected).toHaveLength(1)
    expect(rows.indexOf(selected[0])).toBe(2)
    expect(selected[0].textContent).toContain('B')
  })

  it('search-dialog-029 selectedIndex beyond the rendered results highlights nothing', () => {
    const { container } = openDialog(
      fakeState({ query: 'q', entries: interleaved, selectedIndex: 999 }),
    )
    expect(container.querySelector('.awt-search-dialog__result--selected')).toBeNull()
  })

  it('search-dialog-030 result identity follows slug when entries are reordered', () => {
    const a = mkEntry('/a', 'guides', 'A')
    const b = mkEntry('/b', 'guides', 'B')
    const props = { open: true, onClose: () => {}, onSelect: () => {} }
    const { container, rerender } = render(
      <SearchDialog {...props} state={fakeState({ query: 'q', entries: [a, b] })} />,
    )
    const find = (t: string) =>
      Array.from(container.querySelectorAll('.awt-search-dialog__result')).find((r) =>
        r.textContent?.includes(t),
      )
    const nodeA = find('A')
    const nodeB = find('B')
    rerender(<SearchDialog {...props} state={fakeState({ query: 'q', entries: [b, a] })} />)
    expect(find('A')).toBe(nodeA)
    expect(find('B')).toBe(nodeB)
    expect(container.querySelectorAll('.awt-search-dialog__result')[0]).toBe(nodeB)
  })

  it('search-dialog-031 form submit is default-prevented', () => {
    const { container } = openDialog(fakeState())
    const notPrevented = fireEvent.submit(container.querySelector('form')!)
    expect(notPrevented).toBe(false)
  })

  it('search-dialog-032 form has role search', () => {
    const { container } = openDialog(fakeState())
    expect(container.querySelector('form')!.getAttribute('role')).toBe('search')
  })

  it('search-dialog-033 input carries the autofill suppression attributes', () => {
    const { input } = openDialog(fakeState())
    expect(input.getAttribute('autocomplete')).toBe('off')
    expect(input.getAttribute('data-form-type')).toBe('other')
    expect(input.getAttribute('data-1p-ignore')).toBe('true')
    expect(input.getAttribute('data-lpignore')).toBe('true')
    expect(input.getAttribute('data-bwignore')).toBe('true')
    expect(input.getAttribute('data-protonpass-ignore')).toBe('true')
  })

  it('search-dialog-034 Enter selects the highlighted row (D), not state.results[1] (B)', () => {
    const { input, onSelect } = openDialog(
      fakeState({ query: 'q', entries: interleaved, selectedIndex: 1 }),
    )
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).toHaveBeenCalledWith(interleaved[3])
  })

  it('search-dialog-035 Enter with selectedIndex beyond the results invokes nothing', () => {
    const es = [mkEntry('/x', 'guides', 'X'), mkEntry('/y', 'guides', 'Y')]
    const { input, onSelect, onClose } = openDialog(
      fakeState({ query: 'docs', entries: es, selectedIndex: 999 }),
    )
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSelect).not.toHaveBeenCalled()
    expect(onClose).not.toHaveBeenCalled()
  })

  it('search-dialog-036 a result with an undefined title renders an empty title and does not throw', () => {
    const e = { ...mkEntry('/t', 'guides', 'x'), frontmatter: {} } as unknown as SiteEntry
    const { container } = openDialog(fakeState({ query: 'q', entries: [e] }))
    expect(container.querySelector('.awt-search-dialog__result-title')!.textContent).toBe('')
  })

  it('search-dialog-037 reset is called once per false-to-true transition', () => {
    const state = fakeState()
    const p = { onClose: () => {}, onSelect: () => {}, state }
    const { rerender } = render(<SearchDialog open={false} {...p} />)
    rerender(<SearchDialog open={true} {...p} />)
    rerender(<SearchDialog open={false} {...p} />)
    rerender(<SearchDialog open={true} {...p} />)
    expect(state.reset).toHaveBeenCalledTimes(2)
  })
})
