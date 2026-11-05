/// <reference types="@testing-library/jest-dom/vitest" />
// Nothing asserted the ThemeStyle component itself before this file, which is how a
// silent render-path deletion (inline <style> during render replaced by a
// document.head side effect returning null) passed every gate: buildScopedCss.test.ts
// covers the CSS transform, not what the component does with the result. These tests
// mock the manifest so the CSS under test is small and legacy-anchor-shaped
// (`:root.dark` / `:root:not(.dark)`), which is what colorMode resolves against — see
// ThemeStyle.tsx's ROOT_DARK_RE / ROOT_NOT_DARK_RE.
import { render } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { ThemeStyle } from '../ThemeStyle'

vi.mock('../manifest', () => ({
  themes: {
    stub: {
      id: 'stub',
      label: 'Stub',
      css: ':root:not(.dark) {\n  --a: 1;\n}\n:root.dark {\n  --a: 2;\n}\n',
    },
  },
}))

describe('ThemeStyle', () => {
  it('renders an unscoped theme inline, in the render container, under GLOBAL_ID', () => {
    const { container } = render(<ThemeStyle theme={'stub' as never} />)
    const style = container.querySelector('style')
    expect(style).not.toBeNull()
    expect(style).toHaveAttribute('id', 'adh-sdk-theme')
    // Not appended to document.head: the pre-merge render path put it in the
    // container the component itself renders into.
    expect(document.head.querySelector('#adh-sdk-theme')).toBeNull()
    expect(style!.innerHTML).toContain('--a: 1')
  })

  it('gives two differently-scoped renders two different ids, so both survive on one page', () => {
    const a = render(<ThemeStyle theme={'stub' as never} scope=".host-a" />)
    const b = render(<ThemeStyle theme={'stub' as never} scope=".host-b" />)
    const idA = a.container.querySelector('style')!.id
    const idB = b.container.querySelector('style')!.id
    expect(idA).not.toBe(idB)
    expect(idA).not.toBe('')
    expect(idB).not.toBe('')
  })

  it('resolves colorMode="dark" and "light" to different CSS from each other', () => {
    const dark = render(<ThemeStyle theme={'stub' as never} scope=".host" colorMode="dark" />)
    const light = render(<ThemeStyle theme={'stub' as never} scope=".host" colorMode="light" />)
    const darkCss = dark.container.querySelector('style')!.innerHTML
    const lightCss = light.container.querySelector('style')!.innerHTML
    expect(darkCss).not.toBe(lightCss)
  })

  it('defaults colorMode to "system", which follows html.dark / html:not(.dark)', () => {
    const { container } = render(<ThemeStyle theme={'stub' as never} scope=".host" />)
    const css = container.querySelector('style')!.innerHTML
    expect(css).toContain('html.dark :scope')
    expect(css).toContain('html:not(.dark) :scope')
  })

  it('renders nothing for an unknown theme key, instead of throwing', () => {
    expect(() => render(<ThemeStyle theme={'not-a-real-theme' as never} />)).not.toThrow()
    const { container } = render(<ThemeStyle theme={'not-a-real-theme' as never} />)
    expect(container.querySelector('style')).toBeNull()
  })
})
