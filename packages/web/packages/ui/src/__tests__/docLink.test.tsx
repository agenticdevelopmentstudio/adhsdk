/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, cleanup, fireEvent } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { DefaultDocLink } from '../blocks/doc-link'
import type { DocLinkComponent } from '../blocks/doc-types'

afterEach(cleanup)

describe('DefaultDocLink conformance vectors', () => {
  it('doc-link-001 renders as an anchor with the given href', () => {
    const { container } = render(<DefaultDocLink to="/docs">Link</DefaultDocLink>)
    expect(container.innerHTML).toBe('<a href="/docs">Link</a>')
  })

  it('doc-link-002 passes to into href', () => {
    render(<DefaultDocLink to="/about">About</DefaultDocLink>)
    expect(screen.getByRole('link')).toHaveAttribute('href', '/about')
  })

  it('doc-link-003 renders children as the link text', () => {
    render(<DefaultDocLink to="/">Home</DefaultDocLink>)
    expect(screen.getByRole('link').textContent).toBe('Home')
  })

  it('doc-link-004 renders text plus JSX children inside the anchor', () => {
    render(
      <DefaultDocLink to="/">
        Go <strong data-testid="b">now</strong>
      </DefaultDocLink>,
    )
    const a = screen.getByRole('link')
    expect(a).toContainElement(screen.getByTestId('b'))
    expect(a.textContent).toBe('Go now')
  })

  it('doc-link-005 spreads className and data attributes onto the anchor', () => {
    render(
      <DefaultDocLink to="/" className="nav-link" data-testid="home-link">
        Home
      </DefaultDocLink>,
    )
    const a = screen.getByTestId('home-link')
    expect(a.tagName).toBe('A')
    expect(a).toHaveClass('nav-link')
  })

  it('doc-link-006 passes onClick through', () => {
    const handler = vi.fn()
    render(
      <DefaultDocLink to="/" onClick={handler}>
        Go
      </DefaultDocLink>,
    )
    fireEvent.click(screen.getByRole('link'))
    expect(handler).toHaveBeenCalledTimes(1)
  })

  it('doc-link-007 to and children combine into one anchor', () => {
    const { container } = render(<DefaultDocLink to="/docs">Read Docs</DefaultDocLink>)
    expect(container.innerHTML).toBe('<a href="/docs">Read Docs</a>')
  })

  it('doc-link-008 an empty to renders an empty href', () => {
    const { container } = render(<DefaultDocLink to="">Link</DefaultDocLink>)
    const a = container.querySelector('a')!
    expect(a.getAttribute('href')).toBe('')
    expect(a.textContent).toBe('Link')
  })

  it('doc-link-009 an undefined to omits href entirely', () => {
    const { container } = render(<DefaultDocLink to={undefined as unknown as string}>Link</DefaultDocLink>)
    const a = container.querySelector('a')!
    expect(a.hasAttribute('href')).toBe(false)
    expect(screen.queryByRole('link')).toBeNull()
  })

  it('doc-link-010 null children leave an anchor with no text and no accessible name', () => {
    const { container } = render(<DefaultDocLink to="/x">{null}</DefaultDocLink>)
    const a = container.querySelector('a')!
    expect(a.textContent).toBe('')
    expect(a.hasAttribute('aria-label')).toBe(false)
    expect(screen.getByRole('link', { name: '' })).toBe(a)
  })

  it('doc-link-011 the component does not validate schemes; React alone blocks javascript:', () => {
    const { unmount } = render(<DefaultDocLink to="mailto:a@b.c">x</DefaultDocLink>)
    expect(screen.getByText('x')).toHaveAttribute('href', 'mailto:a@b.c')
    unmount()
    const err = vi.spyOn(console, 'error').mockImplementation(() => {})
    render(<DefaultDocLink to="javascript:alert(1)">y</DefaultDocLink>)
    const href = screen.getByText('y').getAttribute('href')!
    expect(href).not.toBe('javascript:alert(1)')
    expect(href).toContain('React has blocked a javascript: URL')
    err.mockRestore()
  })

  it('doc-link-012 a spread href wins over to', () => {
    const extra = { href: '/other' } as unknown as Record<string, string>
    render(
      <DefaultDocLink to="/docs" {...extra}>
        x
      </DefaultDocLink>,
    )
    expect(screen.getByRole('link')).toHaveAttribute('href', '/other')
  })

  it('doc-link-013 is assignable to DocLinkComponent and renders through that type', () => {
    // Compile-time: this assignment fails `tsc` if the structural contract breaks.
    const Link: DocLinkComponent = DefaultDocLink
    render(<Link to="/docs">Docs</Link>)
    expect(screen.getByRole('link')).toHaveAttribute('href', '/docs')
  })
})
