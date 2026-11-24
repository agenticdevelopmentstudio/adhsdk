import { describe, expect, it, vi } from 'vitest'
import { render } from '@testing-library/react'
import { Checklist, Chips, Roadmap, Rule, Stats, Versus } from '../index'

describe('Versus', () => {
  it('lays the two sides out and marks which is which', () => {
    const { container } = render(
      <Versus
        them={{ title: 'A usage meter', lede: 'Reports.', points: ['a', 'b'] }}
        us={{ title: 'Stenographer', lede: 'Acts.', points: ['c'] }}
      />
    )
    expect(container.querySelector('.lp-versus__them h3')!.textContent).toBe('A usage meter')
    expect(container.querySelector('.lp-versus__us h3')!.textContent).toBe('Stenographer')
    expect(container.querySelectorAll('.lp-versus__them li')).toHaveLength(2)
    expect(container.querySelectorAll('.lp-versus__us li')).toHaveLength(1)
  })

  // A side written as bullets with no opening claim. The generator omits the
  // prop rather than passing `<></>`, and what has to be asserted is the
  // ABSENCE of the <p>, not that the render survived: an empty <p></p> still
  // carries `.lp-versus p`'s margins, and it is invisible to TypeScript, to a
  // snapshot diff and to a screenshot alike.
  it('renders no paragraph on a side with no lede', () => {
    const { container } = render(
      <Versus
        them={{ title: 'A usage meter', points: ['a', 'b'] }}
        us={{ title: 'Stenographer', points: ['c'] }}
      />
    )
    expect(container.querySelectorAll('.lp-versus p')).toHaveLength(0)
    expect(container.querySelectorAll('.lp-versus__them li')).toHaveLength(2)
  })

  // The mirror image: a side that is a claim with no bullets under it.
  it('renders no list on a side with no points', () => {
    const { container } = render(
      <Versus them={{ title: 'A usage meter', lede: 'Reports.' }} us={{ title: 'Stenographer', lede: 'Acts.' }} />
    )
    expect(container.querySelectorAll('.lp-versus ul')).toHaveLength(0)
    expect(container.querySelector('.lp-versus__us p')!.textContent).toBe('Acts.')
  })

  // An empty array is the other way to say "no points", and it has to be
  // treated as absence too — `points={[]}` renders `<ul></ul>` under a naive
  // `.map`, which is the same empty styled element by a different route.
  it('renders no list for an empty points array', () => {
    const { container } = render(
      <Versus them={{ title: 'T', lede: 'a', points: [] }} us={{ title: 'U', lede: 'b', points: [] }} />
    )
    expect(container.querySelectorAll('.lp-versus ul')).toHaveLength(0)
  })

  // Both guards on one side at once: the panel is its heading and nothing else.
  it('renders a bare heading when a side has neither lede nor points', () => {
    const { container } = render(
      <Versus them={{ title: 'T' }} us={{ title: 'U', lede: 'b', points: ['c'] }} />
    )
    const them = container.querySelector('.lp-versus__them')!
    expect(Array.from(them.children).map((c) => c.tagName)).toEqual(['H3'])
  })

  it('versus-001: renders two panels, each with its title in an h3', () => {
    const { container } = render(<Versus them={{ title: 'Option A' }} us={{ title: 'Option B' }} />)
    const panels = container.querySelectorAll('.lp-versus > div')
    expect(panels).toHaveLength(2)
    expect(panels[0]!.querySelector('h3')!.textContent).toBe('Option A')
    expect(panels[1]!.querySelector('h3')!.textContent).toBe('Option B')
  })

  it('versus-002: the h3 contains the title text', () => {
    const { container } = render(<Versus them={{ title: 'Text' }} us={{ title: 'Other' }} />)
    expect(container.querySelector('.lp-versus__them h3')!.textContent).toBe('Text')
  })

  it('versus-003: a defined lede renders in a paragraph', () => {
    const { container } = render(<Versus them={{ title: 'A', lede: 'Introduction' }} us={{ title: 'B' }} />)
    expect(container.querySelector('.lp-versus__them p')!.textContent).toBe('Introduction')
  })

  it('versus-004: no paragraph when lede is omitted on both sides', () => {
    const { container } = render(<Versus them={{ title: 'A' }} us={{ title: 'B' }} />)
    expect(container.querySelectorAll('p')).toHaveLength(0)
  })

  it('versus-005: points render as a ul with one li each', () => {
    const { container } = render(
      <Versus them={{ title: 'A', points: ['Point 1', 'Point 2'] }} us={{ title: 'B' }} />
    )
    const items = container.querySelectorAll('.lp-versus__them ul > li')
    expect(items).toHaveLength(2)
    expect(Array.from(items).map((li) => li.textContent)).toEqual(['Point 1', 'Point 2'])
  })

  it('versus-006: no list for empty or omitted points', () => {
    const empty = render(<Versus them={{ title: 'A', points: [] }} us={{ title: 'B' }} />)
    expect(empty.container.querySelectorAll('ul')).toHaveLength(0)
    empty.unmount()
    const omitted = render(<Versus them={{ title: 'A' }} us={{ title: 'B' }} />)
    expect(omitted.container.querySelectorAll('ul')).toHaveLength(0)
  })

  // jsdom resolves no stylesheet here, so the "different border and background" half of the
  // vector is CSS; what the component owns, and what is asserted, is the distinct marker class.
  it('versus-007: the us panel carries lp-versus__us, the them panel lp-versus__them', () => {
    const { container } = render(<Versus them={{ title: 'A' }} us={{ title: 'B' }} />)
    const them = container.querySelector('.lp-versus__them')!
    const us = container.querySelector('.lp-versus__us')!
    expect(them).not.toBe(us)
    expect(them.className).toBe('lp-versus__them')
    expect(us.className).toBe('lp-versus__us')
    expect(them.classList.contains('lp-versus__us')).toBe(false)
    expect(us.classList.contains('lp-versus__them')).toBe(false)
  })

  it('versus-008: a defined-but-empty lede still renders an empty paragraph', () => {
    const { container } = render(<Versus them={{ title: 'A', lede: <></> }} us={{ title: 'B' }} />)
    const p = container.querySelectorAll('.lp-versus__them p')
    expect(p).toHaveLength(1)
    expect(p[0]!.textContent).toBe('')
    expect(container.querySelectorAll('.lp-versus__us p')).toHaveLength(0)
  })

  it('versus-009: identical props give both panels identical element structure', () => {
    const side = { title: 'T', lede: 'L', points: ['a', 'b'] }
    const { container } = render(<Versus them={side} us={side} />)
    const shape = (el: Element): string =>
      `${el.tagName}(${Array.from(el.children).map(shape).join(',')})`
    expect(shape(container.querySelector('.lp-versus__them')!)).toBe(
      shape(container.querySelector('.lp-versus__us')!)
    )
  })

  it('versus-010: them precedes us in DOM order', () => {
    const { container } = render(<Versus them={{ title: 'A' }} us={{ title: 'B' }} />)
    const root = container.querySelector('.lp-versus')!
    expect(root.children[0]!.className).toBe('lp-versus__them')
    expect(root.children[1]!.className).toBe('lp-versus__us')
  })

  it.skip('versus-011: stacks into one column below two 18rem columns plus the gap (needs real layout and container-width CSS; jsdom has neither)', () => {})
})

