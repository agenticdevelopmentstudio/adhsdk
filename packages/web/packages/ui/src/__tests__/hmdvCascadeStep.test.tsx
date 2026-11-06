/**
 * HierarchicalMenuDetail's cascade: how far each list steps down from its parent.
 *
 * A child list opens just under its parent's HEADER and list TOOLBAR, and its opaque box covers
 * everything of the parent below that line. The step used to be measured to the header alone, which
 * was right while the `+` and `titleActions` rode the header. Once they moved down onto the toolbar,
 * every child covered its parent's toolbar: the hub root's Manage workspace features button, and a
 * covered list's search and list tools.
 *
 * jsdom has no layout, so the two rows' edges are stated here: the header ends 34px into its column,
 * and the toolbar below it ends at 66px. Everything else measures zero, as jsdom's own rects do,
 * which also keeps the stack wide (its container measures no width, so nothing forces it narrow).
 */
import { render } from '@testing-library/react'
import type { ReactElement } from 'react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { HierarchicalMenuDetail } from '../blocks/hierarchical-menu-detail'
import type { TopicLevel } from '../blocks/hierarchical-topic-detail'

const HEADER_BOTTOM = 34
const TOOLBAR_BOTTOM = 66

const rect = (top: number, bottom: number) =>
  ({ top, bottom, y: top, height: bottom - top, left: 0, right: 0, x: 0, width: 0, toJSON: () => ({}) }) as DOMRect

beforeEach(() => {
  vi.spyOn(Element.prototype, 'getBoundingClientRect').mockImplementation(function (this: Element) {
    if (this.matches('[data-htd-toolbar]')) return rect(HEADER_BOTTOM, TOOLBAR_BOTTOM)
    if (this.matches('[data-htd-header]')) return rect(0, HEADER_BOTTOM)
    return rect(0, 0)
  })
})
afterEach(() => {
  vi.restoreAllMocks()
})

// The block keys module-scoped surface state by the ROOT level's id, and that state deliberately
// outlives a mount, so each test gets its own ids rather than inheriting a neighbour's.
let surfaceSeq = 0
const nextSurface = () => `hmd-step-${++surfaceSeq}`

/** A chosen root list with its child open beside it. `root` adds to the root level. */
const levels = (surface: string, root: Partial<TopicLevel> = {}): TopicLevel[] => [
  {
    id: `${surface}-workspaces`,
    title: 'Workspaces',
    items: [{ id: 'acme', label: 'Acme' }],
    selectedId: 'acme',
    onSelect: () => {},
    onClear: () => {},
    ...root,
  },
  {
    id: `${surface}-features`,
    title: 'Workspace',
    items: [{ id: 'integrations', label: 'Integrations' }],
    selectedId: null,
    onSelect: () => {},
    onClear: () => {},
  },
]

const cascade = (stack: TopicLevel[]): ReactElement => (
  <HierarchicalMenuDetail levels={stack} disclosureStyle="cascading" autoHideTopics={false}>
    <div>detail</div>
  </HierarchicalMenuDetail>
)

const manageFeatures = { titleActions: <button type="button">Manage workspace features</button> }

/** The child list's `top`: where its box starts covering the root. */
const childTop = (): string => {
  const col = document.querySelector('[data-htd-col="1"]')
  if (!(col instanceof HTMLElement)) throw new Error('no child column')
  return col.style.top
}

describe('HierarchicalMenuDetail — the cascade step', () => {
  it("opens a child under its parent's toolbar, not over it", () => {
    render(cascade(levels(nextSurface(), manageFeatures)))
    expect(childTop()).toBe(`${TOOLBAR_BOTTOM}px`)
  })

  it('opens a child under the toolbar of a list with no tools of its own — its filter is there', () => {
    // Every titled list has a toolbar now (its filter), so there is no header-only step left.
    render(cascade(levels(nextSurface())))
    expect(document.querySelector('[data-htd-toolbar]')).not.toBeNull()
    expect(childTop()).toBe(`${TOOLBAR_BOTTOM}px`)
  })
})
