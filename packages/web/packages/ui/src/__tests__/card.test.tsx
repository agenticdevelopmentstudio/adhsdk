import { render } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from '../components/card'

const slots = [
  ['Card', Card, 'card'],
  ['CardHeader', CardHeader, 'card-header'],
  ['CardTitle', CardTitle, 'card-title'],
  ['CardDescription', CardDescription, 'card-description'],
  ['CardContent', CardContent, 'card-content'],
  ['CardFooter', CardFooter, 'card-footer'],
] as const

function root(ui: React.ReactElement): HTMLElement {
  const { container } = render(ui)
  return container.firstElementChild as HTMLElement
}

describe('Card family', () => {
  it('card-001 exports six function components', () => {
    for (const [, Component] of slots) expect(typeof Component).toBe('function')
  })
  it('card-002 each component renders a div as its outermost node', () => {
    for (const [, Component] of slots) {
      const el = root(<Component />)
      expect(el.tagName).toBe('DIV')
    }
  })
  it('card-003 each root carries its data-slot value', () => {
    for (const [, Component, slot] of slots) {
      expect(root(<Component />).getAttribute('data-slot')).toBe(slot)
    }
  })
  it('card-004 className merges with the default classes', () => {
    const el = root(<Card className="extra-class" />)
    expect(el.className).toContain('extra-class')
    expect(el.className).toContain('rounded-xl')
  })
  it('card-005 rest props are forwarded to the root div', () => {
    expect(root(<Card data-testid="x" />).getAttribute('data-testid')).toBe('x')
  })
  it('card-006 Card renders with only a CardContent slot', () => {
    const el = root(
      <Card>
        <CardContent>Only content</CardContent>
      </Card>,
    )
    expect(el.children).toHaveLength(1)
    expect(el.firstElementChild?.getAttribute('data-slot')).toBe('card-content')
    expect(el.textContent).toBe('Only content')
  })
  it('card-007 empty Card renders an empty div with default classes', () => {
    const el = root(<Card />)
    expect(el.getAttribute('data-slot')).toBe('card')
    expect(el.childNodes).toHaveLength(0)
    expect(el.className).toContain('rounded-xl')
  })
  it('card-008 Card has rounded-xl', () => {
    expect(root(<Card />).classList.contains('rounded-xl')).toBe(true)
  })
  it('card-009 Card has py-6 and no horizontal padding', () => {
    const el = root(<Card />)
    expect(el.classList.contains('py-6')).toBe(true)
    const horizontal = Array.from(el.classList).filter((c) => /^(p|px|pl|pr|ps|pe)-/.test(c))
    expect(horizontal).toEqual([])
  })
  it('card-010 CardHeader has px-6', () => {
    expect(root(<CardHeader />).classList.contains('px-6')).toBe(true)
  })
  it('card-011 CardContent has px-6', () => {
    expect(root(<CardContent />).classList.contains('px-6')).toBe(true)
  })
  it('card-012 CardFooter has px-6', () => {
    expect(root(<CardFooter />).classList.contains('px-6')).toBe(true)
  })
  it('card-013 Card has gap-6', () => {
    expect(root(<Card />).classList.contains('gap-6')).toBe(true)
  })
  it('card-014 CardHeader has gap-1.5', () => {
    expect(root(<CardHeader />).classList.contains('gap-1.5')).toBe(true)
  })
  it('card-015 CardTitle has font-semibold and leading-none', () => {
    const el = root(<CardTitle />)
    expect(el.classList.contains('font-semibold')).toBe(true)
    expect(el.classList.contains('leading-none')).toBe(true)
  })
  it('card-016 CardDescription has text-sm', () => {
    expect(root(<CardDescription />).classList.contains('text-sm')).toBe(true)
  })
  it('card-017 Card has bg-apt-bg', () => {
    expect(root(<Card />).classList.contains('bg-apt-bg')).toBe(true)
  })
  it('card-018 Card has text-apt-text', () => {
    expect(root(<Card />).classList.contains('text-apt-text')).toBe(true)
  })
  it('card-019 CardTitle has text-apt-text', () => {
    expect(root(<CardTitle />).classList.contains('text-apt-text')).toBe(true)
  })
  it('card-020 CardDescription has text-apt-text-muted', () => {
    expect(root(<CardDescription />).classList.contains('text-apt-text-muted')).toBe(true)
  })
  it('card-021 Card has border and border-apt-border', () => {
    const el = root(<Card />)
    expect(el.classList.contains('border')).toBe(true)
    expect(el.classList.contains('border-apt-border')).toBe(true)
  })
  it('card-022 Card has shadow-sm', () => {
    expect(root(<Card />).classList.contains('shadow-sm')).toBe(true)
  })
  it('card-023 Card is a flex column', () => {
    const el = root(<Card />)
    expect(el.classList.contains('flex')).toBe(true)
    expect(el.classList.contains('flex-col')).toBe(true)
  })
  it('card-024 CardHeader is a flex column', () => {
    const el = root(<CardHeader />)
    expect(el.classList.contains('flex')).toBe(true)
    expect(el.classList.contains('flex-col')).toBe(true)
  })
  it('card-025 CardFooter is a centered flex row', () => {
    const el = root(<CardFooter />)
    expect(el.classList.contains('flex')).toBe(true)
    expect(el.classList.contains('items-center')).toBe(true)
  })
  it('card-026 className p-0 overrides the default py-6', () => {
    const el = root(<Card className="p-0" />)
    expect(el.classList.contains('p-0')).toBe(true)
    expect(el.classList.contains('py-6')).toBe(false)
  })
})
