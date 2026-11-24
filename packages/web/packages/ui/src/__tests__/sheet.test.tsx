/**
 * Conformance vectors for the Sheet recipe (sheet-001 .. sheet-026).
 *
 * jsdom has no CSS engine, no layout and no CSS transitions, so vectors that inspect computed
 * style, rendered width or transition timing are skipped with a reason; class-composition vectors
 * assert the utility classes the source applies.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, cleanup, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, afterEach, vi } from 'vitest'

import * as SheetModule from '../components/sheet'
import {
  Sheet,
  SheetTrigger,
  SheetContent,
  SheetHeader,
  SheetFooter,
  SheetTitle,
  SheetDescription,
} from '../components/sheet'

afterEach(cleanup)

const popup = () => document.querySelector('[data-slot="sheet-content"]') as HTMLElement
const overlay = () => document.querySelector('[data-slot="sheet-overlay"]') as HTMLElement
const closeButton = () => document.querySelector('button[data-slot="sheet-close"]') as HTMLElement | null

function open(content: React.ReactNode = <SheetTitle>T</SheetTitle>, contentProps: object = {}) {
  return render(
    <Sheet open>
      <SheetContent {...contentProps}>{content}</SheetContent>
    </Sheet>,
  )
}

describe('Sheet conformance vectors', () => {
  it('sheet-001 exports the 8 compound components and no SheetPortal/SheetOverlay', () => {
    expect(Object.keys(SheetModule).sort()).toEqual(
      [
        'Sheet',
        'SheetClose',
        'SheetContent',
        'SheetDescription',
        'SheetFooter',
        'SheetHeader',
        'SheetTitle',
        'SheetTrigger',
      ].sort(),
    )
    for (const name of ['SheetPortal', 'SheetOverlay']) {
      expect((SheetModule as Record<string, unknown>)[name]).toBeUndefined()
    }
  })

  it('sheet-002 side="left" sets data-side="left"', () => {
    open(undefined, { side: 'left' })
    expect(popup()).toHaveAttribute('data-side', 'left')
    expect(popup().className).toContain('data-[side=left]:left-0')
  })

  it('sheet-003 defaults to the right side', () => {
    open()
    expect(popup()).toHaveAttribute('data-side', 'right')
    expect(popup().className).toContain('data-[side=right]:right-0')
  })

  it('sheet-004 renders the overlay with data-slot="sheet-overlay"', () => {
    open()
    expect(overlay()).toBeInTheDocument()
  })

  it.skip('sheet-005 overlay computed backdrop-filter includes a blur (jsdom has no CSS engine)', () => {})

  it('sheet-006 shows the close button by default', () => {
    open()
    expect(closeButton()).toBeInTheDocument()
    expect(closeButton()!.className).toContain('top-3')
    expect(closeButton()!.className).toContain('right-3')
  })

  it('sheet-007 showCloseButton={false} hides the close button', () => {
    open(undefined, { showCloseButton: false })
    expect(closeButton()).toBeNull()
  })

  it('sheet-008 the close icon is lucide XIcon', () => {
    open()
    expect(closeButton()!.querySelector('svg')).toHaveClass('lucide-x')
  })

  it('sheet-009 the close button is named "Close"', () => {
    open()
    expect(screen.getByRole('button', { name: 'Close' })).toBe(closeButton())
    expect(closeButton()!.querySelector('span')).toHaveClass('sr-only')
  })

  it.skip('sheet-010 entry transition animates opacity and transform (jsdom has no CSS transitions)', () => {})
  it.skip('sheet-011 exit transition animates opacity and transform (jsdom has no CSS transitions)', () => {})
  it.skip('sheet-012 --apt-anim-scale=2 gives 300ms/400ms durations (jsdom does not evaluate calc()/var())', () => {})
  it.skip('sheet-013 --apt-anim-scale<=0 clamps duration to 0 (jsdom does not evaluate calc()/var())', () => {})

  it('sheet-014 clicking the overlay closes the drawer via onOpenChange', async () => {
    const onOpenChange = vi.fn()
    const user = userEvent.setup()
    render(
      <Sheet defaultOpen onOpenChange={onOpenChange}>
        <SheetContent>
          <SheetTitle>T</SheetTitle>
        </SheetContent>
      </Sheet>,
    )
    await user.click(overlay())
    expect(onOpenChange).toHaveBeenCalledTimes(1)
    expect(onOpenChange.mock.calls[0]![0]).toBe(false)
    expect(onOpenChange.mock.calls[0]![1].reason).toBe('outside-press')
    await waitFor(() => expect(popup()).toBeNull())
  })

  it.skip('sheet-015 right drawer is 75% wide capped at 24rem from 640px (jsdom has no layout or media queries)', () => {})

  it('sheet-016 an extra className lands on the drawer element', () => {
    open(undefined, { className: 'extra-class' })
    expect(popup()).toHaveClass('extra-class')
  })

  it('sheet-017 header and footer are padded column-flex divs', () => {
    render(
      <>
        <SheetHeader data-testid="h" />
        <SheetFooter data-testid="f" />
      </>,
    )
    for (const id of ['h', 'f']) {
      const el = screen.getByTestId(id)
      expect(el.tagName).toBe('DIV')
      expect(el).toHaveClass('p-4', 'flex', 'flex-col')
    }
  })

  it('sheet-018 title is font-medium and description is muted', () => {
    open(
      <>
        <SheetTitle>Title</SheetTitle>
        <SheetDescription>Desc</SheetDescription>
      </>,
    )
    expect(screen.getByText('Title')).toHaveClass('font-medium')
    expect(screen.getByText('Desc')).toHaveClass('text-muted-foreground')
  })

  it('sheet-019 renders an empty drawer without error', () => {
    open(null, { showCloseButton: false })
    expect(popup()).toBeInTheDocument()
    expect(popup()).toBeEmptyDOMElement()
  })

  it('sheet-020 two open sheets render independently with fixed z-50 layers', () => {
    render(
      <>
        <Sheet open>
          <SheetContent aria-label="First" />
        </Sheet>
        <Sheet open>
          <SheetContent aria-label="Second" />
        </Sheet>
      </>,
    )
    const popups = document.querySelectorAll('[data-slot="sheet-content"]')
    const overlays = document.querySelectorAll('[data-slot="sheet-overlay"]')
    expect(popups).toHaveLength(2)
    expect(overlays).toHaveLength(2)
    for (const el of [...popups, ...overlays]) {
      expect(el).toHaveClass('fixed', 'z-50')
    }
  })

  it.skip('sheet-021 interrupted transition reverses from its computed value (jsdom has no CSS transitions)', () => {})
  it.skip('sheet-022 left drawer is 240px on a 320px viewport (jsdom has no layout)', () => {})

  it('sheet-023 Escape closes the drawer and fires onOpenChange(false)', async () => {
    const onOpenChange = vi.fn()
    const user = userEvent.setup()
    render(
      <Sheet defaultOpen onOpenChange={onOpenChange}>
        <SheetContent>
          <SheetTitle>T</SheetTitle>
        </SheetContent>
      </Sheet>,
    )
    await user.keyboard('{Escape}')
    expect(onOpenChange).toHaveBeenCalledTimes(1)
    expect(onOpenChange.mock.calls[0]![0]).toBe(false)
    await waitFor(() => expect(popup()).toBeNull())
  })

  it('sheet-024 focus moves into the drawer on open and back to the trigger on close', async () => {
    const user = userEvent.setup()
    render(
      <Sheet>
        <SheetTrigger>Open</SheetTrigger>
        <SheetContent>
          <SheetTitle>T</SheetTitle>
        </SheetContent>
      </Sheet>,
    )
    const trigger = screen.getByRole('button', { name: 'Open' })
    await user.click(trigger)
    await waitFor(() => expect(popup().contains(document.activeElement)).toBe(true))
    await user.keyboard('{Escape}')
    await waitFor(() => expect(popup()).toBeNull())
    await waitFor(() => expect(trigger).toHaveFocus())
  })

  it('sheet-025 bottom drawer spans the viewport width via inset-x-0', () => {
    open(undefined, { side: 'bottom' })
    expect(popup()).toHaveAttribute('data-side', 'bottom')
    expect(popup().className).toContain('data-[side=bottom]:inset-x-0')
  })

  it('sheet-026 aria-label names the dialog when there is no SheetTitle', () => {
    open(null, { 'aria-label': 'Settings' })
    expect(screen.getByRole('dialog', { name: 'Settings' })).toBeInTheDocument()
  })
})
