/**
 * Touch rows: every tappable row is 30% taller on a touch screen, grown by ONE rule.
 *
 * The growth used to be restated per row shape as rem literals — nine copies across ui and
 * adh — and the copies went wrong independently: the combobox rows never got one; the
 * collapsed rail strip inherited the labelled row's numbers, so it grew 8% instead of 30% and
 * sat its icon off-centre; and every literal froze a padding the Spacing setting is meant to
 * scale. styles/components.css now writes the formula once, in its `@media (pointer: coarse)`
 * block, and a row shape only declares its PARAMETERS: its pointer padding and its one line of
 * content.
 *
 * jsdom evaluates no media query and computes no `calc()`, so a rendered row cannot show its
 * touch height here. These tests hold what makes that height right instead:
 *  - the sheet has one formula and one factor, restates neither, and sits in no layer;
 *  - nothing else in the package carries a copy;
 *  - every row shape is one the formula selects, and its parameters are, text for text, what
 *    Tailwind compiles that row's OWN padding and icon classes to. A row whose `py-1.5` changes
 *    while its parameter does not — the drift behind every bug above — fails here rather than
 *    on a phone.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import * as React from 'react'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { compile } from 'tailwindcss'
import { describe, it, expect, vi } from 'vitest'

import { Combobox } from '../components/combobox'
import { ListChooser } from '../components/list-chooser'
import { OptionMenu } from '../components/option-menu'
import { TopicRail } from '../blocks/topic-detail'

// This package typechecks without Node's types (see phoneSheet.test.tsx), so the Node APIs this
// file needs — to read the sheet, walk the package and feed Tailwind its stylesheets — are typed
// here, for this file alone.
type Dirent = { name: string; isDirectory(): boolean }
type NodeBuiltins = {
  getBuiltinModule(id: 'node:fs'): {
    readFileSync(path: string, encoding: 'utf8'): string
    readdirSync(path: string, options: { withFileTypes: true }): Dirent[]
  }
  getBuiltinModule(id: 'node:module'): {
    createRequire(from: string): { resolve(id: string): string }
  }
  getBuiltinModule(id: 'node:path'): {
    dirname(path: string): string
    join(...parts: string[]): string
    relative(from: string, to: string): string
  }
  getBuiltinModule(id: 'node:url'): { fileURLToPath(url: string): string }
}
const node = (globalThis as unknown as { process: NodeBuiltins }).process
const { readFileSync, readdirSync } = node.getBuiltinModule('node:fs')
const { dirname, join, relative } = node.getBuiltinModule('node:path')
const { fileURLToPath } = node.getBuiltinModule('node:url')
const requireHere = node.getBuiltinModule('node:module').createRequire(import.meta.url)

const SRC = join(dirname(fileURLToPath(import.meta.url)), '..')
const SHEET_PATH = join(SRC, 'styles', 'components.css')

// ── A CSS reader: enough for a hand-written sheet and for Tailwind's output ──────────────────

type Rule = { at: string[]; selector: string; decls: Map<string, string> }

function stripComments(css: string): string {
  return css.replace(/\/\*[\s\S]*?\*\//g, '')
}

/** Whitespace-insensitive text, so a value wrapped across lines compares equal to one that is not. */
function norm(text: string): string {
  return text.replace(/\s+/g, ' ').replace(/\(\s/g, '(').replace(/\s\)/g, ')').trim()
}

/** `text` split on `sep` wherever it is outside brackets, quotes and escapes. */
function split(text: string, sep: string): string[] {
  const parts: string[] = []
  let depth = 0
  let quote = ''
  let start = 0
  for (let i = 0; i < text.length; i++) {
    const ch = text[i]
    if (ch === '\\') i++
    else if (quote) quote = ch === quote ? '' : quote
    else if (ch === '"' || ch === "'") quote = ch
    else if (ch === '(' || ch === '[') depth++
    else if (ch === ')' || ch === ']') depth--
    else if (ch === sep && depth === 0) {
      parts.push(text.slice(start, i))
      start = i + 1
    }
  }
  parts.push(text.slice(start))
  return parts.map(norm).filter(Boolean)
}

