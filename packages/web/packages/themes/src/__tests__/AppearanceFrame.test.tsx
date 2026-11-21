// <AppearanceFrame/> is what a route that wears none of the appearance prefs renders (the site
// template's frame does), so a document loaded straight onto it keeps <html> bare when the first
// commit lands. A file of its own for the reason AppearanceScope.test.tsx gives: the store's
// scoping is module state.
import { render } from '@testing-library/react'
import { describe, expect, it } from 'vitest'

import { AppearanceFrame, AppearanceScope, resetAppearance } from '../appearance-store'

describe('<AppearanceFrame/>', () => {
  it('AS-009: a commit after the frame mounts leaves <html> alone, and a scope still paints', () => {
    const html = document.documentElement
    render(<AppearanceFrame />)
    resetAppearance()
    expect(html.hasAttribute('data-color-mode')).toBe(false)

    const scope = render(<AppearanceScope />)
    expect(html.dataset.colorMode).toBe('auto')
    scope.unmount()
    expect(html.hasAttribute('data-color-mode')).toBe(false)
  })
})
