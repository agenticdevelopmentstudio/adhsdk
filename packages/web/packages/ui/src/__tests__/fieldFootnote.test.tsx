/** `FieldFootnote` conformance vectors (field-footnote-001 .. field-footnote-012). */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach } from 'vitest'

import { FieldFootnote } from '../components/field-footnote'

afterEach(cleanup)

describe('FieldFootnote', () => {
  it('field-footnote-001 error-shown: renders the error with error colour, mono caption size, no id', () => {
    const { container } = render(<FieldFootnote error="This field is required" hint={undefined} />)
    expect(container.children).toHaveLength(1)
    const el = container.firstElementChild as HTMLElement
    expect(el).toHaveTextContent('This field is required')
    expect(el).toHaveClass('text-apt-red', 'font-mono', 'text-[0.7rem]')
    expect(el).not.toHaveAttribute('id')
  })

  it('field-footnote-002 error-takes-precedence: hint is absent when an error is set', () => {
    const { container } = render(<FieldFootnote error="Error occurred" hint="Hint text" />)
    expect(container).toHaveTextContent('Error occurred')
    expect(container).not.toHaveTextContent('Hint text')
  })

  it('field-footnote-003 hint-shown-without-error: renders the hint with secondary colour, mono caption size, no id', () => {
    const { container } = render(<FieldFootnote error={undefined} hint="Type at least 8 characters" />)
    expect(container.children).toHaveLength(1)
    const el = container.firstElementChild as HTMLElement
    expect(el).toHaveTextContent('Type at least 8 characters')
    expect(el).toHaveClass('text-apt-text-dim', 'font-mono', 'text-[0.7rem]')
    expect(el).not.toHaveAttribute('id')
  })

  it('field-footnote-004 renders-nothing-when-empty: renders nothing without error or hint', () => {
    const { container } = render(<FieldFootnote error={undefined} hint={undefined} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('field-footnote-005 error-id-applied: errorId lands on the error element', () => {
    const { container } = render(<FieldFootnote error="Error" errorId="email-error" />)
    expect(container.firstElementChild).toHaveAttribute('id', 'email-error')
  })

  it('field-footnote-006 error-id-only-on-error: the hint never gets the id', () => {
    const { container } = render(<FieldFootnote hint="Hint" errorId="some-id" />)
    expect(container.firstElementChild).toHaveTextContent('Hint')
    expect(container.firstElementChild).not.toHaveAttribute('id')
  })

  it('field-footnote-007 caller-class-name-merged: custom class sits alongside the defaults', () => {
    const { container } = render(<FieldFootnote error="Error" className="custom-class" />)
    expect(container.firstElementChild).toHaveClass('custom-class', 'font-mono', 'text-[0.7rem]', 'text-apt-red')
  })

  it('field-footnote-008 supports-rich-content: renders a ReactNode error as children', () => {
    const { container } = render(<FieldFootnote error={<strong>Bold error</strong>} />)
    const strong = container.firstElementChild?.querySelector('strong')
    expect(strong).toHaveTextContent('Bold error')
  })

  it('field-footnote-009 caller-class-name-merged: caller colour wins over the default error colour', () => {
    const { container } = render(<FieldFootnote error="Error" className="text-blue-500" />)
    expect(container.firstElementChild).toHaveClass('text-blue-500')
    expect(container.firstElementChild).not.toHaveClass('text-apt-red')
  })

  it('field-footnote-010 supports-rich-content: an empty-string error falls back to the hint', () => {
    const { container } = render(<FieldFootnote error="" hint="Hint" />)
    expect(container).toHaveTextContent('Hint')
    expect(container.firstElementChild).toHaveClass('text-apt-text-dim')
  })

  it('field-footnote-011 renders-nothing-when-empty: error={0} renders nothing', () => {
    const { container } = render(<FieldFootnote error={0} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('field-footnote-012 renders-nothing-when-empty: hint="" alone renders nothing', () => {
    const { container } = render(<FieldFootnote hint="" />)
    expect(container).toBeEmptyDOMElement()
  })
})
