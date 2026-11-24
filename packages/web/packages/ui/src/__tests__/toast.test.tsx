/**
 * Conformance vectors for the Toast recipe (toast-001 .. toast-023).
 *
 * jsdom has no layout, CSS engine or transitions, so width/animation vectors are skipped with a
 * reason; class-composition vectors assert the utility classes the source applies.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, cleanup, act, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, afterEach, vi } from 'vitest'

import { ToastProvider, Toaster, useToast } from '../components/toast'

afterEach(() => {
  cleanup()
  vi.useRealTimers()
})

function Adder({ label = 'add', toast = { title: 'Success' } }: { label?: string; toast?: Record<string, unknown> }) {
  const { add } = useToast()
  return (
    <button type="button" onClick={() => add(toast)}>
      {label}
    </button>
  )
}

function mount(toast?: Record<string, unknown>, providerProps: Record<string, unknown> = {}) {
  render(
    <ToastProvider {...providerProps}>
      <Adder toast={toast} />
      <Toaster />
    </ToastProvider>,
  )
}

const viewport = () => document.querySelector('[data-base-ui-toast-viewport], [role="region"]') as HTMLElement
const toastRoots = () => Array.from(document.querySelectorAll('[role="dialog"]')) as HTMLElement[]
const closeBtn = () => document.querySelector('button[aria-label="Close"]') as HTMLElement

describe('Toast conformance vectors', () => {
  it('toast-001 renders the title', async () => {
    mount({ title: 'Success' })
    await userEvent.click(screen.getByText('add'))
    expect(await screen.findByText('Success')).toBeInTheDocument()
  })

  it('toast-002 renders the description', async () => {
    mount({ description: 'Operation complete' })
    await userEvent.click(screen.getByText('add'))
    expect(await screen.findByText('Operation complete')).toBeInTheDocument()
  })

  it('toast-003 renders a close button with an X icon', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    const btn = await waitFor(() => { expect(closeBtn()).not.toBeNull(); return closeBtn() })
    expect(btn.querySelector('svg')).toHaveClass('lucide-x')
  })

  it('toast-004 clicking close removes the toast', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    await userEvent.click(await waitFor(() => { expect(closeBtn()).not.toBeNull(); return closeBtn() }))
    await waitFor(() => expect(screen.queryByText('Success')).toBeNull())
  })

  it('toast-005 add() inside the provider subtree enqueues a toast', async () => {
    mount({ title: 'Alert' })
    await userEvent.click(screen.getByText('add'))
    expect(await screen.findByText('Alert')).toBeInTheDocument()
  })

  it('toast-006 viewport is fixed 1rem from the inline-end and bottom', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    await screen.findByText('Success')
    expect(viewport()).toHaveClass('fixed', 'end-4', 'bottom-4')
  })

  it('toast-007 viewport sits at z-50', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    await screen.findByText('Success')
    expect(viewport()).toHaveClass('z-50')
  })

  it.skip('toast-008 opacity transitions 0 to 1 on entrance (jsdom has no CSS transitions)', () => {})
  it.skip('toast-009 opacity transitions to 0 on exit (jsdom has no CSS transitions)', () => {})

  it('toast-010 viewport stacks toasts in a column with a 0.5rem gap', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    await screen.findByText('Success')
    expect(viewport()).toHaveClass('flex', 'flex-col', 'gap-2')
  })

  it.skip('toast-011 toast is 320px wide at a 1024px viewport (jsdom has no layout)', () => {})
  it.skip('toast-012 toast width caps at calc(100vw - 2rem) at 320px (jsdom has no layout)', () => {})

  it('toast-013 each provider shows only its own toasts', async () => {
    render(
      <>
        <ToastProvider>
          <Adder label="add-a" toast={{ title: 'From A' }} />
          <Toaster />
        </ToastProvider>
        <ToastProvider>
          <Adder label="add-b" toast={{ title: 'From B' }} />
          <Toaster />
        </ToastProvider>
      </>,
    )
    await userEvent.click(screen.getByText('add-a'))
    expect(await screen.findByText('From A')).toBeInTheDocument()
    expect(screen.queryByText('From B')).toBeNull()
    expect(document.querySelectorAll('[role="region"], [data-base-ui-toast-viewport]').length).toBeGreaterThan(0)
    await userEvent.click(screen.getByText('add-b'))
    expect(await screen.findByText('From B')).toBeInTheDocument()
    expect(screen.getByText('From A')).toBeInTheDocument()
  })

  it('toast-014 close label is the caller-supplied localized string', async () => {
    render(
      <ToastProvider>
        <Adder />
        <Toaster closeLabel="Fermer" />
      </ToastProvider>,
    )
    await userEvent.click(screen.getByText('add'))
    await screen.findByText('Success')
    expect(document.querySelector('button[aria-label="Fermer"]')).not.toBeNull()
    expect(document.querySelector('button[aria-label="Close"]')).toBeNull()
  })

  // jsdom evaluates no media queries, so assert the reduced-motion utility on the animated elements.
  it('toast-015 reduced motion disables the fade', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    await screen.findByText('Success')
    expect(toastRoots()[0]).toHaveClass('transition-all', 'motion-reduce:transition-none')
    expect(closeBtn()).toHaveClass('motion-reduce:transition-none')
  })

  // jsdom has no layout; size-11 is 2.75rem (44px) square.
  it('toast-016 close hit area is at least 44x44', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    await screen.findByText('Success')
    expect(closeBtn()).toHaveClass('size-11')
  })

  it('toast-017 viewport and close button use logical inline-end offsets', async () => {
    render(
      <div dir="rtl">
        <ToastProvider>
          <Adder />
          <Toaster />
        </ToastProvider>
      </div>,
    )
    await userEvent.click(screen.getByText('add'))
    await screen.findByText('Success')
    expect(viewport()).toHaveClass('end-4')
    expect(viewport().className).not.toMatch(/(^|\s)right-/)
    expect(closeBtn()).toHaveClass('end-0')
    expect(closeBtn().className).not.toMatch(/(^|\s)right-/)
    expect(toastRoots()[0]).toHaveClass('pe-11')
  })

  it('toast-018 auto-dismisses after 5000ms', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    mount()
    fireEvent.click(screen.getByText('add'))
    expect(await screen.findByText('Success')).toBeInTheDocument()
    await act(async () => {
      vi.advanceTimersByTime(4_900)
    })
    expect(screen.getByText('Success')).toBeInTheDocument()
    await act(async () => {
      vi.advanceTimersByTime(200)
    })
    await waitFor(() => expect(screen.queryByText('Success')).toBeNull())
  })

  it('toast-019 hovering pauses the auto-dismiss timer', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    mount()
    fireEvent.click(screen.getByText('add'))
    const title = await screen.findByText('Success')
    fireEvent.mouseEnter(viewport())
    fireEvent.pointerEnter(viewport())
    fireEvent.mouseEnter(title)
    await act(async () => {
      vi.advanceTimersByTime(8_000)
    })
    expect(screen.getByText('Success')).toBeInTheDocument()
    fireEvent.mouseLeave(viewport())
    fireEvent.pointerLeave(viewport())
    fireEvent.mouseLeave(title)
    await act(async () => {
      vi.advanceTimersByTime(5_500)
    })
    await waitFor(() => expect(screen.queryByText('Success')).toBeNull())
  })

  it('toast-020 Escape inside a toast dismisses it', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    await screen.findByText('Success')
    closeBtn().focus()
    await userEvent.keyboard('{Escape}')
    await waitFor(() => expect(screen.queryByText('Success')).toBeNull())
  })

  it('toast-021 swiping down past 40px dismisses the toast', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    await screen.findByText('Success')
    const root = toastRoots()[0]!
    root.setPointerCapture = () => {}
    root.releasePointerCapture = () => {}
    fireEvent.pointerDown(root, { pointerId: 1, pointerType: 'touch', clientX: 100, clientY: 100, button: 0, isPrimary: true })
    fireEvent.pointerMove(root, { pointerId: 1, pointerType: 'touch', clientX: 100, clientY: 160, isPrimary: true })
    fireEvent.pointerMove(root, { pointerId: 1, pointerType: 'touch', clientX: 100, clientY: 220, isPrimary: true })
    fireEvent.pointerUp(root, { pointerId: 1, pointerType: 'touch', clientX: 100, clientY: 220, isPrimary: true })
    await waitFor(() => expect(screen.queryByText('Success')).toBeNull())
  })

  it('toast-022 limit={2} with three toasts marks the oldest data-limited', async () => {
    render(
      <ToastProvider limit={2}>
        <Adder label="a1" toast={{ title: 'One', timeout: 0 }} />
        <Adder label="a2" toast={{ title: 'Two', timeout: 0 }} />
        <Adder label="a3" toast={{ title: 'Three', timeout: 0 }} />
        <Toaster />
      </ToastProvider>,
    )
    for (const l of ['a1', 'a2', 'a3']) await userEvent.click(screen.getByText(l))
    await screen.findByText('Three')
    const roots = toastRoots()
    const limited = roots.filter((r) => r.hasAttribute('data-limited'))
    expect(limited).toHaveLength(1)
    expect(limited[0]).toHaveTextContent('One')
  })

  it('toast-023 close button colors come from design tokens', async () => {
    mount()
    await userEvent.click(screen.getByText('add'))
    const cls = (await waitFor(() => { expect(closeBtn()).not.toBeNull(); return closeBtn() })).className
    expect(cls).toContain('text-apt-text-muted')
    expect(cls).toContain('hover:text-apt-text')
    expect(cls).toContain('focus-visible:ring-apt-gold/40')
    expect(cls).not.toMatch(/#[0-9a-fA-F]{3,8}|rgb\(|hsl\(/)
  })
})
