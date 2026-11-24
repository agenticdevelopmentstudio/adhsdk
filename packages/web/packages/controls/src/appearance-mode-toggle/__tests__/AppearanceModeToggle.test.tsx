/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, fireEvent, act, cleanup } from '@testing-library/react'
import { renderToString } from 'react-dom/server'
import { AppearanceModeToggle } from '../AppearanceModeToggle'
import { ColorModeProvider } from '@adh-sdk/themes/colorMode'

describe('AppearanceModeToggle', () => {
  it('renders a button with the awt-appearance-mode-toggle class', () => {
    const { container } = render(
      <ColorModeProvider>
        <AppearanceModeToggle />
      </ColorModeProvider>,
    )
    const btn = container.querySelector('.awt-appearance-mode-toggle')
    expect(btn).not.toBeNull()
    expect(btn?.tagName).toBe('BUTTON')
  })

  it('exposes an aria-label that changes after a click', () => {
    const { container } = render(
      <ColorModeProvider>
        <AppearanceModeToggle />
      </ColorModeProvider>,
    )
    const btn = container.querySelector('.awt-appearance-mode-toggle') as HTMLButtonElement
    const before = btn.getAttribute('aria-label')
    fireEvent.click(btn)
    const after = btn.getAttribute('aria-label')
    expect(before).not.toBeNull()
    expect(after).not.toBeNull()
    expect(after).not.toEqual(before)
  })
})

const MOON_PATH = 'M20.354'
const SUN_PATH = 'M12 3v1'
const CHANGED = 'awt:appearance-changed'
const DARK_LABEL = 'Dark mode — click for light'
const LIGHT_LABEL = 'Light mode — click for auto'

function setDom(mode: string | undefined, dark: boolean) {
  const el = document.documentElement
  if (mode === undefined) delete el.dataset.appearanceMode
  else el.dataset.appearanceMode = mode
  el.classList.toggle('dark', dark)
}

function fireChanged() {
  act(() => {
    window.dispatchEvent(new CustomEvent(CHANGED))
  })
}

function btnOf(container: HTMLElement) {
  return container.querySelector('button.awt-appearance-mode-toggle') as HTMLButtonElement
}

function pathsOf(el: Element) {
  return Array.from(el.querySelectorAll(':scope > svg path')).map((p) => p.getAttribute('d') ?? '')
}

