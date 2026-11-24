import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { Disclosure } from '../components/disclosure'

const toggle = () => screen.getByRole('button', { name: /Section/ })

describe('Disclosure conformance vectors', () => {
  it('T1 toggle-on-header-click: click shows then hides children', () => {
    render(<Disclosure title="Section"><p>body</p></Disclosure>)
    fireEvent.click(toggle())
    expect(screen.getByText('body')).toBeTruthy()
    fireEvent.click(toggle())
    expect(screen.queryByText('body')).toBeNull()
  })

  it('T2 support-uncontrolled: defaultOpen only, two clicks', () => {
    render(<Disclosure title="Section" defaultOpen={false}><p>body</p></Disclosure>)
    fireEvent.click(toggle())
    expect(screen.getByText('body')).toBeTruthy()
    fireEvent.click(toggle())
    expect(screen.queryByText('body')).toBeNull()
  })

  it('T3 support-controlled: open=false with ignoring callback stays closed', () => {
    const onOpenChange = vi.fn()
    render(<Disclosure title="Section" open={false} onOpenChange={onOpenChange}><p>body</p></Disclosure>)
    fireEvent.click(toggle())
    expect(onOpenChange).toHaveBeenCalledTimes(1)
    expect(screen.queryByText('body')).toBeNull()
    expect(toggle().getAttribute('aria-expanded')).toBe('false')
  })

  it('T4 rotate-chevron: open chevron gains rotate-90', () => {
    render(<Disclosure title="Section"><p>body</p></Disclosure>)
    const chevron = () => toggle().querySelector('svg')!
    expect(chevron().getAttribute('class')).not.toContain('rotate-90')
    fireEvent.click(toggle())
    expect(chevron().getAttribute('class')).toContain('rotate-90')
  })

  it('T5 actions-exempt-from-toggle: clicking an action does not toggle', () => {
    const onAction = vi.fn()
    render(
      <Disclosure title="Section" actions={<button type="button" onClick={onAction}>Act</button>}>
        <p>body</p>
      </Disclosure>,
    )
    fireEvent.click(screen.getByRole('button', { name: 'Act' }))
    expect(onAction).toHaveBeenCalledTimes(1)
    expect(screen.queryByText('body')).toBeNull()
    expect(toggle().getAttribute('aria-expanded')).toBe('false')
  })

  it('T6 mount-children-only-when-open: collapsed children absent', () => {
    render(<Disclosure title="Section"><p>body</p></Disclosure>)
    expect(screen.queryByText('body')).toBeNull()
  })

  it('T7 toggle-on-header-click: Enter and Space on the focused header', async () => {
    const user = userEvent.setup()
    render(<Disclosure title="Section"><p>body</p></Disclosure>)
    toggle().focus()
    await user.keyboard('{Enter}')
    expect(screen.getByText('body')).toBeTruthy()
    await user.keyboard('{Enter}')
    expect(screen.queryByText('body')).toBeNull()
    await user.keyboard(' ')
    expect(screen.getByText('body')).toBeTruthy()
    await user.keyboard(' ')
    expect(screen.queryByText('body')).toBeNull()
  })

  it('T8 expose-expanded-state: aria-expanded follows open state', () => {
    render(<Disclosure title="Section"><p>body</p></Disclosure>)
    expect(toggle().getAttribute('aria-expanded')).toBe('false')
    fireEvent.click(toggle())
    expect(toggle().getAttribute('aria-expanded')).toBe('true')
    fireEvent.click(toggle())
    expect(toggle().getAttribute('aria-expanded')).toBe('false')
  })

  it('T9 support-uncontrolled: defaultOpen true mounts children on first render', () => {
    render(<Disclosure title="Section" defaultOpen><p>body</p></Disclosure>)
    expect(screen.getByText('body')).toBeTruthy()
    expect(toggle().getAttribute('aria-expanded')).toBe('true')
  })

  it('T10 support-controlled: open=true with ignoring callback stays open', () => {
    const onOpenChange = vi.fn()
    render(<Disclosure title="Section" open onOpenChange={onOpenChange}><p>body</p></Disclosure>)
    expect(screen.getByText('body')).toBeTruthy()
    expect(toggle().getAttribute('aria-expanded')).toBe('true')
    fireEvent.click(toggle())
    expect(onOpenChange).toHaveBeenCalledWith(false)
    expect(screen.getByText('body')).toBeTruthy()
  })

  it('T11 on-open-change-uncontrolled: spy gets true then false', () => {
    const onOpenChange = vi.fn()
    render(<Disclosure title="Section" onOpenChange={onOpenChange}><p>body</p></Disclosure>)
    fireEvent.click(toggle())
    expect(onOpenChange).toHaveBeenNthCalledWith(1, true)
    expect(screen.getByText('body')).toBeTruthy()
    fireEvent.click(toggle())
    expect(onOpenChange).toHaveBeenNthCalledWith(2, false)
    expect(screen.queryByText('body')).toBeNull()
  })

  it('T12 link-toggle-to-body: aria-controls equals the body id', () => {
    render(<Disclosure title="Section" defaultOpen><p>body</p></Disclosure>)
    const body = screen.getByText('body').parentElement!
    expect(toggle().getAttribute('aria-controls')).toBe(body.id)
  })

  it('T13 rtl-chevron: chevron points left when collapsed under rtl, down when open', () => {
    render(<div dir="rtl"><Disclosure title="Section"><p>body</p></Disclosure></div>)
    const cls = () => toggle().querySelector('svg')!.getAttribute('class')!.split(' ')
    // Tailwind v4's rtl: variant applies under any [dir="rtl"] ancestor; jsdom computes no CSS.
    expect(cls()).toContain('rtl:rotate-180')
    fireEvent.click(toggle())
    expect(cls()).toContain('rotate-90')
    expect(cls()).not.toContain('rtl:rotate-180')
  })

  it('T14 respect-reduced-motion: chevron transition is dropped under reduce', () => {
    render(<Disclosure title="Section"><p>body</p></Disclosure>)
    // jsdom computes no CSS, so assert the motion-reduce utility that zeroes the transition.
    expect(toggle().querySelector('svg')!.getAttribute('class')!.split(' ')).toContain('motion-reduce:transition-none')
  })
})
