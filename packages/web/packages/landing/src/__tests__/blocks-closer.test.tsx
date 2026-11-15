import { describe, expect, it } from 'vitest'
import { render } from '@testing-library/react'
import { Closer } from '../blocks/Closer'

function root(ui: React.ReactElement): HTMLElement {
  return render(ui).container.firstElementChild as HTMLElement
}

describe('Closer conformance vectors', () => {
  it('closer-001 renders the title inside an h2', () => {
    const el = root(<Closer title="Get Started"><div>form</div></Closer>)
    expect(el.querySelector('h2')!.textContent).toBe('Get Started')
  })

  it('closer-002 renders children after the h2', () => {
    const el = root(<Closer title="Call"><button>Sign Up</button></Closer>)
    const h2 = el.querySelector('h2')!
    const button = el.querySelector('button')!
    expect(h2.nextElementSibling).toBe(button)
    expect(button.textContent).toBe('Sign Up')
  })

  it('closer-003 root div carries lp-closer', () => {
    const el = root(<Closer title="X">{null}</Closer>)
    expect(el.tagName).toBe('DIV')
    expect(el.className).toContain('lp-closer')
  })

  it('closer-004 merges a className after the base class', () => {
    const el = root(<Closer title="X" className="custom-styling"><p>body</p></Closer>)
    expect(el.className).toBe('lp-closer custom-styling')
  })

  it('closer-005 an empty className adds no trailing space', () => {
    const el = root(<Closer title="X" className=""><p>body</p></Closer>)
    expect(el.className).toBe('lp-closer')
  })

  it('closer-006 an undefined className leaves only the base class', () => {
    const el = root(<Closer title="X" className={undefined}><p>body</p></Closer>)
    expect(el.className).toBe('lp-closer')
  })

  it('closer-007 null children render nothing after the h2', () => {
    const el = root(<Closer title="X">{null}</Closer>)
    expect(el.children).toHaveLength(1)
    expect(el.querySelector('h2')!.nextElementSibling).toBeNull()
  })

  it('closer-008 a node title is rendered inside the h2', () => {
    const el = root(<Closer title={<span>Ready?</span>}>{null}</Closer>)
    const span = el.querySelector('h2 > span')!
    expect(span.textContent).toBe('Ready?')
  })

  it('closer-009 the h2 is the first child and the body its next sibling', () => {
    const el = root(<Closer title="Get Started"><p>body</p></Closer>)
    expect(el.firstElementChild!.tagName).toBe('H2')
    expect(el.firstElementChild!.nextElementSibling!.tagName).toBe('P')
  })
})