/** Every style rule in `css`, in source order, with the at-rules it sits in. Fails on anything it
 *  cannot read rather than skipping it: a reader that drops a rule would pass a sheet it never saw.
 *  Flat CSS only — neither sheet it reads nests, and a nested block would hide its declarations
 *  from this reader, so one is refused rather than half-read. */
function rules(css: string): Rule[] {
  const out: Rule[] = []
  const open: string[] = []
  let buf = ''
  for (const ch of stripComments(css)) {
    if (ch === '{') {
      const prelude = norm(buf.slice(buf.lastIndexOf(';') + 1))
      const style = open.find((p) => !p.startsWith('@'))
      if (style !== undefined) throw new Error(`nested block "${prelude}" inside "${style}"`)
      open.push(prelude)
      buf = ''
    } else if (ch === '}') {
      const prelude = open.pop()
      if (prelude === undefined) throw new Error('unbalanced } in stylesheet')
      if (!prelude.startsWith('@')) {
        const decls = new Map<string, string>()
        for (const decl of split(buf, ';')) {
          const colon = decl.indexOf(':')
          if (colon < 0) throw new Error(`not a declaration: ${decl}`)
          decls.set(norm(decl.slice(0, colon)), norm(decl.slice(colon + 1)))
        }
        out.push({ at: open.filter((p) => p.startsWith('@')), selector: prelude, decls })
      }
      buf = ''
    } else {
      buf += ch
    }
  }
  if (open.length > 0) throw new Error('unbalanced { in stylesheet')
  return out
}

const SHEET_TEXT = stripComments(readFileSync(SHEET_PATH, 'utf8'))
const SHEET = rules(SHEET_TEXT)

const PARAMS = ['--adh-touch-row-pt', '--adh-touch-row-pb', '--adh-touch-row-content'] as const
const isCoarse = (r: Rule): boolean =>
  r.at.some((a) => /^@media\b.*\(\s*pointer\s*:\s*coarse\s*\)/.test(a))
const setsPadding = (r: Rule): boolean => [...r.decls.keys()].some((p) => p.startsWith('padding'))

/** The rule that grows the rows. Found, never assumed: zero or two of them is the failure. */
function formula(): Rule {
  const growers = SHEET.filter((r) => isCoarse(r) && setsPadding(r))
  expect(growers).toHaveLength(1)
  const [rule] = growers
  if (!rule) throw new Error('no coarse-pointer rule sets padding')
  return rule
}

// ── The sheet ────────────────────────────────────────────────────────────────────────────────

