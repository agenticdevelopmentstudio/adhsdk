/// <reference types="@testing-library/jest-dom/vitest" />
import { useState } from 'react'
import { render, screen, cleanup, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, afterEach, vi } from 'vitest'
import { FocusedTopicDetail } from '../blocks/focused-topic-detail'

const ITEMS = [
  { id: 'temporal', label: 'Temporal', sublabel: 'com.temporal', description: 'First blurb' },
  { id: 'acme', label: 'Acme', sublabel: 'com.acme', description: 'Second blurb' },
  { id: 'globex', label: 'Globex', sublabel: 'com.globex', description: 'Third blurb' },
]
const TOPICS = [
  { id: 'apps', label: 'Applications' },
  { id: 'people', label: 'People', disabled: true },
  { id: 'notes', label: 'Notes' },
]

type Props = Partial<React.ComponentProps<typeof FocusedTopicDetail>>

function renderFtd(props: Props = {}) {
  const onFocus = vi.fn()
  const utils = render(
    <FocusedTopicDetail
      items={ITEMS}
      focusedId="temporal"
      onFocus={onFocus}
      topics={TOPICS}
      activeTopicId="apps"
      onTopicSelect={() => {}}
      popupAriaLabel="Ecosystem"
      {...props}
    >
      <div data-testid="pane">pane content</div>
    </FocusedTopicDetail>,
  )
  return { onFocus, ...utils }
}

const rail = (name: RegExp) => screen.getByRole('button', { name })
const selectorRow = () => screen.getByLabelText('Ecosystem').closest('li') as HTMLElement

afterEach(cleanup)

describe('FocusedTopicDetail conformance', () => {
  it('ftd-001 a known focusedId selects the active topic and shows the pane', () => {
    renderFtd({ nameSuffix: 'Ecosystem' })
    expect(rail(/^Applications/)).toHaveAttribute('aria-current', 'true')
    expect(screen.getByTestId('pane')).toBeInTheDocument()
    expect(screen.getByText('Applications (Temporal Ecosystem)')).toBeInTheDocument()
  })

  it('ftd-002 an unknown focusedId falls back to the All view', () => {
    renderFtd({ focusedId: 'gone' })
    expect(screen.getByText('All items')).toBeInTheDocument()
    expect(screen.queryByTestId('pane')).toBeNull()
    expect(screen.getByText('First blurb')).toBeInTheDocument()
  })

  it('ftd-003 unfocused: topics dim, none selected, the bar sits on the selector row', () => {
    renderFtd({ focusedId: null })
    for (const name of [/^Applications/, /^People/, /^Notes/]) {
      expect(rail(name)).toBeDisabled()
      expect(rail(name)).not.toHaveAttribute('aria-current', 'true')
    }
    expect(selectorRow()).toHaveClass('border-l-apt-gold')
  })

  it('ftd-003 (focused) keeps each topic own disabled value and no bar on the selector', () => {
    renderFtd()
    expect(rail(/^Applications/)).not.toBeDisabled()
    expect(rail(/^People/)).toBeDisabled()
    expect(rail(/^Notes/)).not.toBeDisabled()
    expect(selectorRow()).not.toHaveClass('border-l-apt-gold')
  })

  it('ftd-004 derives the focused header from topic, item and suffix', () => {
    renderFtd({ nameSuffix: 'Ecosystem' })
    expect(screen.getByRole('heading', { name: 'Applications (Temporal Ecosystem)' })).toBeInTheDocument()
  })

  it('ftd-005 an explicit title overrides the derived header', () => {
    renderFtd({ title: 'Custom', nameSuffix: 'Ecosystem' })
    expect(screen.getByRole('heading', { name: 'Custom' })).toBeInTheDocument()
    expect(screen.queryByText('Applications (Temporal Ecosystem)')).toBeNull()
  })

  it('ftd-006 omits the header row when there is no title and no suffix', () => {
    renderFtd()
    expect(screen.queryByRole('heading')).toBeNull()
    expect(screen.getByTestId('pane')).toBeInTheDocument()
  })

  it('ftd-007 renders one card per item and clicking one focuses it', () => {
    const { onFocus } = renderFtd({ focusedId: null })
    expect(screen.getByText('com.temporal')).toBeInTheDocument()
    expect(screen.getAllByRole('button', { name: /blurb/ })).toHaveLength(3)
    fireEvent.click(screen.getByText('Acme'))
    expect(onFocus).toHaveBeenCalledWith('acme')
  })

  it('ftd-008 shows the empty copy and no cards when there are no items', () => {
    renderFtd({ items: [], focusedId: null })
    expect(screen.getByText('Nothing here yet.')).toBeInTheDocument()
    expect(screen.queryByText(/blurb/)).toBeNull()
  })

  it('ftd-009 switching focus remounts the pane children with fresh state', () => {
    function Counter() {
      const [n, setN] = useState(0)
      return <button onClick={() => setN(n + 1)}>count {n}</button>
    }
    function Harness({ id }: { id: string }) {
      return (
        <FocusedTopicDetail
          items={ITEMS}
          focusedId={id}
          onFocus={() => {}}
          topics={TOPICS}
          activeTopicId="apps"
          onTopicSelect={() => {}}
          popupAriaLabel="Ecosystem"
        >
          <Counter />
        </FocusedTopicDetail>
      )
    }
    const { rerender } = render(<Harness id="temporal" />)
    fireEvent.click(screen.getByText('count 0'))
    expect(screen.getByText('count 1')).toBeInTheDocument()
    rerender(<Harness id="acme" />)
    expect(screen.getByText('count 0')).toBeInTheDocument()
  })

  it('ftd-010 choosing All clears focus; choosing an item focuses it', async () => {
    const user = userEvent.setup({ pointerEventsCheck: 0 })
    const { onFocus } = renderFtd()
    await user.click(screen.getByLabelText('Ecosystem'))
    await user.click(await screen.findByRole('menuitemradio', { name: 'All' }))
    expect(onFocus).toHaveBeenCalledWith(null)
    await user.click(screen.getByLabelText('Ecosystem'))
    await user.click(await screen.findByRole('menuitemradio', { name: 'Globex' }))
    await waitFor(() => expect(onFocus).toHaveBeenCalledWith('globex'))
  })

  it('ftd-011 offers no New entry without onNew, and one with it', async () => {
    const user = userEvent.setup({ pointerEventsCheck: 0 })
    renderFtd()
    await user.click(screen.getByLabelText('Ecosystem'))
    await screen.findByRole('menuitemradio', { name: 'All' })
    expect(screen.queryByRole('menuitem', { name: 'New…' })).toBeNull()
    cleanup()

    const onNew = vi.fn()
    renderFtd({ onNew, newLabel: 'New ecosystem' })
    await user.click(screen.getByLabelText('Ecosystem'))
    await user.click(await screen.findByRole('menuitem', { name: 'New ecosystem' }))
    expect(onNew).toHaveBeenCalled()
  })
})
