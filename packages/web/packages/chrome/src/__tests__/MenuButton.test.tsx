import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import type { ReactElement } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { act } from 'react'
import { createRoot, type Root } from 'react-dom/client'
import { MenuButton } from '../MenuButton'

const BASE_CSS = readFileSync(join(dirname(fileURLToPath(import.meta.url)), '../css/base.css'), 'utf8')

function injectCss(): HTMLStyleElement {
  const style = document.createElement('style')
  style.textContent = BASE_CSS
  document.head.appendChild(style)
  return style
}

;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true

// The chrome package declares no @testing-library dependency, so render with react-dom directly.
const mounted: Array<{ root: Root; container: HTMLElement }> = []

function render(ui: ReactElement): { container: HTMLElement; rerender: (next: ReactElement) => void } {
  const container = document.createElement('div')
  document.body.appendChild(container)
  const root = createRoot(container)
  mounted.push({ root, container })
  act(() => root.render(ui))
  return { container, rerender: (next) => act(() => root.render(next)) }
}

function cleanup(): void {
  for (const { root, container } of mounted.splice(0)) {
    act(() => root.unmount())
    container.remove()
  }
}

const fireEvent = {
  click(el: Element): void {
    act(() => {
      el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
    })
  },
}

function button(container: HTMLElement): HTMLButtonElement {
  return container.querySelector('button') as HTMLButtonElement
}

afterEach(() => {
  cleanup()
  document.head.querySelectorAll('style').forEach((s) => s.remove())
})