describe('touch rows — the one rule in styles/components.css', () => {
  it('writes the 30% once, on :root, and never restates it as a fallback', () => {
    const setters = SHEET.filter((r) => r.decls.has('--adh-touch-row-grow')).map((r) => ({
      at: r.at,
      selector: r.selector,
      value: r.decls.get('--adh-touch-row-grow'),
    }))
    expect(setters).toEqual([{ at: [], selector: ':root', value: '0.3' }])
    // Read exactly once — by the formula — and bare. A `var(…, 0.3)` is a second copy of the
    // factor, which is how nine copies of it came to exist.
    expect(SHEET_TEXT.match(/var\(\s*--adh-touch-row-grow[^)]*\)/g)).toEqual([
      'var(--adh-touch-row-grow)',
    ])
  })

  it('grows every row shape by one formula, built from the parameters alone', () => {
    const rule = formula()
    expect(split(rule.selector, ',')).toEqual([
      '.adh-touch-row',
      '.adh-dropdown-menu__item',
      '[data-htd-row]',
    ])
    expect(Object.fromEntries(rule.decls)).toEqual({
      '--adh-touch-row-extra':
        'calc((var(--adh-touch-row-pt) + var(--adh-touch-row-pb) + var(--adh-touch-row-content)) * var(--adh-touch-row-grow) / 2)',
      'padding-top': 'calc(var(--adh-touch-row-pt) + var(--adh-touch-row-extra))',
      'padding-bottom': 'calc(var(--adh-touch-row-pb) + var(--adh-touch-row-extra))',
    })
    // Derived there and nowhere else: a row that set its own `extra` would be a copy again.
    expect(SHEET.filter((r) => r.decls.has('--adh-touch-row-extra'))).toEqual([rule])
  })

  it('declares each shape\'s parameters at zero specificity, and from the density', () => {
    const declared = SHEET.filter((r) => !isCoarse(r) && PARAMS.some((p) => r.decls.has(p)))
    expect(declared.map((r) => r.selector)).toEqual([
      ':where(.adh-touch-row)',
      ':where(.adh-dropdown-menu__item)',
      ':where([data-htd-row])',
      ':where([data-htd-row][data-htd-strip])',
      ':where([data-htd-row][data-htd-strip="collapsed"])',
    ])
    for (const r of declared) {
      for (const p of PARAMS) {
        const value = r.decls.get(p)
        if (value === undefined) continue
        // The dropdown item's 0.6rem never followed the Spacing setting on a pointer either.
        if (r.selector === ':where(.adh-dropdown-menu__item)' && p !== '--adh-touch-row-content') {
          expect(value).toBe('0.6rem')
          continue
        }
        // No length literal: a frozen rem is what made Comfortable and Spacious rows grow less
        // than 30%. A line is the row's own `1lh`; everything else is `--spacing`.
        expect(value.replace(/\b1lh\b/g, ''), `${r.selector} ${p}`).not.toMatch(/\d(?:rem|px|em)\b/)
        expect(value === '1lh' || value.includes('var(--spacing)'), `${r.selector} ${p}`).toBe(true)
      }
    }
  })

  it('pads the dropdown item FROM its parameters, so a host that sets them keeps the growth', () => {
    const base = SHEET.filter((r) => r.at.length === 0 && r.selector === '.adh-dropdown-menu__item')
    expect(base.map((r) => r.decls.get('padding'))).toEqual([
      'var(--adh-touch-row-pt) 0.75rem var(--adh-touch-row-pb)',
    ])
  })

  it('sits in no layer and uses no !important', () => {
    // Unlayered is what lets the formula beat the rows' own `py-*` (Tailwind's utilities layer)
    // with no !important; a layered copy would lose to them and grow nothing.
    const touch = SHEET.filter((r) =>
      [...r.decls.keys()].some((p) => p.startsWith('--adh-touch-row-')),
    )
    expect(touch.length).toBeGreaterThan(0)
    for (const r of touch) expect(r.at.filter((a) => a.startsWith('@layer'))).toEqual([])
    expect(SHEET_TEXT).not.toContain('!important')
  })

  it('has no copy anywhere else in the package', () => {
    const sources = (dir: string): string[] =>
      readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
        const path = join(dir, entry.name)
        if (entry.isDirectory()) return entry.name === '__tests__' ? [] : sources(path)
        return /\.(tsx?|css)$/.test(entry.name) ? [path] : []
      })
    const files = sources(SRC)
    // Fail closed: a walk that found nothing would report no copies.
    expect(files.map((f) => relative(SRC, f))).toEqual(
      expect.arrayContaining([
        'styles/components.css',
        'components/list-chooser.tsx',
        'components/option-menu.tsx',
        'components/combobox.tsx',
        'blocks/topic-detail.tsx',
      ]),
    )
    const COPY = /--adh-touch-row-(?:grow|extra)\b|pointer-coarse:p[xytblr]?-/
    const copies = files
      .filter((f) => f !== SHEET_PATH && COPY.test(readFileSync(f, 'utf8')))
      .map((f) => relative(SRC, f))
    expect(copies).toEqual([])
  })
})

// ── The rows ─────────────────────────────────────────────────────────────────────────────────

/**
 * What Tailwind compiles `classes` to, from its DEFAULT theme. A fresh compiler per class list:
 * `build()` accumulates every candidate it has ever been given, so a shared one would credit one
 * row with another's rules (phoneSheet.test.tsx).
 */
const compiled = new Map<string, Promise<Rule[]>>()
function tailwind(classes: string): Promise<Rule[]> {
  let result = compiled.get(classes)
  if (!result) {
    result = compile(
      '@import "tailwindcss/theme.css" layer(theme); @import "tailwindcss/utilities.css" layer(utilities);',
      {
        loadStylesheet: async (id: string) => {
          const path = requireHere.resolve(id)
          return { path, base: dirname(path), content: readFileSync(path, 'utf8') }
        },
      },
    ).then((compiler) => rules(compiler.build(classes.split(/\s+/).filter(Boolean))))
    compiled.set(classes, result)
  }
  return result
}

