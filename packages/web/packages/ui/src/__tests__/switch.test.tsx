import { fireEvent, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { Switch } from '../components/switch'

function sw(): HTMLElement {
  return screen.getByRole('switch')
}

describe('Switch', () => {
  it('switch-001 uncontrolled click checks an unchecked switch', async () => {
    render(<Switch aria-label="s" />)
    expect(sw().getAttribute('aria-checked')).toBe('false')
    await userEvent.click(sw())
    expect(sw().getAttribute('aria-checked')).toBe('true')
  })
  it('switch-002 uncontrolled click unchecks a defaultChecked switch', async () => {
    render(<Switch aria-label="s" defaultChecked />)
    expect(sw().getAttribute('aria-checked')).toBe('true')
    await userEvent.click(sw())
    expect(sw().getAttribute('aria-checked')).toBe('false')
  })
  it('switch-003 controlled switch reports the toggle but stays at the prop value', async () => {
    const onCheckedChange = vi.fn()
    render(<Switch aria-label="s" checked onCheckedChange={onCheckedChange} />)
    await userEvent.click(sw())
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
    expect(onCheckedChange.mock.calls[0]![0]).toBe(false)
    expect(sw().getAttribute('aria-checked')).toBe('true')
  })
  it('switch-004 defaultChecked toggles without an external callback', async () => {
    render(<Switch aria-label="s" defaultChecked />)
    await userEvent.click(sw())
    expect(sw().getAttribute('aria-checked')).toBe('false')
    await userEvent.click(sw())
    expect(sw().getAttribute('aria-checked')).toBe('true')
  })
  it('switch-005 disabled switch ignores clicks', () => {
    const onCheckedChange = vi.fn()
    render(<Switch aria-label="s" disabled onCheckedChange={onCheckedChange} />)
    fireEvent.click(sw())
    expect(onCheckedChange).not.toHaveBeenCalled()
    expect(sw().getAttribute('aria-checked')).toBe('false')
    expect(sw().hasAttribute('data-disabled')).toBe(true)
  })
  it.skip('switch-006 thumb transform transition (jsdom has no Tailwind CSS, so computed transition-property and duration are unavailable)', () => {})
  it.skip('switch-007 track color transition (jsdom has no Tailwind CSS, so computed transition styles are unavailable)', () => {})
  it.skip('switch-008 computed display inline-flex (jsdom loads no stylesheet, so computed display is unavailable)', () => {})
  it('switch-009 custom className merges with the internal classes', () => {
    render(<Switch aria-label="s" className="my-custom-class" />)
    expect(sw().classList.contains('my-custom-class')).toBe(true)
    expect(sw().classList.contains('inline-flex')).toBe(true)
    expect(sw().getAttribute('data-slot')).toBe('switch')
  })
  it('switch-010 disabled controlled switch follows the checked prop and ignores clicks', () => {
    const onCheckedChange = vi.fn()
    const { rerender } = render(
      <Switch aria-label="s" disabled checked onCheckedChange={onCheckedChange} />,
    )
    expect(sw().getAttribute('aria-checked')).toBe('true')
    expect(sw().hasAttribute('data-checked')).toBe(true)
    rerender(<Switch aria-label="s" disabled checked={false} onCheckedChange={onCheckedChange} />)
    expect(sw().getAttribute('aria-checked')).toBe('false')
    expect(sw().hasAttribute('data-unchecked')).toBe(true)
    expect(sw().className).toContain('transition-colors')
    fireEvent.click(sw())
    expect(onCheckedChange).not.toHaveBeenCalled()
    expect(sw().getAttribute('aria-checked')).toBe('false')
  })
  it('switch-011 Tab then Space toggles an uncontrolled switch', async () => {
    const user = userEvent.setup()
    render(<Switch aria-label="s" />)
    await user.tab()
    expect(document.activeElement).toBe(sw())
    await user.keyboard(' ')
    expect(sw().getAttribute('aria-checked')).toBe('true')
  })
  it('switch-012 exposes role switch with name and checked state', () => {
    render(<Switch aria-label="Notifications" defaultChecked />)
    const el = screen.getByRole('switch', { name: 'Notifications' })
    expect(el.getAttribute('aria-checked')).toBe('true')
  })
  it('switch-013 focused disabled switch ignores Space', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Switch aria-label="s" disabled onCheckedChange={onCheckedChange} />)
    await user.tab()
    await user.keyboard(' ')
    expect(onCheckedChange).not.toHaveBeenCalled()
    expect(sw().getAttribute('aria-checked')).toBe('false')
  })
  it('switch-014 three rapid clicks alternate checked, unchecked, checked', async () => {
    const user = userEvent.setup()
    render(<Switch aria-label="s" />)
    await user.click(sw())
    expect(sw().getAttribute('aria-checked')).toBe('true')
    await user.click(sw())
    expect(sw().getAttribute('aria-checked')).toBe('false')
    await user.click(sw())
    expect(sw().getAttribute('aria-checked')).toBe('true')
  })
  it('switch-015 unchecked controlled click fires onCheckedChange(true) once', async () => {
    const onCheckedChange = vi.fn()
    render(<Switch aria-label="s" checked={false} onCheckedChange={onCheckedChange} />)
    await userEvent.click(sw())
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
    expect(onCheckedChange.mock.calls[0]![0]).toBe(true)
  })
  it('switch-016 checked controlled click fires onCheckedChange(false) once', async () => {
    const onCheckedChange = vi.fn()
    render(<Switch aria-label="s" checked onCheckedChange={onCheckedChange} />)
    await userEvent.click(sw())
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
    expect(onCheckedChange.mock.calls[0]![0]).toBe(false)
  })
  it('switch-017 Tab then Space fires onCheckedChange once on a controlled switch', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Switch aria-label="s" checked={false} onCheckedChange={onCheckedChange} />)
    await user.tab()
    await user.keyboard(' ')
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
    expect(onCheckedChange.mock.calls[0]![0]).toBe(true)
  })
  it('switch-018 readOnly switch ignores clicks', async () => {
    const onCheckedChange = vi.fn()
    render(<Switch aria-label="s" readOnly onCheckedChange={onCheckedChange} />)
    await userEvent.click(sw())
    expect(onCheckedChange).not.toHaveBeenCalled()
    expect(sw().getAttribute('aria-checked')).toBe('false')
  })
  it('switch-019 checked switch submits name=value in a form', () => {
    const { unmount } = render(
      <form data-testid="f">
        <Switch aria-label="s" name="notify" value="yes" defaultChecked />
      </form>,
    )
    let data = new FormData(screen.getByTestId('f') as HTMLFormElement)
    expect(data.get('notify')).toBe('yes')
    unmount()
    render(
      <form data-testid="f">
        <Switch aria-label="s" name="notify" value="yes" />
      </form>,
    )
    data = new FormData(screen.getByTestId('f') as HTMLFormElement)
    expect(data.has('notify')).toBe(false)
  })
})
