import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ProfileInfoButton } from './ProfileInfoButton'

const PROFILE = 'https://registry.example/olylo'

// Count how many times the inner render function builds its <a>: it is the
// only element of type 'a' this component creates.
const anchorBuilds = vi.hoisted(() => ({ count: 0 }))
vi.mock('react/jsx-runtime', async (importOriginal) => {
  const real = await importOriginal<typeof import('react/jsx-runtime')>()
  const wrap =
    (fn: (...a: never[]) => unknown) =>
    (type: unknown, ...rest: never[]) => {
      if (type === 'a') anchorBuilds.count += 1
      return fn(type as never, ...rest)
    }
  return { ...real, jsx: wrap(real.jsx as never), jsxs: wrap(real.jsxs as never) }
})
vi.mock('react/jsx-dev-runtime', async (importOriginal) => {
  const real = await importOriginal<typeof import('react/jsx-dev-runtime')>()
  const jsxDEV = real.jsxDEV as unknown as (...a: unknown[]) => unknown
  return {
    ...real,
    jsxDEV: (type: unknown, ...rest: unknown[]) => {
      if (type === 'a') anchorBuilds.count += 1
      return jsxDEV(type, ...rest)
    },
  }
})

const renderButton = (props: { className?: string } = {}) =>
  render(<ProfileInfoButton profileUrl={PROFILE} label="olylo's profile" {...props} />)

describe('ProfileInfoButton', () => {
  it('links to the profile in a new tab with the accessible label', () => {
    render(<ProfileInfoButton profileUrl={PROFILE} label="olylo's profile" />)
    const link = screen.getByRole('link', { name: "olylo's profile" })
    expect(link).toHaveAttribute('href', PROFILE)
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('rel', 'noopener noreferrer')
    expect(link).toHaveAttribute('title', "olylo's profile")
    expect(link).toHaveClass('pc-profile-info')
    expect(link).toHaveTextContent('i')
  })

  it('profile-info-button-001 sets href to profileUrl', () => {
    renderButton()
    expect(screen.getByRole('link')).toHaveAttribute('href', PROFILE)
  })

  it('profile-info-button-002 opens a new tab with opener isolation', () => {
    renderButton()
    const link = screen.getByRole('link')
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('rel', 'noopener noreferrer')
  })

  it('profile-info-button-003 exposes label as accessible name and title', () => {
    renderButton()
    const link = screen.getByRole('link', { name: "olylo's profile" })
    expect(link).toHaveAttribute('title', "olylo's profile")
  })

  it('profile-info-button-004 has root class and glyph text', () => {
    renderButton()
    const link = screen.getByRole('link')
    expect(link).toHaveClass('pc-profile-info')
    expect(link.textContent).toBe('i')
  })

  it('profile-info-button-005 hides the glyph span from assistive technology', () => {
    renderButton()
    const link = screen.getByRole('link')
    expect(link.children).toHaveLength(1)
    expect(link.children[0].tagName).toBe('SPAN')
    expect(link.children[0]).toHaveAttribute('aria-hidden', 'true')
    expect(link.children[0].textContent).toBe('i')
  })

  it('profile-info-button-006 appends className after the root class', () => {
    renderButton({ className: 'host-extra' })
    expect(screen.getByRole('link').getAttribute('class')).toBe('pc-profile-info host-extra')
  })

  it('profile-info-button-007 omits an undefined or empty className with no trailing space', () => {
    const { unmount } = renderButton()
    expect(screen.getByRole('link').getAttribute('class')).toBe('pc-profile-info')
    unmount()
    renderButton({ className: '' })
    expect(screen.getByRole('link').getAttribute('class')).toBe('pc-profile-info')
  })

  it.skip('profile-info-button-008 default placement and size (needs real layout and stylesheet var() resolution)', () => {})
  it.skip('profile-info-button-009 custom size and inset (needs real layout and stylesheet var() resolution)', () => {})
  it.skip('profile-info-button-010 theme token fallbacks (jsdom does not resolve var() fallbacks)', () => {})
  it.skip('profile-info-button-011 hover and focus-visible highlight (jsdom does not apply :hover/:focus-visible styles or color-mix)', () => {})

  it('profile-info-button-012 does not re-render with identical props', () => {
    const props = { profileUrl: PROFILE, label: "olylo's profile", className: 'x' }
    const { rerender } = render(<ProfileInfoButton {...props} />)
    const before = anchorBuilds.count
    rerender(<ProfileInfoButton {...props} />)
    expect(anchorBuilds.count).toBe(before)
    rerender(<ProfileInfoButton {...props} label="other" />)
    expect(anchorBuilds.count).toBe(before + 1)
  })

  it.skip('profile-info-button-013 overflow clipping by .persona-chat (needs real layout and painting)', () => {})

  it('profile-info-button-014 renders an anchor with an empty href for an empty profileUrl', () => {
    const { container } = render(<ProfileInfoButton profileUrl="" label="none" />)
    const a = container.querySelector('a.pc-profile-info')
    expect(a).not.toBeNull()
    expect(a!.getAttribute('href')).toBe('')
  })
})