describe('AppearanceModeToggle conformance', () => {
  afterEach(() => {
    cleanup()
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
    setDom(undefined, false)
  })

  it('toggle-001 renders a button with type="button"', () => {
    const { container } = render(<AppearanceModeToggle />)
    const btn = container.querySelector('button')
    expect(btn).not.toBeNull()
    expect(btn).toHaveAttribute('type', 'button')
  })

  it('toggle-002 reads mode dark from data-appearance-mode', () => {
    setDom('dark', true)
    const { container } = render(<AppearanceModeToggle />)
    expect(btnOf(container)).toHaveAttribute('aria-label', DARK_LABEL)
  })

  it('toggle-003 treats an invalid mode as auto', () => {
    setDom('invalid', false)
    const { container } = render(<AppearanceModeToggle />)
    expect(btnOf(container).getAttribute('aria-label')).toMatch(/^Appearance: Auto/)
    expect(container.querySelector('.awt-appearance-mode-toggle__badge')).not.toBeNull()
  })

  it('toggle-004 dark class resolves appearance to dark', () => {
    setDom('auto', true)
    const { container } = render(<AppearanceModeToggle />)
    expect(btnOf(container).getAttribute('aria-label')).toContain('currently dark')
  })

  it('toggle-005 no dark class resolves appearance to light', () => {
    setDom('auto', false)
    const { container } = render(<AppearanceModeToggle />)
    expect(btnOf(container).getAttribute('aria-label')).toContain('currently light')
  })

  it('toggle-006 resolved dark renders the moon icon and not the sun', () => {
    setDom('light', true)
    const { container } = render(<AppearanceModeToggle />)
    const paths = pathsOf(btnOf(container))
    expect(paths).toHaveLength(1)
    expect(paths[0].startsWith(MOON_PATH)).toBe(true)
    expect(paths.some((d) => d.startsWith(SUN_PATH))).toBe(false)
  })

  it('toggle-007 resolved light renders the sun icon and not the moon', () => {
    setDom('dark', false)
    const { container } = render(<AppearanceModeToggle />)
    const paths = pathsOf(btnOf(container))
    expect(paths).toHaveLength(1)
    expect(paths[0].startsWith(SUN_PATH)).toBe(true)
    expect(paths.some((d) => d.startsWith(MOON_PATH))).toBe(false)
  })

  it('toggle-008 auto mode renders the badge span with a nested svg', () => {
    setDom('auto', false)
    const { container } = render(<AppearanceModeToggle />)
    const badge = container.querySelector('span.awt-appearance-mode-toggle__badge')
    expect(badge).not.toBeNull()
    expect(badge!.querySelector('svg')).not.toBeNull()
  })

  it('toggle-009 light or dark mode renders no badge', () => {
    setDom('light', false)
    const a = render(<AppearanceModeToggle />)
    expect(a.container.querySelector('.awt-appearance-mode-toggle__badge')).toBeNull()
    a.unmount()
    setDom('dark', true)
    const b = render(<AppearanceModeToggle />)
    expect(b.container.querySelector('.awt-appearance-mode-toggle__badge')).toBeNull()
  })

  it('toggle-010 click dispatches awt:appearance-cycle on window with no detail', () => {
    const handler = vi.fn()
    window.addEventListener('awt:appearance-cycle', handler)
    try {
      const { container } = render(<AppearanceModeToggle />)
      fireEvent.click(btnOf(container))
      expect(handler).toHaveBeenCalledTimes(1)
      const evt = handler.mock.calls[0][0] as CustomEvent
      expect(evt.type).toBe('awt:appearance-cycle')
      expect(evt.detail).toBeNull()
    } finally {
      window.removeEventListener('awt:appearance-cycle', handler)
    }
  })

  it('toggle-011 awt:appearance-changed re-reads the DOM and updates icon and label', () => {
    setDom('auto', false)
    const { container } = render(<AppearanceModeToggle />)
    expect(pathsOf(btnOf(container))[0].startsWith(SUN_PATH)).toBe(true)
    setDom('dark', true)
    fireChanged()
    expect(pathsOf(btnOf(container))[0].startsWith(MOON_PATH)).toBe(true)
    expect(btnOf(container)).toHaveAttribute('aria-label', DARK_LABEL)
  })

  it('toggle-012 auto mode, resolved light: aria-label and title are the auto template', () => {
    setDom('auto', false)
    const { container } = render(<AppearanceModeToggle />)
    const text = 'Appearance: Auto (currently light). Click to switch to dark.'
    expect(btnOf(container)).toHaveAttribute('aria-label', text)
    expect(btnOf(container)).toHaveAttribute('title', text)
  })

  it('toggle-013 dark mode: aria-label and title are the dark template', () => {
    setDom('dark', true)
    const { container } = render(<AppearanceModeToggle />)
    expect(btnOf(container)).toHaveAttribute('aria-label', DARK_LABEL)
    expect(btnOf(container)).toHaveAttribute('title', DARK_LABEL)
  })

  it('toggle-014 light mode: aria-label and title are the light template', () => {
    setDom('light', false)
    const { container } = render(<AppearanceModeToggle />)
    expect(btnOf(container)).toHaveAttribute('aria-label', LIGHT_LABEL)
    expect(btnOf(container)).toHaveAttribute('title', LIGHT_LABEL)
  })

  it('toggle-015 className is merged with the base class', () => {
    const { container } = render(<AppearanceModeToggle className="custom" />)
    const btn = container.querySelector('button') as HTMLButtonElement
    expect(btn).toHaveClass('awt-appearance-mode-toggle', 'custom')
  })

  it('toggle-016 server render with no document does not throw and yields auto/light', () => {
    setDom('dark', true)
    vi.stubGlobal('document', undefined)
    let html = ''
    expect(() => {
      html = renderToString(<AppearanceModeToggle />)
    }).not.toThrow()
    vi.unstubAllGlobals()
    expect(html).toContain('Appearance: Auto (currently light). Click to switch to dark.')
    expect(html).toContain(SUN_PATH)
    expect(html).toContain('awt-appearance-mode-toggle__badge')
  })

  it('toggle-017 the first render reads the live document immediately, not after mount', () => {
    vi.stubGlobal('document', undefined)
    const server = renderToString(<AppearanceModeToggle />)
    vi.unstubAllGlobals()
    setDom('auto', true)
    // renderToString runs no effects, so any value it reflects was read during render itself.
    const live = renderToString(<AppearanceModeToggle />)
    expect(server).toContain('currently light')
    expect(server).toContain(SUN_PATH)
    expect(live).toContain('currently dark')
    expect(live).toContain(MOON_PATH)
    expect(live).not.toContain(SUN_PATH)
  })

  it('toggle-018 click with window undefined returns early without dispatching or throwing', () => {
    const { container } = render(<AppearanceModeToggle />)
    const btn = btnOf(container)
    const propsKey = Object.keys(btn).find((k) => k.startsWith('__reactProps$')) as string
    const onClick = (btn as unknown as Record<string, { onClick: () => void }>)[propsKey].onClick
    const dispatch = vi.spyOn(window, 'dispatchEvent')
    vi.stubGlobal('window', undefined)
    try {
      expect(() => onClick()).not.toThrow()
    } finally {
      vi.unstubAllGlobals()
    }
    expect(dispatch).not.toHaveBeenCalled()
  })

  it('toggle-019 unmount removes the listener; a later event causes no update', () => {
    const add = vi.spyOn(window, 'addEventListener')
    const remove = vi.spyOn(window, 'removeEventListener')
    const err = vi.spyOn(console, 'error').mockImplementation(() => {})
    const { unmount } = render(<AppearanceModeToggle />)
    const added = add.mock.calls.find((c) => c[0] === CHANGED)
    expect(added).toBeDefined()
    unmount()
    expect(remove).toHaveBeenCalledWith(CHANGED, added![1])
    setDom('dark', true)
    expect(() => fireChanged()).not.toThrow()
    expect(err).not.toHaveBeenCalled()
  })

  it('toggle-020 two instances both update on one awt:appearance-changed event', () => {
    setDom('auto', false)
    const a = render(<AppearanceModeToggle />)
    const b = render(<AppearanceModeToggle />)
    setDom('dark', true)
    fireChanged()
    expect(btnOf(a.container)).toHaveAttribute('aria-label', DARK_LABEL)
    expect(btnOf(b.container)).toHaveAttribute('aria-label', DARK_LABEL)
  })

  it('toggle-021 absent data-appearance-mode is treated as auto with the badge', () => {
    setDom(undefined, false)
    const { container } = render(<AppearanceModeToggle />)
    expect(btnOf(container).getAttribute('aria-label')).toMatch(/^Appearance: Auto/)
    expect(container.querySelector('.awt-appearance-mode-toggle__badge')).not.toBeNull()
  })

  it('toggle-022 DOM changes without the changed event leave the label unchanged', () => {
    setDom('auto', false)
    const { container } = render(<AppearanceModeToggle />)
    const before = btnOf(container).getAttribute('aria-label')
    setDom('dark', true)
    expect(btnOf(container).getAttribute('aria-label')).toBe(before)
    fireChanged()
    expect(btnOf(container).getAttribute('aria-label')).not.toBe(before)
  })
})
