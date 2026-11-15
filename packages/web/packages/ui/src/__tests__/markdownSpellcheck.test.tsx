/**
 * Unit tests for MarkdownSpellCheck — the off-by-default editor-toolbar control
 * that lints the markdown source via harper.js and lists problems in a popover.
 *
 * The real linter loads harper's WASM in a Web Worker, which jsdom cannot run, so
 * every test injects a fake `MarkdownLinter` via the `createLinter` DI seam. That
 * also lets us assert the lazy contract: harper is never reached until the toggle
 * is first enabled.
 */
import * as React from 'react'
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react'
import { renderToString } from 'react-dom/server'
import { describe, it, expect, vi, afterEach } from 'vitest'
import {
  createHarperLinter,
  MarkdownSpellCheck,
  type MarkdownLinter,
  type SpellIssue,
} from '../components/markdown-spellcheck'

// harper.js is mocked for T9 only; every other test injects a fake linter via `createLinter`.
const harperMock = vi.hoisted(() => ({
  workerCtor: vi.fn(),
  localCtor: vi.fn(),
  lint: vi.fn(async (_text: string, _opts: unknown): Promise<unknown[]> => []),
}))
vi.mock('harper.js', () => ({
  Dialect: { American: 0 },
  WorkerLinter: class {
    constructor(init: unknown) {
      harperMock.workerCtor(init)
    }
    lint(text: string, opts: unknown) {
      return harperMock.lint(text, opts)
    }
    applySuggestion() {
      return Promise.resolve('')
    }
    dispose() {
      return Promise.resolve()
    }
  },
  LocalLinter: class {
    constructor(init: unknown) {
      harperMock.localCtor(init)
    }
  },
}))
vi.mock('harper.js/binaryInlined', () => ({ binaryInlined: 'data:fake' }))

afterEach(() => {
  vi.useRealTimers()
})

// A trivial fake linter: flags every "teh" as a misspelling of "the". Pure JS —
// no WASM, no worker.
function makeFakeLinter(): MarkdownLinter {
  const find = (source: string): SpellIssue[] => {
    const issues: SpellIssue[] = []
    const re = /teh/g
    let m: RegExpExecArray | null
    while ((m = re.exec(source)) !== null) {
      issues.push({
        start: m.index,
        end: m.index + 3,
        flagged: 'teh',
        message: 'Did you mean "the"?',
        suggestions: ['the'],
      })
    }
    return issues
  }
  return {
    async lint(source) {
      return find(source)
    },
    async apply(source, issueIndex, suggestionIndex) {
      const issue = find(source)[issueIndex]
      if (!issue) return source
      const replacement = issue.suggestions[suggestionIndex] ?? ''
      return source.slice(0, issue.start) + replacement + source.slice(issue.end)
    },
    dispose() {},
  }
}

function toggle(): HTMLElement {
  return screen.getByRole('button', { name: 'Check spelling' })
}

function Harness({ initial }: { initial: string }): React.ReactElement {
  const [value, setValue] = React.useState(initial)
  const createLinter = React.useMemo(() => makeFakeLinter, [])
  return (
    <>
      <MarkdownSpellCheck
        value={value}
        onApply={setValue}
        createLinter={createLinter}
        debounceMs={0}
      />
      <span data-testid="src">{value}</span>
    </>
  )
}

describe('MarkdownSpellCheck — toggle', () => {
  it('renders an off-by-default, labelled toggle and checks nothing until enabled', () => {
    render(
      <MarkdownSpellCheck
        value="teh cat"
        onApply={vi.fn()}
        createLinter={makeFakeLinter}
      />,
    )
    const btn = toggle()
    expect(btn).toBeInTheDocument()
    expect(btn).toHaveAttribute('aria-pressed', 'false')
    // The panel (and any lint output) stays out of the DOM while off.
    expect(screen.queryByText('Did you mean "the"?')).toBeNull()
  })

  it('does not build the linter until the toggle is enabled (lazy)', async () => {
    const createLinter = vi.fn(makeFakeLinter)
    render(
      <MarkdownSpellCheck
        value="teh"
        onApply={vi.fn()}
        createLinter={createLinter}
        debounceMs={0}
      />,
    )
    expect(createLinter).not.toHaveBeenCalled()
    fireEvent.click(toggle())
    await waitFor(() => expect(createLinter).toHaveBeenCalledTimes(1))
  })
})

