import { render } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { TopicSelectHint } from '../blocks/topic-select-hint'

const root = (c: HTMLElement) => c.querySelector('[data-htd-select-hint]') as HTMLElement
const card = (c: HTMLElement) => c.querySelector('[data-slot="card"]') as HTMLElement
// Card children: icon chip, then optional headline div, then optional description div.
const headlineEl = (c: HTMLElement) => card(c).querySelector(':scope > div.font-semibold') as HTMLElement | null
const descEl = (c: HTMLElement) => card(c).querySelector(':scope > div.text-sm') as HTMLElement | null

const GENERIC = 'Select an item from the list to view or edit it here.'

describe('TopicSelectHint conformance vectors', () => {
  it('topic-select-hint-001 defaults render card, icon, test hook and fallback headline', () => {
    const { container } = render(<TopicSelectHint />)
    expect(root(container)).not.toBeNull()
    expect(card(container)).not.toBeNull()
    expect(card(container).querySelector('svg.lucide-mouse-pointer-click')).not.toBeNull()
    expect(headlineEl(container)?.textContent).toBe(GENERIC)
  })

  it('topic-select-hint-002 custom title renders verbatim', () => {
    const { container } = render(<TopicSelectHint title="Custom headline" />)
    expect(headlineEl(container)?.textContent).toBe('Custom headline')
  })

  it('topic-select-hint-003 noun "workspace" gives "a workspace"', () => {
    const { container } = render(<TopicSelectHint noun="workspace" />)
    expect(headlineEl(container)?.textContent).toBe('Select a workspace to view or edit it here.')
  })

  it('topic-select-hint-004 noun "item" gives "an item"', () => {
    const { container } = render(<TopicSelectHint noun="item" />)
    expect(headlineEl(container)?.textContent).toBe('Select an item to view or edit it here.')
  })

  it('topic-select-hint-005 listTitle builds the headline with the edit suffix', () => {
    const { container } = render(<TopicSelectHint listTitle="Workspaces" />)
    expect(headlineEl(container)?.textContent).toBe('Select an item from Workspaces to view or edit it here.')
  })

  it('topic-select-hint-006 noun takes precedence over listTitle', () => {
    const { container } = render(<TopicSelectHint noun="workspace" listTitle="Workspaces" />)
    expect(headlineEl(container)?.textContent).toBe('Select a workspace to view or edit it here.')
  })

  it('topic-select-hint-007 title takes precedence over noun', () => {
    const { container } = render(<TopicSelectHint title="Select a group" noun="workspace" />)
    expect(headlineEl(container)?.textContent).toBe('Select a group')
  })

  it('topic-select-hint-008 children render as the description below the headline', () => {
    const { container } = render(<TopicSelectHint>Choose one to begin editing.</TopicSelectHint>)
    const d = descEl(container)
    expect(d?.textContent).toBe('Choose one to begin editing.')
    expect(headlineEl(container)!.compareDocumentPosition(d!) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('topic-select-hint-009 headline ends with the edit suffix when there are no children', () => {
    const { container } = render(<TopicSelectHint noun="site" />)
    expect(headlineEl(container)?.textContent?.endsWith(' to view or edit it here.')).toBe(true)
  })

  it('topic-select-hint-010 headline drops the edit suffix when children are given', () => {
    const { container } = render(<TopicSelectHint noun="site">Some description</TopicSelectHint>)
    expect(headlineEl(container)?.textContent).toBe('Select a site')
    expect(headlineEl(container)?.textContent?.endsWith(' to view or edit it here.')).toBe(false)
  })

  it('topic-select-hint-011 selectable=false hides the headline but shows children', () => {
    const { container } = render(<TopicSelectHint selectable={false}>Nothing yet.</TopicSelectHint>)
    expect(headlineEl(container)).toBeNull()
    expect(descEl(container)?.textContent).toBe('Nothing yet.')
  })

  it('topic-select-hint-012 selectable=false without children renders the card with no headline or description', () => {
    const { container } = render(<TopicSelectHint selectable={false} />)
    expect(card(container)).not.toBeNull()
    expect(headlineEl(container)).toBeNull()
    expect(descEl(container)).toBeNull()
  })

  it('topic-select-hint-013 no description section when children are undefined', () => {
    const { container } = render(<TopicSelectHint noun="site">{undefined}</TopicSelectHint>)
    expect(descEl(container)).toBeNull()
  })

  it.skip('topic-select-hint-014 root computes a centering flex column: jsdom loads no Tailwind CSS, so computed layout is unavailable', () => {})

  it('topic-select-hint-015 explicit title still renders when selectable=false', () => {
    const { container } = render(<TopicSelectHint title="Confirm delete" selectable={false} />)
    expect(headlineEl(container)?.textContent).toBe('Confirm delete')
  })

  it('topic-select-hint-016 empty noun falls back to the generic headline', () => {
    const { container } = render(<TopicSelectHint noun="" />)
    expect(headlineEl(container)?.textContent).toBe(GENERIC)
  })

  it('topic-select-hint-017 empty listTitle falls back to the generic headline', () => {
    const { container } = render(<TopicSelectHint listTitle="" />)
    expect(headlineEl(container)?.textContent).toBe(GENERIC)
  })

  it('topic-select-hint-018 empty-string children count as provided', () => {
    const { container } = render(<TopicSelectHint noun="site">{''}</TopicSelectHint>)
    expect(descEl(container)).not.toBeNull()
    expect(descEl(container)?.textContent).toBe('')
    expect(headlineEl(container)?.textContent?.endsWith(' to view or edit it here.')).toBe(false)
  })

  it('topic-select-hint-019 empty-string title renders an empty headline', () => {
    const { container } = render(<TopicSelectHint title="" noun="site" />)
    expect(headlineEl(container)).not.toBeNull()
    expect(headlineEl(container)?.textContent).toBe('')
    expect(container.textContent).not.toContain('Select a site')
  })
})