describe('MenuButton', () => {
  it('menu-button-001: renders a button element with type="button"', () => {
    const { container } = render(<MenuButton label="Menu" />)
    expect(button(container)).not.toBeNull()
    expect(button(container).getAttribute('type')).toBe('button')
  })

  it('menu-button-002: label becomes aria-label', () => {
    const { container } = render(<MenuButton label="Menu" />)
    expect(button(container).getAttribute('aria-label')).toBe('Menu')
  })

  it('menu-button-003: default icon renders three bars', () => {
    const { container } = render(<MenuButton label="Menu" />)
    expect(container.querySelectorAll('span.mb-bar')).toHaveLength(3)
  })

  it('menu-button-004: icon="close" renders two bars', () => {
    const { container } = render(<MenuButton label="Close" icon="close" />)
    expect(container.querySelectorAll('span.mb-bar')).toHaveLength(2)
  })

  it('menu-button-005: default render has class menu-button', () => {
    const { container } = render(<MenuButton label="Menu" />)
    expect(button(container)).toHaveClass('menu-button')
  })

  it('menu-button-006: close icon adds menu-button--close', () => {
    const { container } = render(<MenuButton label="Close" icon="close" />)
    expect(button(container)).toHaveClass('menu-button', 'menu-button--close')
  })

  it('menu-button-007: className is included in the class list', () => {
    const { container } = render(<MenuButton label="Menu" className="custom-class" />)
    expect(button(container)).toHaveClass('custom-class')
  })

  it('menu-button-008: onClick is invoked on click', () => {
    const handler = vi.fn()
    const { container } = render(<MenuButton label="Menu" onClick={handler} />)
    fireEvent.click(button(container))
    expect(handler).toHaveBeenCalledTimes(1)
  })

  it('menu-button-009: disabled button has the attribute and does not invoke onClick', () => {
    const handler = vi.fn()
    const { container } = render(<MenuButton label="Menu" disabled onClick={handler} />)
    expect(button(container)).toHaveAttribute('disabled')
    fireEvent.click(button(container))
    expect(handler).not.toHaveBeenCalled()
  })

  it('menu-button-010: toggling icon from menu to close changes bars and adds the close class', () => {
    const { container, rerender } = render(<MenuButton label="Menu" icon="menu" />)
    expect(container.querySelectorAll('.mb-bar')).toHaveLength(3)
    expect(button(container)).not.toHaveClass('menu-button--close')
    rerender(<MenuButton label="Menu" icon="close" />)
    expect(container.querySelectorAll('.mb-bar')).toHaveLength(2)
    expect(button(container)).toHaveClass('menu-button--close')
  })

  it('menu-button-011: bars are SPAN elements and no svg is present', () => {
    const { container } = render(<MenuButton label="Menu" />)
    const bars = Array.from(container.querySelectorAll('.mb-bar'))
    expect(bars.length).toBeGreaterThan(0)
    bars.forEach((bar) => expect(bar.tagName).toBe('SPAN'))
    expect(container.querySelector('svg')).toBeNull()
  })

  it('menu-button-012: explicit icon="menu" renders three bars like the default', () => {
    const { container } = render(<MenuButton label="Menu" icon="menu" />)
    expect(container.querySelectorAll('span.mb-bar')).toHaveLength(3)
  })

  it('menu-button-014: class attribute is exactly menu-button without className', () => {
    const { container } = render(<MenuButton label="Menu" />)
    expect(button(container).getAttribute('class')).toBe('menu-button')
  })

  it('menu-button-015: menu-button is position relative and the ::after hit area is 44px', () => {
    injectCss()
    const { container } = render(<MenuButton label="Menu" />)
    const btn = button(container)
    expect(getComputedStyle(btn).position).toBe('relative')
    // jsdom has no layout and does not compute pseudo-element size, so read the ::after rule
    // and the custom property it resolves through.
    const rules = Array.from(document.styleSheets).flatMap((sheet) => Array.from(sheet.cssRules)) as CSSStyleRule[]
    const after = rules.find((r) => r.selectorText === '.menu-button::after')
    expect(after?.style.getPropertyValue('width')).toBe('var(--menu-hit)')
    expect(after?.style.getPropertyValue('height')).toBe('var(--menu-hit)')
    expect(getComputedStyle(btn).getPropertyValue('--menu-hit').trim()).toBe('44px')
  })

  it('menu-button-016: no aria-label attribute when label is omitted', () => {
    const { container } = render(
      // @ts-expect-error label is required; omitted on purpose to bypass the type system
      <MenuButton />,
    )
    expect(button(container).hasAttribute('aria-label')).toBe(false)
  })

  it('menu-button-017: label="" renders an empty aria-label', () => {
    const { container } = render(<MenuButton label="" />)
    expect(button(container).getAttribute('aria-label')).toBe('')
  })

  it('menu-button-018: close icon with className gives the exact class attribute', () => {
    const { container } = render(<MenuButton label="Close" icon="close" className="custom-class" />)
    expect(button(container).getAttribute('class')).toBe('menu-button menu-button--close custom-class')
  })

  // jsdom has no layout and leaves var() unresolved in width/height, so geometry vectors assert the
  // declared var() reference together with the custom property value it resolves to.
  it('menu-button-019: bars are 16px wide, 1px thick, with a 999px radius', () => {
    injectCss()
    const { container } = render(<MenuButton label="Menu" />)
    const btn = button(container)
    const bars = Array.from(container.querySelectorAll('.mb-bar'))
    expect(bars).toHaveLength(3)
    for (const bar of bars) {
      const cs = getComputedStyle(bar)
      expect(cs.width).toBe('var(--menu-bar-width)')
      expect(cs.height).toBe('var(--menu-bar-thickness)')
      expect(cs.borderRadius).toBe('999px')
    }
    const btnStyle = getComputedStyle(btn)
    expect(btnStyle.getPropertyValue('--menu-bar-width').trim()).toBe('16px')
    expect(btnStyle.getPropertyValue('--menu-bar-thickness').trim()).toBe('1px')
  })

  it('menu-button-020: button is 32x32 with a 4px row gap', () => {
    injectCss()
    const { container } = render(<MenuButton label="Menu" />)
    const btn = button(container)
    const cs = getComputedStyle(btn)
    expect(cs.width).toBe('var(--menu-size)')
    expect(cs.height).toBe('var(--menu-size)')
    expect(cs.getPropertyValue('--menu-size').trim()).toBe('32px')
    // jsdom does not expand the `gap` shorthand into row-gap.
    expect(cs.getPropertyValue('gap')).toBe('var(--menu-bar-gap)')
    expect(cs.getPropertyValue('--menu-bar-gap').trim()).toBe('4px')
  })

  it('menu-button-021: bars take the button color through currentColor', () => {
    injectCss()
    const { container } = render(<MenuButton label="Menu" />)
    button(container).style.color = 'rgb(255, 0, 0)'
    container.querySelectorAll('.mb-bar').forEach((bar) => {
      expect(getComputedStyle(bar).backgroundColor).toBe('rgb(255, 0, 0)')
    })
  })

  it('menu-button-022: bars declare transition 0.25s', () => {
    injectCss()
    const { container } = render(<MenuButton label="Menu" />)
    // jsdom does not expand the transition shorthand into transition-duration, so assert the shorthand.
    expect(getComputedStyle(container.querySelector('.mb-bar') as Element).getPropertyValue('transition')).toBe('0.25s')
  })

  it('menu-button-023: close bars share grid cell 1 / 1 and rotate +45deg and -45deg', () => {
    injectCss()
    const { container } = render(<MenuButton label="Close" icon="close" />)
    const bars = Array.from(container.querySelectorAll('.mb-bar'))
    expect(bars).toHaveLength(2)
    bars.forEach((bar) => expect(getComputedStyle(bar).getPropertyValue('grid-area')).toBe('1 / 1'))
    expect(getComputedStyle(bars[0]).transform).toBe('rotate(45deg)')
    expect(getComputedStyle(bars[1]).transform).toBe('rotate(-45deg)')
  })
})
