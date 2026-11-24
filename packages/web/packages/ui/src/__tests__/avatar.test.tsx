/**
 * Conformance tests for Avatar / AvatarImage / AvatarFallback — the Base UI avatar wrapped
 * in stable `adh-avatar*` classes. One `it` per vector in
 * cookbook/ui/components/display/avatar/conformance-test-vectors.md.
 *
 * Base UI's Avatar.Image creates `new window.Image()` and renders only once that object
 * fires onload (jsdom never loads images), so image vectors mock window.Image.
 */
import { render, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach, vi } from 'vitest'
import { Avatar, AvatarImage, AvatarFallback } from '../components/avatar'

const SRC = 'https://example.test/ada.png'
const RealImage = window.Image

function mockImage(outcome: 'load' | 'error'): void {
  class FakeImage {
    onload: (() => void) | null = null
    onerror: (() => void) | null = null
    referrerPolicy = ''
    crossOrigin: string | null = null
    private _src = ''
    get src(): string {
      return this._src
    }
    set src(value: string) {
      this._src = value
      queueMicrotask(() => (outcome === 'load' ? this.onload : this.onerror)?.())
    }
  }
  window.Image = FakeImage as unknown as typeof window.Image
}

afterEach(() => {
  cleanup()
  window.Image = RealImage
})

describe('Avatar conformance vectors', () => {
  it('avatar-001: Avatar root carries adh-avatar', () => {
    const { container } = render(<Avatar />)
    expect(container.firstElementChild).toHaveClass('adh-avatar')
  })

  it('avatar-002: AvatarImage carries adh-avatar__image', async () => {
    mockImage('load')
    const { findByRole } = render(
      <Avatar>
        <AvatarImage src={SRC} alt="Ada" />
      </Avatar>,
    )
    expect(await findByRole('img')).toHaveClass('adh-avatar__image')
  })

  it('avatar-003: AvatarFallback carries adh-avatar__fallback', () => {
    const { getByText } = render(
      <Avatar>
        <AvatarFallback>AL</AvatarFallback>
      </Avatar>,
    )
    expect(getByText('AL')).toHaveClass('adh-avatar__fallback')
  })

  it('avatar-004: Avatar merges a consumer className', () => {
    const { container } = render(<Avatar className="ring-2" />)
    expect(container.firstElementChild).toHaveClass('adh-avatar', 'ring-2')
  })

  it('avatar-005: AvatarImage merges a consumer className', async () => {
    mockImage('load')
    const { findByRole } = render(
      <Avatar>
        <AvatarImage className="opacity-0" src={SRC} alt="Ada" />
      </Avatar>,
    )
    expect(await findByRole('img')).toHaveClass('adh-avatar__image', 'opacity-0')
  })

  it('avatar-006: AvatarFallback merges a consumer className', () => {
    const { getByText } = render(
      <Avatar>
        <AvatarFallback className="bg-muted">AL</AvatarFallback>
      </Avatar>,
    )
    expect(getByText('AL')).toHaveClass('adh-avatar__fallback', 'bg-muted')
  })

  it('avatar-007: Avatar forwards other props (data-testid)', () => {
    const { getByTestId } = render(<Avatar data-testid="a1" />)
    expect(getByTestId('a1')).toHaveClass('adh-avatar')
  })

  it('avatar-008: AvatarImage forwards other props (alt)', async () => {
    mockImage('load')
    const { findByRole } = render(
      <Avatar>
        <AvatarImage alt="Ada Lovelace" src={SRC} />
      </Avatar>,
    )
    expect(await findByRole('img')).toHaveAttribute('alt', 'Ada Lovelace')
  })

  it('avatar-009: AvatarFallback forwards other props and its children', () => {
    const { getByTestId } = render(
      <Avatar>
        <AvatarFallback data-testid="f1">AL</AvatarFallback>
      </Avatar>,
    )
    const fb = getByTestId('f1')
    expect(fb).toHaveClass('adh-avatar__fallback')
    expect(fb).toHaveTextContent('AL')
  })

  it('avatar-010: an undefined className adds no "undefined" class', () => {
    const { container } = render(<Avatar className={undefined} />)
    const root = container.firstElementChild as HTMLElement
    expect(root).toHaveClass('adh-avatar')
    expect(root.className).not.toContain('undefined')
  })

  it('avatar-011: AvatarImage outside Avatar throws', () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() => render(<AvatarImage src={SRC} />)).toThrow()
    error.mockRestore()
  })

  it('avatar-012: a failed image load leaves only the fallback', async () => {
    mockImage('error')
    const { findByText, container } = render(
      <Avatar>
        <AvatarImage src={SRC} />
        <AvatarFallback>AL</AvatarFallback>
      </Avatar>,
    )
    const fb = await findByText('AL')
    expect(fb).toHaveClass('adh-avatar__fallback')
    expect(container.querySelector('.adh-avatar__image')).toBeNull()
  })
})
