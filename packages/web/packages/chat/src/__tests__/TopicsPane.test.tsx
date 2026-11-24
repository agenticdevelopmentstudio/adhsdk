import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { TopicsPane } from '../modes/three-pane/TopicsPane'
import { ConnectorRegistryProvider } from '../modes/three-pane/connectors/ConnectorRegistry'

type Topic = { title: string; messageIndex: number }

function pane(
  topics: Topic[],
  opts: { activeIndex?: number; visible?: boolean; onSelectTopic?: (i: number) => void } = {},
) {
  return render(
    <ConnectorRegistryProvider>
      <TopicsPane
        topics={topics as never}
        activeIndex={opts.activeIndex ?? -1}
        onSelectTopic={opts.onSelectTopic ?? (() => {})}
        visible={opts.visible ?? true}
      />
    </ConnectorRegistryProvider>,
  )
}

const root = (c: HTMLElement) => c.querySelector('.pc-topics-pane') as HTMLElement

describe('TopicsPane conformance vectors', () => {
  it('topics-001 renders the Topics header', () => {
    const { container } = pane([])
    expect(container.querySelector('.pc-panel-header')!.textContent).toBe('Topics')
  })

  it('topics-002 renders a single topic as a list item with a button', () => {
    const { container } = pane([{ title: 'Topic 1', messageIndex: 1 }])
    expect(container.querySelectorAll('li')).toHaveLength(1)
    expect(container.querySelector('li button')!.textContent).toBe('Topic 1')
  })

  it('topics-003 shows each topic title in its own button', () => {
    pane([
      { title: 'First', messageIndex: 1 },
      { title: 'Second', messageIndex: 2 },
    ])
    expect(screen.getByRole('button', { name: 'First' })).toBeTruthy()
    expect(screen.getByRole('button', { name: 'Second' })).toBeTruthy()
  })

  it('topics-004 clicking a topic calls onSelectTopic with its index', () => {
    const onSelect = vi.fn()
    pane([{ title: 'Topic', messageIndex: 1 }], { onSelectTopic: onSelect })
    fireEvent.click(screen.getByRole('button', { name: 'Topic' }))
    expect(onSelect).toHaveBeenCalledWith(0)
  })

  it('topics-005 only the active topic carries the active class', () => {
    pane(
      [
        { title: 'A', messageIndex: 1 },
        { title: 'B', messageIndex: 2 },
      ],
      { activeIndex: 1 },
    )
    expect(screen.getByRole('button', { name: 'B' }).classList.contains('active')).toBe(true)
    expect(screen.getByRole('button', { name: 'A' }).classList.contains('active')).toBe(false)
  })

  it('topics-006 visible adds pc-pane-visible', () => {
    const { container } = pane([], { visible: true })
    expect(root(container).classList.contains('pc-pane-visible')).toBe(true)
  })

  it('topics-007 hidden adds pc-pane-hidden', () => {
    const { container } = pane([], { visible: false })
    expect(root(container).classList.contains('pc-pane-hidden')).toBe(true)
  })

  it('topics-008 each topic renders a connector anchor keyed by messageIndex', () => {
    const { container } = pane([{ title: 'Topic', messageIndex: 5 }])
    const anchor = container.querySelector('[data-connector-anchor="topic-5"]')!
    expect(anchor).toBeTruthy()
    expect(anchor.classList.contains('pc-connector-anchor-out')).toBe(true)
  })

  it('topics-009 a single active topic button has the active class', () => {
    pane([{ title: 'First', messageIndex: 1 }], { activeIndex: 0 })
    expect(screen.getByRole('button').classList.contains('active')).toBe(true)
  })

  it('topics-010 clicking the second of three topics passes index 1', () => {
    const onSelect = vi.fn()
    pane(
      [
        { title: 'A', messageIndex: 1 },
        { title: 'B', messageIndex: 2 },
        { title: 'C', messageIndex: 3 },
      ],
      { onSelectTopic: onSelect },
    )
    fireEvent.click(screen.getByRole('button', { name: 'B' }))
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect).toHaveBeenCalledWith(1)
  })

  it('topics-011 activeIndex -1 activates nothing', () => {
    const { container } = pane([{ title: 'A', messageIndex: 1 }], { activeIndex: -1 })
    expect(container.querySelector('button.active')).toBeNull()
  })

  it('topics-012 an out-of-range activeIndex activates nothing', () => {
    const { container } = pane([{ title: 'A', messageIndex: 1 }], { activeIndex: 5 })
    expect(container.querySelector('button.active')).toBeNull()
  })

  it('topics-013 no topics renders no list items but keeps the header', () => {
    const { container } = pane([])
    expect(container.querySelectorAll('li')).toHaveLength(0)
    expect(container.querySelector('.pc-panel-header')).toBeTruthy()
  })

  it('topics-014 a hidden pane keeps its buttons in the DOM, not inert or aria-hidden', () => {
    const { container } = pane([{ title: 'A', messageIndex: 1 }], { visible: false })
    expect(root(container).classList.contains('pc-pane-hidden')).toBe(true)
    const button = container.querySelector('button')!
    expect(button).toBeTruthy()
    for (let n: HTMLElement | null = button; n; n = n.parentElement) {
      expect(n.hasAttribute('inert')).toBe(false)
      expect(n.getAttribute('aria-hidden')).not.toBe('true')
    }
  })
})
