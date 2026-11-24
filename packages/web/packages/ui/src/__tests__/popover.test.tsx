import { useState } from 'react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Popover, PopoverTrigger, PopoverContent } from '../components/popover'

afterEach(cleanup)

type ContentProps = Partial<React.ComponentProps<typeof PopoverContent>>

function Controlled({
  open,
  onOpenChange,
  content,
}: {
  open: boolean
  onOpenChange?: (open: boolean) => void
  content?: ContentProps
}) {
  return (
    <div>
      <button>Outside</button>
      <Popover open={open} onOpenChange={onOpenChange}>
        <PopoverTrigger>Trigger</PopoverTrigger>
        <PopoverContent {...content}>
          <p>Content text</p>
        </PopoverContent>
      </Popover>
    </div>
  )
}

const popup = () => document.querySelector('[data-slot="popover-content"]') as HTMLElement | null
const arrow = () => document.querySelector('[data-slot="popover-arrow"]') as HTMLElement | null

describe('PopoverContent (full-featured)', () => {
  it('popover-001: open={true} puts PopoverContent in the DOM', async () => {
    render(<Controlled open />)
    await waitFor(() => expect(popup()).not.toBeNull())
  })

  it('popover-003: open={false} leaves no PopoverContent subtree', () => {
    render(<Controlled open={false} />)
    expect(popup()).toBeNull()
    expect(screen.queryByText('Content text')).toBeNull()
  })

  it.each([
    ['popover-005', 'top'],
    ['popover-006', 'bottom'],
    ['popover-007', 'left'],
    ['popover-008', 'right'],
  ] as const)('%s: side="%s" is handed to the positioner (data-side on the popup)', async (_id, side) => {
    render(<Controlled open content={{ side }} />)
    await waitFor(() => expect(popup()).not.toBeNull())
    // jsdom has no layout, so the geometric "above/below" is not measurable; Base UI
    // reports the resolved side on the popup, and with no collisions it is the requested one.
    expect(popup()!.getAttribute('data-side')).toBe(side)
  })

  it('popover-011: children render inside the panel', async () => {
    render(<Controlled open />)
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(popup()!).toContainElement(screen.getByText('Content text'))
  })

  it.each([
    ['popover-014', 'start'],
    ['popover-015', 'center'],
    ['popover-016', 'end'],
  ] as const)('%s: align="%s" reaches the popup as data-align', async (_id, align) => {
    render(<Controlled open content={align === 'center' ? undefined : { align }} />)
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(popup()!.getAttribute('data-align')).toBe(align)
  })

  it('popover-017: className is applied alongside the default classes', async () => {
    render(<Controlled open content={{ className: 'custom-popover-class' }} />)
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(popup()!).toHaveClass('custom-popover-class', 'rounded-lg', 'bg-apt-surface')
  })

  it('popover-018: arrow={true} renders the pointer element', async () => {
    render(<Controlled open content={{ arrow: true }} />)
    await waitFor(() => expect(arrow()).not.toBeNull())
    expect(arrow()).toHaveClass('size-2')
  })

  it('popover-019: arrow defaults to no pointer', async () => {
    render(<Controlled open />)
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(arrow()).toBeNull()
  })

  it('popover-020: the popup has role="dialog"', async () => {
    render(<Controlled open />)
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(popup()!.getAttribute('role')).toBe('dialog')
  })

  it('popover-023: Escape calls onOpenChange(false) and the consumer closing it unmounts the content', async () => {
    const onOpenChange = vi.fn()
    function Harness() {
      const [open, setOpen] = useState(true)
      return (
        <Controlled
          open={open}
          onOpenChange={(next) => {
            onOpenChange(next)
            setOpen(next)
          }}
        />
      )
    }
    render(<Harness />)
    await waitFor(() => expect(popup()).not.toBeNull())
    fireEvent.keyDown(popup()!, { key: 'Escape' })
    await waitFor(() => expect(onOpenChange).toHaveBeenCalledWith(false))
    await waitFor(() => expect(popup()).toBeNull())
  })

  it('popover-024: an open popover marks its trigger aria-expanded="true"', async () => {
    render(<Controlled open />)
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(screen.getByText('Trigger')).toHaveAttribute('aria-expanded', 'true')
  })

  it('popover-025: a closed popover marks its trigger aria-expanded="false"', () => {
    render(<Controlled open={false} />)
    expect(screen.getByText('Trigger')).toHaveAttribute('aria-expanded', 'false')
  })

  it('popover-026: pressing outside calls onOpenChange(false)', async () => {
    const onOpenChange = vi.fn()
    const user = userEvent.setup()
    render(<Controlled open onOpenChange={onOpenChange} />)
    await waitFor(() => expect(popup()).not.toBeNull())
    await user.click(screen.getByText('Outside'))
    await waitFor(() => expect(onOpenChange).toHaveBeenCalled())
    expect(onOpenChange.mock.calls[0]![0]).toBe(false)
  })

  it('popover-027: the trigger toggles, calling onOpenChange(false) then onOpenChange(true)', async () => {
    const onOpenChange = vi.fn()
    const user = userEvent.setup()
    function Harness() {
      const [open, setOpen] = useState(true)
      return (
        <Controlled
          open={open}
          onOpenChange={(next) => {
            onOpenChange(next)
            setOpen(next)
          }}
        />
      )
    }
    render(<Harness />)
    await waitFor(() => expect(popup()).not.toBeNull())
    await user.click(screen.getByText('Trigger'))
    await waitFor(() => expect(popup()).toBeNull())
    await user.click(screen.getByText('Trigger'))
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(onOpenChange.mock.calls.map((c) => c[0])).toEqual([false, true])
  })

  it('popover-028: aria-label on PopoverContent lands on the dialog element', async () => {
    render(<Controlled open content={{ 'aria-label': 'Help' }} />)
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(popup()!).toHaveAttribute('role', 'dialog')
    expect(popup()!).toHaveAttribute('aria-label', 'Help')
  })

  it.each([
    ['popover-031', 'top', 'data-[side=top]:rotate-45'],
    ['popover-032', 'bottom', 'data-[side=bottom]:rotate-[225deg]'],
    ['popover-033', 'left', 'data-[side=left]:rotate-[315deg]'],
    ['popover-034', 'right', 'data-[side=right]:rotate-[135deg]'],
  ] as const)('%s: arrow on side="%s" carries its rotation rule', async (_id, side, rule) => {
    render(<Controlled open content={{ arrow: true, side }} />)
    await waitFor(() => expect(arrow()).not.toBeNull())
    // jsdom resolves no Tailwind cascade, so the rotation itself is not measurable;
    // the per-side rule on the element, and Base UI marking the arrow's side, are.
    expect(arrow()!.className).toContain(rule)
    expect(arrow()!.getAttribute('data-side')).toBe(side)
  })

  it.skip('popover-013: sideOffset={16} gap of 16px (needs real layout)', () => {})
  it.skip('popover-029: default sideOffset gap of 8px (needs real layout)', () => {})
  it.skip('popover-021: Tab through the panel does not cycle (jsdom has no real tab order; needs a browser)', () => {})
  it.skip('popover-022: Tab out of the last element moves focus past the trigger (jsdom has no real tab order; needs a browser)', () => {})
})