describe('Rule', () => {
  it('is a definition list, one dt/dd pair per step, in order', () => {
    const { container } = render(
      <Rule steps={[{ term: 'When', detail: 'idle' }, { term: 'Then', detail: 'compact' }]} />
    )
    const dl = container.querySelector('dl.lp-rule')!
    expect(Array.from(dl.children).map((c) => c.tagName)).toEqual(['DT', 'DD', 'DT', 'DD'])
    expect(dl.querySelectorAll('dt')[1].textContent).toBe('Then')
  })

  describe('conformance vectors', () => {
    it('rule-001 renders two dt/dd pairs in order', () => {
      const { container } = render(
        <Rule steps={[{ term: 'A', detail: 'First' }, { term: 'B', detail: 'Second' }]} />
      )
      expect(Array.from(container.querySelectorAll('dt')).map((e) => e.textContent)).toEqual(['A', 'B'])
      expect(Array.from(container.querySelectorAll('dd')).map((e) => e.textContent)).toEqual(['First', 'Second'])
    })

    it('rule-002 renders ReactNode term and detail inside dt and dd', () => {
      const { container } = render(<Rule steps={[{ term: <strong>Bold</strong>, detail: <em>Italic</em> }]} />)
      expect(container.querySelector('dt')!.innerHTML).toBe('<strong>Bold</strong>')
      expect(container.querySelector('dd')!.innerHTML).toBe('<em>Italic</em>')
    })

    it('rule-003 is a dl whose direct children are only dt and dd', () => {
      const { container } = render(<Rule steps={[{ term: 'A', detail: '1' }, { term: 'B', detail: '2' }]} />)
      const root = container.firstElementChild!
      expect(root.tagName).toBe('DL')
      expect(Array.from(root.children).map((c) => c.tagName)).toEqual(['DT', 'DD', 'DT', 'DD'])
    })

    it('rule-004 gives the root dl the lp-rule class', () => {
      const { container } = render(<Rule steps={[{ term: 'A', detail: '1' }]} />)
      expect(container.firstElementChild!.classList.contains('lp-rule')).toBe(true)
    })

    it('rule-005 renders an empty dl for no steps', () => {
      const { container } = render(<Rule steps={[]} />)
      expect(container.innerHTML).toBe('<dl class="lp-rule"></dl>')
    })

    it('rule-006 renders exactly one dt and one dd for one step', () => {
      const { container } = render(<Rule steps={[{ term: 'A', detail: '1' }]} />)
      expect(container.querySelectorAll('dt')).toHaveLength(1)
      expect(container.querySelectorAll('dd')).toHaveLength(1)
      expect(container.querySelector('dt')!.textContent).toBe('A')
      expect(container.querySelector('dd')!.textContent).toBe('1')
    })

    it('rule-007 renders empty dt and dd for null term and undefined detail', () => {
      const { container } = render(<Rule steps={[{ term: null, detail: undefined }]} />)
      expect(container.querySelector('dt')!.textContent).toBe('')
      expect(container.querySelector('dd')!.textContent).toBe('')
    })

    it('rule-008 renders a numeric term as text and a boolean detail as nothing', () => {
      const { container } = render(<Rule steps={[{ term: 42, detail: true }]} />)
      expect(container.querySelector('dt')!.textContent).toBe('42')
      expect(container.querySelector('dd')!.textContent).toBe('')
    })

    it('rule-009 lets React reject a plain object term (web-only, informational)', () => {
      const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
      try {
        expect(() => render(<Rule steps={[{ term: {} as never, detail: 'x' }]} />)).toThrow(/Objects are not valid/)
      } finally {
        spy.mockRestore()
      }
    })

    it.skip('rule-010 treats a missing steps value as empty (not applicable to the typed web source)', () => {})
  })
})