describe('MarkdownSpellCheck — linting', () => {
  it('lints the source and lists the problem when enabled', async () => {
    render(
      <MarkdownSpellCheck
        value="teh cat sat"
        onApply={vi.fn()}
        createLinter={makeFakeLinter}
        debounceMs={0}
      />,
    )
    fireEvent.click(toggle())
    expect(await screen.findByText('Did you mean "the"?')).toBeInTheDocument()
    expect(screen.getByText('teh')).toBeInTheDocument()
    // The toggle reflects the active state.
    expect(toggle()).toHaveAttribute('aria-pressed', 'true')
    // An apply-suggestion action is offered for the flagged text.
    expect(
      screen.getByRole('button', { name: /Replace .*teh.* with .*the.*/ }),
    ).toBeInTheDocument()
  })

  it('shows an empty state when the source is clean', async () => {
    render(
      <MarkdownSpellCheck
        value="the cat sat"
        onApply={vi.fn()}
        createLinter={makeFakeLinter}
        debounceMs={0}
      />,
    )
    fireEvent.click(toggle())
    expect(await screen.findByText('No issues found.')).toBeInTheDocument()
  })
})

describe('MarkdownSpellCheck — apply', () => {
  it('applies a suggestion and edits the source', async () => {
    render(<Harness initial="teh cat" />)
    fireEvent.click(toggle())
    const apply = await screen.findByRole('button', {
      name: /Replace .*teh.* with .*the.*/,
    })
    fireEvent.click(apply)
    await waitFor(() =>
      expect(screen.getByTestId('src')).toHaveTextContent('the cat'),
    )
  })
})

// ---- Conformance vectors (recipe ui/components/actions/markdown-spellcheck) ----

function issue(flagged: string, suggestions: string[] = ['x'], start = 0): SpellIssue {
  return { start, end: start + flagged.length, flagged, message: `msg ${flagged}`, suggestions }
}

