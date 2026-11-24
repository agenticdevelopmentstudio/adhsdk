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
import { ThemeStyle, buildScopedCss } from '../ThemeStyle'

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
  it('theme-style-001 renders an unscoped theme inline, in the render container, under GLOBAL_ID', () => {
    const { container } = render(<ThemeStyle theme={'stub' as never} />)
    const style = container.querySelector('style')
    expect(style).not.toBeNull()
    expect(style).toHaveAttribute('id', 'adh-sdk-theme')
    // Not appended to document.head: the pre-merge render path put it in the
    // container the component itself renders into.
    expect(document.head.querySelector('#adh-sdk-theme')).toBeNull()
    expect(style!.innerHTML).toContain('--a: 1')
  })

  it('theme-style-002 gives two differently-scoped renders two different ids, so both survive on one page', () => {
    const a = render(<ThemeStyle theme={'stub' as never} scope=".host-a" />)
    const b = render(<ThemeStyle theme={'stub' as never} scope=".host-b" />)
    const idA = a.container.querySelector('style')!.id
    const idB = b.container.querySelector('style')!.id
    expect(idA).not.toBe(idB)
    expect(idA).not.toBe('')
    expect(idB).not.toBe('')
  })

  it('theme-style-017 keeps scopes that differ only in punctuation or case on different ids', () => {
    const ids = ['.host-a', '#host-a', '.Host-A', 'host-a'].map(
      (scope) => render(<ThemeStyle theme={'stub' as never} scope={scope} />).container.querySelector('style')!.id,
    )
    expect(new Set(ids).size).toBe(4)
    // A scope that is already its own slug keeps the plain, readable id.
    expect(ids[3]).toBe('adh-sdk-theme-scoped-host-a')
  })

  it('theme-style-003 resolves colorMode="dark" and "light" to different CSS from each other', () => {
    const dark = render(<ThemeStyle theme={'stub' as never} scope=".host" colorMode="dark" />)
    const light = render(<ThemeStyle theme={'stub' as never} scope=".host" colorMode="light" />)
    const darkCss = dark.container.querySelector('style')!.innerHTML
    const lightCss = light.container.querySelector('style')!.innerHTML
    expect(darkCss).not.toBe(lightCss)
  })

  it('theme-style-004 defaults colorMode to "system", which follows html.dark / html:not(.dark)', () => {
    const { container } = render(<ThemeStyle theme={'stub' as never} scope=".host" />)
    const css = container.querySelector('style')!.innerHTML
    expect(css).toContain('html.dark :scope')
    expect(css).toContain('html:not(.dark) :scope')
  })

  it('theme-style-005 renders nothing for an unknown theme key, instead of throwing', () => {
    expect(() => render(<ThemeStyle theme={'not-a-real-theme' as never} />)).not.toThrow()
    const { container } = render(<ThemeStyle theme={'not-a-real-theme' as never} />)
    expect(container.querySelector('style')).toBeNull()
  })

  it('theme-style-015 a scope that is not its own slug gets the slug plus an FNV-1a hash suffix', () => {
    const { container } = render(<ThemeStyle theme={'stub' as never} scope="Host B > .x" />)
    expect(container.querySelector('style')!.id).toBe('adh-sdk-theme-scoped-host-b-x-g3a3in')
  })

  it('theme-style-016 colorMode has no effect without a scope: the body equals the stub CSS', () => {
    const { container } = render(<ThemeStyle theme={'stub' as never} colorMode="dark" />)
    expect(container.querySelector('style')!.innerHTML).toBe(
      ':root:not(.dark) {\n  --a: 1;\n}\n:root.dark {\n  --a: 2;\n}\n',
    )
  })

  it('theme-style-017b hashed ids for punctuation variants are the documented ones', () => {
    const idOf = (scope: string): string =>
      render(<ThemeStyle theme={'stub' as never} scope={scope} />).container.querySelector('style')!.id
    expect(idOf('host-a')).toBe('adh-sdk-theme-scoped-host-a')
    expect(idOf('.host-a')).toBe('adh-sdk-theme-scoped-host-a-5l1jl5')
    expect(idOf('#host-a')).toBe('adh-sdk-theme-scoped-host-a-lcrp5y')
  })

  it('theme-style-022 re-rendering with a different scope swaps the style body and id', () => {
    const css = ':root:not(.dark) {\n  --a: 1;\n}\n:root.dark {\n  --a: 2;\n}\n'
    const { container, rerender } = render(<ThemeStyle theme={'stub' as never} scope=".a" />)
    const idA = container.querySelector('style')!.id
    expect(container.querySelector('style')!.innerHTML).toBe(buildScopedCss(css, '.a'))
    rerender(<ThemeStyle theme={'stub' as never} scope=".b" />)
    const style = container.querySelector('style')!
    expect(style.innerHTML).toBe(buildScopedCss(css, '.b'))
    expect(style.id).toContain('adh-sdk-theme-scoped-b')
    expect(style.id).not.toBe(idA)
  })
})