describe('Stats', () => {
  it('wraps each pair in the div the grid lays out', () => {
    const { container } = render(
      <Stats entries={[{ term: '5h', detail: 'window' }, { term: '1 line', detail: 'HUD' }]} />
    )
    const wrappers = container.querySelectorAll('dl.lp-stats > div')
    expect(wrappers).toHaveLength(2)
    expect(wrappers[0].querySelector('dt')!.textContent).toBe('5h')
    expect(wrappers[0].querySelector('dd')!.textContent).toBe('window')
  })
})

describe('Chips', () => {
  it('marks the open one and nothing else', () => {
    const { container } = render(
      <Chips entries={[{ label: 'Ollama', open: true }, { label: 'Anthropic' }]} />
    )
    const items = container.querySelectorAll('li')
    expect(items[0].className).toContain('lp-chip--open')
    expect(items[1].className).not.toContain('lp-chip--open')
  })

  it('carries the soon modifier on the list', () => {
    const { container } = render(<Chips soon entries={[{ label: 'Codex' }]} />)
    expect(container.firstElementChild!.className).toContain('lp-chips--soon')
  })
})

describe('Roadmap', () => {
  it('is an eyebrowed aside', () => {
    const { container } = render(<Roadmap eyebrow="Planned agents"><p>x</p></Roadmap>)
    expect(container.querySelector('.lp-roadmap .lp-eyebrow')!.textContent).toBe('Planned agents')
  })

  // An aside nested inside a section that already carries a heading has
  // nothing left to label. An empty span would still take `.lp-roadmap
  // .lp-eyebrow`'s margin and open the box with a blank line — invisible in
  // the JSX, and nothing to fail on.
  it('renders no eyebrow element when not given one', () => {
    const { container } = render(<Roadmap><p>x</p></Roadmap>)
    expect(container.querySelector('.lp-eyebrow')).toBeNull()
    expect(container.querySelector('.lp-roadmap p')!.textContent).toBe('x')
  })
})

describe('Checklist', () => {
  it('groups items under headings and wraps each item in a span', () => {
    const { container } = render(
      <Checklist groups={[{ heading: 'Capture', items: [{ text: 'One' }, { text: 'Two' }] }]} />
    )
    expect(container.querySelector('.lp-checklist h3')!.textContent).toBe('Capture')
    expect(container.querySelectorAll('.lp-checklist li span')).toHaveLength(2)
  })

  // The mark is a `::before` the host picks, so jsdom can see the class and
  // nothing else — which is exactly what has to be asserted: the CSS keys off
  // this modifier, and an item that loses it silently claims to be shipped.
  it('marks the not-yet item and nothing else', () => {
    const { container } = render(
      <Checklist
        groups={[{ heading: 'Testing', items: [{ text: 'Shipped' }, { text: 'On a branch', soon: true }] }]}
      />
    )
    const items = container.querySelectorAll('.lp-checklist li')
    expect(items[0].className).toBe('')
    expect(items[1].className).toContain('lp-checklist__item--soon')
  })

  // A group with no items renders its heading and no list — not an empty
  // <ul></ul>, which is invisible on screen while still taking the list's
  // spacing. The generator refuses this shape outright (a group with nothing
  // under it is incomplete content); the guard is what a different caller gets.
  it('renders no list for a group with no items', () => {
    const { container } = render(
      <Checklist groups={[{ heading: 'Capture', items: [] }, { heading: 'Review', items: [{ text: 'One' }] }]} />
    )
    expect(container.querySelectorAll('.lp-checklist ul')).toHaveLength(1)
    const empty = container.querySelectorAll('.lp-checklist > div')[0]
    expect(Array.from(empty.children).map((c) => c.tagName)).toEqual(['H3'])
  })
})
