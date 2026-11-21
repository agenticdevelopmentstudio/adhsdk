import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import { DescriptionCard } from '../blocks/description-card'

afterEach(cleanup)

describe('DescriptionCard (ui)', () => {
  it('T1: renders the title and a plain-text description without a renderer', () => {
    render(<DescriptionCard title="Plan" description={'line one\nline two'} />)
    expect(screen.getByText('Plan')).toBeInTheDocument()
    const p = screen.getByText(/line one/)
    expect(p.tagName).toBe('P')
    expect(p.className).toContain('whitespace-pre-wrap')
  })

  it('T2: passes the description through renderMarkdown when given', () => {
    render(
      <DescriptionCard
        description="**hi**"
        renderMarkdown={(md) => <div data-testid="md">{md.toUpperCase()}</div>}
      />,
    )
    expect(screen.getByTestId('md')).toHaveTextContent('**HI**')
  })

  it('T3: renders nothing when title and description are both absent or empty', () => {
    const a = render(<DescriptionCard />)
    expect(a.container).toBeEmptyDOMElement()
    const b = render(<DescriptionCard title="" description="" />)
    expect(b.container).toBeEmptyDOMElement()
  })

  it('T4: a title alone omits the content area', () => {
    const { container } = render(<DescriptionCard title="Only title" />)
    expect(container.querySelector('[data-slot="card-content"]')).toBeNull()
  })

  it('T5: a description alone omits the header', () => {
    const { container } = render(<DescriptionCard description="just text" />)
    expect(container.querySelector('[data-slot="card-header"]')).toBeNull()
  })

  it('T6: forwards className and host attributes to the card', () => {
    const { container } = render(
      <DescriptionCard title="t" className="col-span-2" data-testid="dc" />,
    )
    const card = container.querySelector('[data-slot="card"]') as HTMLElement
    expect(card).toHaveClass('col-span-2')
    expect(card).toHaveAttribute('data-testid', 'dc')
  })
})