interface Deferred<T> {
  promise: Promise<T>
  resolve: (v: T) => void
  reject: (e: unknown) => void
}
function deferred<T>(): Deferred<T> {
  let resolve!: (v: T) => void
  let reject!: (e: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

function linterOf(
  lint: (source: string) => Promise<SpellIssue[]>,
  extra: Partial<MarkdownLinter> = {},
): MarkdownLinter {
  return {
    lint,
    apply: async (source) => source,
    dispose() {},
    ...extra,
  }
}

function renderWith(
  linter: MarkdownLinter,
  value = 'src',
  props: Partial<React.ComponentProps<typeof MarkdownSpellCheck>> = {},
) {
  const onApply = vi.fn()
  const createLinter = vi.fn(() => linter)
  const ui = (v: string): React.ReactElement => (
    <MarkdownSpellCheck value={v} onApply={onApply} createLinter={createLinter} debounceMs={0} {...props} />
  )
  const utils = render(ui(value))
  const again = (next: string): void => utils.rerender(ui(next))
  return { ...utils, onApply, createLinter, again }
}

describe('MarkdownSpellCheck conformance vectors', () => {
  it('T1 default off: one named toggle, aria-pressed false, no panel text', () => {
    renderWith(makeFakeLinter(), 'teh cat')
    expect(screen.getAllByRole('button')).toHaveLength(1)
    expect(toggle()).toHaveAttribute('aria-pressed', 'false')
    expect(screen.queryByText('Spelling & grammar')).toBeNull()
    expect(screen.queryByText('Checking…')).toBeNull()
    expect(screen.queryByText('No issues found.')).toBeNull()
  })

  it('T2 createLinter is not called on render, exactly once after enabling', async () => {
    const { createLinter } = renderWith(makeFakeLinter(), 'teh')
    expect(createLinter).not.toHaveBeenCalled()
    fireEvent.click(toggle())
    await screen.findByText('Did you mean "the"?')
    expect(createLinter).toHaveBeenCalledTimes(1)
  })

  it('T3 lists the flagged text, message and an apply action; toggle pressed', async () => {
    renderWith(makeFakeLinter(), 'teh cat sat')
    fireEvent.click(toggle())
    expect(await screen.findByText('Did you mean "the"?')).toBeInTheDocument()
    expect(screen.getByText('teh')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Replace “teh” with “the”' })).toBeInTheDocument()
    expect(toggle()).toHaveAttribute('aria-pressed', 'true')
  })

  it('T4 shows "No issues found." for clean source', async () => {
    renderWith(makeFakeLinter(), 'the cat sat')
    fireEvent.click(toggle())
    expect(await screen.findByText('No issues found.')).toBeInTheDocument()
  })

  it('T5 apply is called with the second problem index against the latest lint', async () => {
    const lint = vi
      .fn<(s: string) => Promise<SpellIssue[]>>()
      .mockResolvedValueOnce([issue('teh', ['the']), issue('recieve', ['receive'], 4)])
      .mockResolvedValue([issue('foo', ['f1']), issue('bar', ['b1'], 4)])
    const apply = vi.fn(async (_s: string, _i: number, _j: number): Promise<string> => 'applied')
    const { again, onApply } = renderWith(linterOf(lint, { apply }), 'v1')
    fireEvent.click(toggle())
    await screen.findByText('msg teh')
    again('v2')
    await screen.findByText('msg foo')
    expect(screen.queryByText('msg teh')).toBeNull()
    fireEvent.click(screen.getByRole('button', { name: /Replace .*bar.* with .*b1.*/ }))
    await waitFor(() => expect(onApply).toHaveBeenCalledWith('applied'))
    expect(apply).toHaveBeenCalledTimes(1)
    expect(apply).toHaveBeenCalledWith('v2', 1, 0)
  })

  it('T6 a rejecting createLinter shows the unavailable state', async () => {
    render(
      <MarkdownSpellCheck
        value="x"
        onApply={vi.fn()}
        debounceMs={0}
        createLinter={() => Promise.reject(new Error('no wasm'))}
      />,
    )
    fireEvent.click(toggle())
    expect(await screen.findByText('Spell check is unavailable in this browser.')).toBeInTheDocument()
  })

  it('T7 re-enabling shows "Checking…", not the cleared list', async () => {
    const pending = deferred<SpellIssue[]>()
    const lint = vi
      .fn<(s: string) => Promise<SpellIssue[]>>()
      .mockResolvedValueOnce([issue('teh', ['the'])])
      .mockReturnValue(pending.promise)
    renderWith(linterOf(lint), 'teh')
    fireEvent.click(toggle())
    await screen.findByText('msg teh')
    fireEvent.click(toggle())
    await waitFor(() => expect(toggle()).toHaveAttribute('aria-pressed', 'false'))
    expect(screen.queryByText('msg teh')).toBeNull()
    fireEvent.click(toggle())
    expect(await screen.findByText('Checking…')).toBeInTheDocument()
    expect(screen.queryByText('msg teh')).toBeNull()
  })

  it('T8 a burst of source changes coalesces into one re-lint after debounceMs', async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] })
    const lint = vi.fn(async (_s: string): Promise<SpellIssue[]> => [])
    const { again } = renderWith(linterOf(lint), 'a', { debounceMs: 600 })
    fireEvent.click(toggle())
    await act(async () => {
      await vi.advanceTimersByTimeAsync(0)
    })
    expect(lint).toHaveBeenCalledTimes(1)
    for (const next of ['ab', 'abc', 'abcd']) {
      act(() => again(next))
      await act(async () => {
        await vi.advanceTimersByTimeAsync(100)
      })
    }
    expect(lint).toHaveBeenCalledTimes(1)
    await act(async () => {
      await vi.advanceTimersByTimeAsync(600)
    })
    expect(lint).toHaveBeenCalledTimes(2)
    expect(lint).toHaveBeenLastCalledWith('abcd')
  })

  it('T9 createHarperLinter builds a WorkerLinter and lints in markdown mode with dedup', async () => {
    harperMock.workerCtor.mockClear()
    harperMock.localCtor.mockClear()
    harperMock.lint.mockClear()
    const linter = await createHarperLinter()
    await linter.lint('some *markdown*')
    expect(harperMock.workerCtor).toHaveBeenCalledTimes(1)
    expect(harperMock.localCtor).not.toHaveBeenCalled()
    expect(harperMock.lint).toHaveBeenCalledWith('some *markdown*', { language: 'markdown', dedup: true })
  })

  it('T10 server-rendering the closed control does not throw or build a linter', () => {
    // jsdom always defines window, so this uses the server renderer (renderToString) rather than
    // deleting globals; effects never run there, which is what keeps harper unloaded.
    const createLinter = vi.fn(makeFakeLinter)
    const html = renderToString(
      <MarkdownSpellCheck value="teh" onApply={() => {}} createLinter={createLinter} />,
    )
    expect(html).toContain('Check spelling')
    expect(createLinter).not.toHaveBeenCalled()
  })

  it('T11 dispose is called exactly once on unmount', async () => {
    const dispose = vi.fn()
    const { unmount } = renderWith(linterOf(async () => [], { dispose }))
    fireEvent.click(toggle())
    await screen.findByText('No issues found.')
    unmount()
    await waitFor(() => expect(dispose).toHaveBeenCalledTimes(1))
  })

  it('T12 a Remove suggestion reads "Remove" and applying it deletes the flagged span', async () => {
    const lint = async (): Promise<SpellIssue[]> => [
      { start: 2, end: 7, flagged: 'very ', message: 'redundant', suggestions: [''] },
    ]
    const apply = async (src: string, _i: number, _j: number): Promise<string> => src.slice(0, 2) + src.slice(7)
    const { onApply } = renderWith(linterOf(lint, { apply }), 'a very big dog')
    fireEvent.click(toggle())
    const chip = await screen.findByRole('button', { name: /Replace .* with .*nothing.*/ })
    expect(chip).toHaveTextContent('Remove')
    fireEvent.click(chip)
    await waitFor(() => expect(onApply).toHaveBeenCalledWith('a big dog'))
  })

  it('T13 an older lint resolving after a newer one does not replace it', async () => {
    const d1 = deferred<SpellIssue[]>()
    const d2 = deferred<SpellIssue[]>()
    const lint = vi
      .fn<(s: string) => Promise<SpellIssue[]>>()
      .mockReturnValueOnce(d1.promise)
      .mockReturnValueOnce(d2.promise)
      .mockResolvedValue([])
    const { again } = renderWith(linterOf(lint), 'v1')
    fireEvent.click(toggle())
    await waitFor(() => expect(lint).toHaveBeenCalledTimes(1))
    again('v2')
    await waitFor(() => expect(lint).toHaveBeenCalledTimes(2))
    await act(async () => {
      d2.resolve([issue('newer')])
    })
    await screen.findByText('msg newer')
    await act(async () => {
      d1.resolve([issue('older')])
    })
    expect(screen.getByText('msg newer')).toBeInTheDocument()
    expect(screen.queryByText('msg older')).toBeNull()
  })

  it('T14 Escape turns the check off, clears problems and refocuses the toggle', async () => {
    renderWith(makeFakeLinter(), 'teh')
    fireEvent.click(toggle())
    await screen.findByText('Did you mean "the"?')
    fireEvent.keyDown(document.body, { key: 'Escape' })
    await waitFor(() => expect(toggle()).toHaveAttribute('aria-pressed', 'false'))
    expect(screen.queryByText('Did you mean "the"?')).toBeNull()
    await waitFor(() => expect(toggle()).toHaveFocus())
  })

  it('T14 an outside click turns the check off, clears problems and refocuses the toggle', async () => {
    render(
      <div>
        <button type="button">outside</button>
        <MarkdownSpellCheck value="teh" onApply={() => {}} createLinter={makeFakeLinter} debounceMs={0} />
      </div>,
    )
    fireEvent.click(toggle())
    await screen.findByText('Did you mean "the"?')
    const outside = screen.getByRole('button', { name: 'outside' })
    fireEvent.pointerDown(outside)
    fireEvent.mouseDown(outside)
    fireEvent.pointerUp(outside)
    fireEvent.mouseUp(outside)
    fireEvent.click(outside)
    await waitFor(() => expect(toggle()).toHaveAttribute('aria-pressed', 'false'))
    expect(screen.queryByText('Did you mean "the"?')).toBeNull()
    await waitFor(() => expect(toggle()).toHaveFocus())
  })

  it('T15 the toggle shows a count badge of three', async () => {
    renderWith(linterOf(async () => [issue('a', ['x'], 0), issue('b', ['x'], 2), issue('c', ['x'], 4)]), 'a b c')
    fireEvent.click(toggle())
    await screen.findByText('msg a')
    expect(toggle()).toHaveTextContent('3')
  })

  it('T16 a pending re-lint keeps the prior list and shows no "Checking…"', async () => {
    const pending = deferred<SpellIssue[]>()
    const lint = vi
      .fn<(s: string) => Promise<SpellIssue[]>>()
      .mockResolvedValueOnce([issue('teh', ['the'])])
      .mockReturnValue(pending.promise)
    const { again } = renderWith(linterOf(lint), 'v1')
    fireEvent.click(toggle())
    await screen.findByText('msg teh')
    again('v2')
    await waitFor(() => expect(lint).toHaveBeenCalledTimes(2))
    expect(screen.getByText('msg teh')).toBeInTheDocument()
    expect(screen.queryByText('Checking…')).toBeNull()
  })

  it('T17 only the first four of six suggestions render as apply actions', async () => {
    renderWith(linterOf(async () => [issue('teh', ['s1', 's2', 's3', 's4', 's5', 's6'])]), 'teh')
    fireEvent.click(toggle())
    await screen.findByText('msg teh')
    expect(screen.getAllByRole('button', { name: /^Replace / })).toHaveLength(4)
    expect(screen.queryByText('s5')).toBeNull()
  })

  it('T18 a problem with no suggestions shows "No suggestion." and no apply action', async () => {
    renderWith(linterOf(async () => [issue('teh', [])]), 'teh')
    fireEvent.click(toggle())
    await screen.findByText('msg teh')
    expect(screen.getByText('No suggestion.')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /^Replace / })).toBeNull()
  })

  it('T19 a rejecting lint() shows the unavailable state', async () => {
    renderWith(linterOf(() => Promise.reject(new Error('boom'))), 'x')
    fireEvent.click(toggle())
    expect(await screen.findByText('Spell check is unavailable in this browser.')).toBeInTheDocument()
  })
})