type OwnSize = {
  /** Block padding the row's own classes give it on a fine pointer. */
  top?: string
  bottom?: string
  /** The height its `[&_svg]:h-*` gives its icon. */
  icon?: string
  /** Rules from its own classes that set padding under a media query — a growth copy. */
  mediaPadding: string[]
}

async function ownSize(row: Element): Promise<OwnSize> {
  const size: OwnSize = { mediaPadding: [] }
  for (const r of await tailwind(row.className)) {
    if (r.at[0] !== '@layer utilities') continue
    // A selector with a combinator styles a descendant (`[&_svg]:`), not the row.
    const onRow = !/\s/.test(r.selector)
    for (const [prop, value] of r.decls) {
      if (!onRow) {
        if (/ svg$/.test(r.selector) && prop === 'height') size.icon = value
      } else if (prop.startsWith('padding')) {
        if (r.at.length > 1) size.mediaPadding.push(`${r.at.slice(1).join(' ')} ${r.selector}`)
        else if (prop === 'padding-block' || prop === 'padding-top' || prop === 'padding-bottom') {
          if (prop !== 'padding-bottom') size.top = value
          if (prop !== 'padding-top') size.bottom = value
        } else if (prop === 'padding') {
          throw new Error(`${r.selector}: a padding shorthand this test does not read`)
        }
      }
    }
  }
  return size
}

/** The row's parameters as the sheet resolves them: every `:where()` rule it matches, in sheet
 *  order. They tie on specificity, so the later rule wins — as it does in the browser. */
function params(row: Element): Record<string, string> {
  const out: Record<string, string> = {}
  for (const r of SHEET) {
    const inner = /^:where\((.+)\)$/.exec(r.selector)?.[1]
    if (r.at.length > 0 || !inner || !row.matches(inner)) continue
    for (const [prop, value] of r.decls) if (prop.startsWith('--adh-touch-row-')) out[prop] = value
  }
  return out
}

/** `row` is grown by the formula, carries no growth of its own, and declares — part for part —
 *  the height it really has: its own block padding, and the one line `content` names. */
async function expectTouchRow(
  row: Element,
  content: (size: OwnSize) => string,
): Promise<void> {
  const label = `${row.tagName.toLowerCase()} "${row.textContent || row.getAttribute('aria-label')}"`
  expect(
    split(formula().selector, ',').some((s) => row.matches(s)),
    `${label} is not a row the formula selects`,
  ).toBe(true)
  const size = await ownSize(row)
  expect(size.mediaPadding, `${label} carries its own touch padding`).toEqual([])
  expect(size.top, `${label} has no block padding of its own`).toMatch(/var\(--spacing\)/)
  const p = params(row)
  expect(
    {
      pt: p['--adh-touch-row-pt'],
      pb: p['--adh-touch-row-pb'],
      content: p['--adh-touch-row-content'],
    },
    label,
  ).toEqual({ pt: size.top, pb: size.bottom, content: content(size) })
}

const oneLine = (): string => '1lh'

