import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { VStack, HStack } from '../components/Stack'

function root(container: HTMLElement): HTMLElement {
  return container.firstElementChild as HTMLElement
}

describe('Stack conformance vectors', () => {
  it('stack-001 renders both children', () => {
    const { container } = render(<VStack><div>one</div><div>two</div></VStack>)
    expect(root(container).children).toHaveLength(2)
    expect(root(container).textContent).toBe('onetwo')
  })

  it('stack-002 numeric gap becomes px', () => {
    const { container } = render(<VStack gap={16} />)
    expect(root(container).style.gap).toBe('16px')
  })

  it('stack-003 string gap passes through', () => {
    const { container } = render(<VStack gap="1rem" />)
    expect(root(container).style.gap).toBe('1rem')
  })

  it('stack-004 gap omitted when unset', () => {
    const { container } = render(<VStack />)
    expect(root(container).style.gap).toBe('')
    expect(root(container).getAttribute('style') ?? '').not.toContain('gap')
  })

  it('stack-005 HStack align maps to alignItems', () => {
    const { container } = render(<HStack align="center" />)
    expect(root(container).style.alignItems).toBe('center')
  })

  it('stack-006 VStack justify maps to justifyContent', () => {
    const { container } = render(<VStack justify="space-between" />)
    expect(root(container).style.justifyContent).toBe('space-between')
  })

  it('stack-007 inline styles are merged', () => {
    const { container } = render(<VStack gap={4} style={{ padding: '10px' }} />)
    expect(root(container).style.padding).toBe('10px')
    expect(root(container).style.gap).toBe('4px')
  })

  it('stack-008 VStack class names', () => {
    const { container } = render(<VStack className="custom" />)
    expect(root(container).className).toBe('aws-stack aws-stack--v custom')
  })

  it('stack-009 HStack class names', () => {
    const { container } = render(<HStack className="custom" />)
    expect(root(container).className).toBe('aws-stack aws-stack--h custom')
  })

  it('stack-010 root is a plain div with no role', () => {
    for (const el of [<VStack key="v" />, <HStack key="h" />]) {
      const { container, unmount } = render(el)
      expect(root(container).tagName).toBe('DIV')
      expect(root(container).hasAttribute('role')).toBe(false)
      unmount()
    }
  })

  it('stack-011 undefined children render no child nodes', () => {
    const { container } = render(<VStack children={undefined} />)
    expect(root(container).className).toBe('aws-stack aws-stack--v')
    expect(root(container).childNodes).toHaveLength(0)
  })

  it('stack-012 empty array children render no child nodes', () => {
    const { container } = render(<VStack children={[]} />)
    expect(root(container).className).toBe('aws-stack aws-stack--v')
    expect(root(container).childNodes).toHaveLength(0)
  })

  it('stack-013 gap 0 becomes 0px', () => {
    const { container } = render(<VStack gap={0} />)
    expect(root(container).style.gap).toBe('0px')
  })

  it('stack-014 gap "0" passes through (CSSOM serializes it as 0px)', () => {
    const { container } = render(<VStack gap="0" />)
    expect(root(container).style.gap).toBe('0px')
  })

  it('stack-015 style prop overrides gap and alignItems', () => {
    const { container } = render(
      <VStack gap={8} align="center" style={{ gap: '2rem', alignItems: 'flex-start' }} />,
    )
    expect(root(container).style.gap).toBe('2rem')
    expect(root(container).style.alignItems).toBe('flex-start')
  })

  it('stack-016 empty className adds no extra tokens', () => {
    const { container } = render(<VStack className="" />)
    expect(root(container).getAttribute('class')).toBe('aws-stack aws-stack--v')
  })

  it('stack-017 unsupported props are not forwarded', () => {
    const props = { id: 'x' } as any
    const { container } = render(<VStack {...props} />)
    expect(root(container).hasAttribute('id')).toBe(false)
  })

  it('stack-018 null children render no child nodes', () => {
    const { container } = render(<VStack children={null} />)
    expect(root(container).className).toBe('aws-stack aws-stack--v')
    expect(root(container).childNodes).toHaveLength(0)
  })
})
