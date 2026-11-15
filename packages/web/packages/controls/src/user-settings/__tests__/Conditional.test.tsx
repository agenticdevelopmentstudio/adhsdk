import { describe, it, expect } from 'vitest'
import { useState } from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import { Conditional } from '../components/Conditional'

function Stateful() {
  const [n, setN] = useState(0)
  return <button onClick={() => setN(n + 1)}>count {n}</button>
}

describe('Conditional', () => {
  it('conditional-001 renders children when true', () => {
    const { container } = render(<Conditional when={true} fallback="Goodbye">Hello</Conditional>)
    expect(container.textContent).toBe('Hello')
  })
  it('conditional-002 renders fallback when false', () => {
    const { container } = render(<Conditional when={false} fallback="Goodbye">Hello</Conditional>)
    expect(container.textContent).toBe('Goodbye')
  })
  it('conditional-003 fallback defaults to null', () => {
    const { container } = render(<Conditional when={false}>Hello</Conditional>)
    expect(container.innerHTML).toBe('')
  })
  it('conditional-004 inactive branch of a different type is unmounted and its state discarded', () => {
    const { rerender } = render(<Conditional when={true} fallback={<p>Other</p>}><Stateful /></Conditional>)
    fireEvent.click(screen.getByRole('button'))
    expect(screen.getByRole('button').textContent).toBe('count 1')
    rerender(<Conditional when={false} fallback={<p>Other</p>}><Stateful /></Conditional>)
    expect(screen.getByText('Other')).toBeTruthy()
    expect(screen.queryByRole('button')).toBeNull()
    rerender(<Conditional when={true} fallback={<p>Other</p>}><Stateful /></Conditional>)
    expect(screen.getByRole('button').textContent).toBe('count 0')
  })
  it('conditional-005 adds no wrapper element', () => {
    const { container } = render(
      <Conditional when={true}>{[<span key="a">A</span>, <span key="b">B</span>]}</Conditional>,
    )
    expect(container.children).toHaveLength(2)
    expect(container.innerHTML).toBe('<span>A</span><span>B</span>')
  })
  it('conditional-006 null children render nothing', () => {
    const { container } = render(<Conditional when={true}>{null}</Conditional>)
    expect(container.innerHTML).toBe('')
  })
  it('conditional-007 falsy numeric children render the value', () => {
    const { container } = render(<Conditional when={true}>{0}</Conditional>)
    expect(container.textContent).toBe('0')
  })
  it('conditional-008 mixed children render in order', () => {
    const { container } = render(
      <Conditional when={true}>{['A', <span key="b">B</span>, <>C</>]}</Conditional>,
    )
    expect(container.innerHTML).toBe('A<span>B</span>C')
  })
  it('conditional-009 same-type branches update in place and state survives', () => {
    const { rerender } = render(<Conditional when={true} fallback={<Stateful />}><Stateful /></Conditional>)
    fireEvent.click(screen.getByRole('button'))
    expect(screen.getByRole('button').textContent).toBe('count 1')
    rerender(<Conditional when={false} fallback={<Stateful />}><Stateful /></Conditional>)
    expect(screen.getByRole('button').textContent).toBe('count 1')
  })
})