describe('touch rows — every row shape is grown from its own height', () => {
  const FRAMEWORKS = [
    { value: 'react', label: 'React' },
    { value: 'vue', label: 'Vue' },
  ]
  const LABELS = { ariaLabel: 'Framework', inputLabel: 'Filter or add framework' }
  function openChooser(): HTMLElement {
    fireEvent.click(screen.getByRole('button', { name: 'Framework' }))
    return screen.getByRole('combobox', { name: 'Filter or add framework' })
  }

  it('ListChooser: the items and the create row', async () => {
    render(<ListChooser items={FRAMEWORKS} value={null} onChange={vi.fn()} {...LABELS} />)
    const input = openChooser()
    const options = screen.getAllByRole('option')
    expect(options).toHaveLength(2)
    for (const row of options) await expectTouchRow(row, oneLine)

    fireEvent.change(input, { target: { value: 'Solid' } })
    await expectTouchRow(screen.getByRole('option', { name: /Add .*Solid/ }), oneLine)
  })

  it('ListChooser: the empty message when creation is off', async () => {
    render(
      <ListChooser
        items={FRAMEWORKS}
        value={null}
        onChange={vi.fn()}
        allowCreate={false}
        emptyLabel="No frameworks"
        {...LABELS}
      />,
    )
    fireEvent.change(openChooser(), { target: { value: 'zzz' } })
    await expectTouchRow(screen.getByText('No frameworks'), oneLine)
  })

  it('OptionMenu: the items and the Other row', async () => {
    render(
      <OptionMenu
        items={[
          { value: 'a', label: 'Search engine' },
          { value: 'b', label: 'Blog post' },
        ]}
        value={null}
        onChange={vi.fn()}
        ariaLabel="Source"
        allowOther
        otherLabel="Other"
      />,
    )
    fireEvent.click(screen.getByRole('button', { name: 'Source' }))
    const options = screen.getAllByRole('option')
    expect(options).toHaveLength(3)
    for (const row of options) await expectTouchRow(row, oneLine)
  })

  it('Combobox: the items and the no-match message', async () => {
    function Harness(): React.ReactElement {
      const [value, setValue] = React.useState('')
      return (
        <Combobox
          items={['React', 'Vue', 'Svelte']}
          value={value}
          onValueChange={setValue}
          ariaLabel="Framework"
        />
      )
    }
    render(<Harness />)
    const input = screen.getByRole('combobox', { name: 'Framework' })
    fireEvent.change(input, { target: { value: 'e' } })
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    await waitFor(() => expect(input).toHaveAttribute('aria-expanded', 'true'))
    const options = await screen.findAllByRole('option')
    expect(options).toHaveLength(3)
    for (const row of options) await expectTouchRow(row, oneLine)

    fireEvent.change(input, { target: { value: 'zzz' } })
    await expectTouchRow(await screen.findByText('No matches'), oneLine)
  })

  describe('TopicRail', () => {
    function renderRail(mode: 'labelled' | 'covered' | 'collapsed'): Element[] {
      render(
        <TopicRail
          items={[
            { id: 'a', label: 'Appearance' },
            { id: 'b', label: 'Keyboard' },
          ]}
          selectedId="a"
          onSelect={() => {}}
          emptyLabel="Nothing"
          collapsed={mode === 'collapsed'}
          covered={mode === 'covered'}
          onToggle={() => {}}
        />,
      )
      const rows = [...document.querySelectorAll('[data-htd-row]')]
      expect(rows).toHaveLength(2)
      return rows
    }

    it('a labelled row: its `pt-1 pb-0.5` around the taller of its label line and its icon', async () => {
      for (const row of renderRail('labelled')) {
        expect(row).not.toHaveAttribute('data-htd-strip')
        await expectTouchRow(row, (size) => `max(1lh, ${size.icon})`)
      }
    })

    it('a covered strip: the same padding around the icon alone', async () => {
      for (const row of renderRail('covered')) {
        expect(row).toHaveAttribute('data-htd-strip', 'covered')
        await expectTouchRow(row, (size) => `${size.icon}`)
      }
    })

    it('a filter suggestion: its `py-1.5` around one line, like the Tailwind rows', async () => {
      // A titled rail: the filter lives in the toolbar under its header.
      render(
        <TopicRail
          title="Settings"
          items={[
            { id: 'a', label: 'Appearance' },
            { id: 'b', label: 'Keyboard' },
          ]}
          selectedId={null}
          onSelect={() => {}}
          emptyLabel="Nothing"
          collapsed={false}
          onToggle={() => {}}
        />,
      )
      fireEvent.click(screen.getByRole('button', { name: 'Filter' }))
      fireEvent.change(screen.getByRole('combobox'), { target: { value: 'e' } })
      const options = screen.getAllByRole('option')
      expect(options).toHaveLength(2)
      for (const row of options) await expectTouchRow(row, oneLine)
    })

    it('a collapsed strip: its `py-1.5` around the icon alone, the same above and below', async () => {
      for (const row of renderRail('collapsed')) {
        expect(row).toHaveAttribute('data-htd-strip', 'collapsed')
        await expectTouchRow(row, (size) => `${size.icon}`)
        // Equal parameters above and below: the growth is split evenly, so the icon stays centred.
        const p = params(row)
        expect(p['--adh-touch-row-pt']).toBe(p['--adh-touch-row-pb'])
      }
    })
  })
})
