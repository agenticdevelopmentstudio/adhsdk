import { describe, expect, it } from 'vitest'
import { fireEvent, render } from '@testing-library/react'
import { Faq } from '../index'

describe('Faq conformance vectors', () => {
  it('faq-001 renders one details with the question in its summary and the answer after it', () => {
    const { container } = render(<Faq entries={[{ question: 'Q1', answer: 'A1' }]} />)
    const all = container.querySelectorAll('details')
    expect(all).toHaveLength(1)
    const summaries = all[0].querySelectorAll('summary')
    expect(summaries).toHaveLength(1)
    expect(summaries[0].textContent).toBe('Q1')
    expect(all[0].childNodes).toHaveLength(2)
    expect(all[0].childNodes[0]).toBe(summaries[0])
    expect(all[0].childNodes[1].textContent).toBe('A1')
  })

  it('faq-002 renders an empty container for no entries', () => {
    const { container } = render(<Faq entries={[]} />)
    expect(container.innerHTML).toBe('<div class="lp-faq"></div>')
    expect(container.querySelectorAll('details')).toHaveLength(0)
  })

  it('faq-003 sets the open attribute only on the entry flagged open', () => {
    const { container } = render(
      <Faq entries={[
        { question: 'Q1', answer: 'A1', open: true },
        { question: 'Q2', answer: 'A2', open: false },
      ]} />
    )
    const [first, second] = Array.from(container.querySelectorAll('details'))
    expect(first.hasAttribute('open')).toBe(true)
    expect(second.hasAttribute('open')).toBe(false)
  })

  it('faq-004 accepts element nodes for the question and the answer', () => {
    const { container } = render(
      <Faq entries={[{ question: <h3>Question</h3>, answer: <p>Answer text</p> }]} />
    )
    const details = container.querySelector('details')!
    expect(details.querySelector('summary > h3')!.textContent).toBe('Question')
    expect(details.querySelector(':scope > p')!.textContent).toBe('Answer text')
  })

  it('faq-005 clicking a summary opens its details (native toggle)', () => {
    const { container } = render(
      <Faq entries={[{ question: 'Q1', answer: 'A1' }, { question: 'Q2', answer: 'A2' }]} />
    )
    const first = container.querySelector('details') as HTMLDetailsElement
    expect(first.hasAttribute('open')).toBe(false)
    fireEvent.click(first.querySelector('summary')!)
    expect(first.hasAttribute('open')).toBe(true)
  })

  it.skip('faq-006 print media keeps open entries open (jsdom has no print media emulation)', () => {})

  it('faq-007 the question is in the DOM and a closed answer stays in the DOM inside a closed details', () => {
    const { container, getByText } = render(
      <Faq entries={[{ question: 'What is this?', answer: 'It is a FAQ.' }]} />
    )
    expect(getByText('What is this?').tagName).toBe('SUMMARY')
    const answer = getByText('It is a FAQ.')
    expect(answer.closest('details')!.hasAttribute('open')).toBe(false)
    expect(container.textContent).toContain('It is a FAQ.')
  })

  it('faq-008 a user toggle survives a re-render whose open value is unchanged', () => {
    const { container, rerender } = render(<Faq entries={[{ question: 'Q1', answer: 'A1', open: false }]} />)
    const details = container.querySelector('details') as HTMLDetailsElement
    fireEvent.click(details.querySelector('summary')!)
    expect(details.open).toBe(true)
    rerender(<Faq entries={[{ question: 'Q1', answer: 'A1', open: false }]} />)
    expect(container.querySelector('details')).toBe(details)
    expect(details.open).toBe(true)
  })

  it('faq-009 a changed open prop is written to the element on re-render', () => {
    const { container, rerender } = render(<Faq entries={[{ question: 'Q1', answer: 'A1', open: false }]} />)
    const details = container.querySelector('details') as HTMLDetailsElement
    fireEvent.click(details.querySelector('summary')!)
    expect(details.open).toBe(true)
    rerender(<Faq entries={[{ question: 'Q1', answer: 'A1', open: true }]} />)
    expect(details.open).toBe(true)
    // The other direction: the prop changes to false while the user has it open.
    rerender(<Faq entries={[{ question: 'Q1', answer: 'A1', open: false }]} />)
    expect(details.open).toBe(false)
  })
})
