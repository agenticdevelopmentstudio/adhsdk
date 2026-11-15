/** Conformance vectors for the Textarea recipe (cookbook/ui/components/inputs/textarea).
 *  jsdom does not run Tailwind, so style vectors assert the utility classes the
 *  component applies, which is the contract the source actually carries. */
/// <reference types="@testing-library/jest-dom/vitest" />
import * as React from 'react'
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { Textarea } from '../components/textarea'
import { noAutofillProps } from '../lib/autofill'

const OPT_OUT_ATTRS = Object.entries(noAutofillProps).map(
  ([key, value]) => [key === 'autoComplete' ? 'autocomplete' : key, value] as const,
)
const VENDOR_ATTRS = ['data-form-type', 'data-1p-ignore', 'data-lpignore', 'data-bwignore', 'data-protonpass-ignore']

function field(props: React.ComponentProps<typeof Textarea> = {}): HTMLTextAreaElement {
  render(<Textarea aria-label="Body" {...props} />)
  return screen.getByLabelText('Body') as HTMLTextAreaElement
}

function expectOptOut(el: HTMLElement): void {
  expect(OPT_OUT_ATTRS).toHaveLength(6)
  for (const [attr, value] of OPT_OUT_ATTRS) expect(el).toHaveAttribute(attr, value)
}

describe('Textarea conformance vectors', () => {
  it('textarea-001 root node is an HTML textarea', () => {
    expect(field().tagName).toBe('TEXTAREA')
  })

  it('textarea-002 custom className is applied alongside default styles', () => {
    const el = field({ className: 'custom-class' })
    expect(el).toHaveClass('custom-class')
    expect(el).toHaveClass('rounded-lg', 'border', 'w-full')
  })

  it('textarea-003 props are forwarded and text/placeholder appear', () => {
    const el = field({ value: 'text', placeholder: 'Enter text', onChange: () => {}, rows: 5 })
    expect(el).toHaveValue('text')
    expect(el).toHaveAttribute('placeholder', 'Enter text')
    expect(el).toHaveAttribute('rows', '5')
  })

  it('textarea-004 minimum height is 64px (min-h-16)', () => {
    expect(field()).toHaveClass('min-h-16')
  })

  it('textarea-005 fills the container width (w-full)', () => {
    expect(field()).toHaveClass('w-full')
  })

  it('textarea-006 focus indicator is a gold border and a gold/25 2px ring', () => {
    expect(field()).toHaveClass(
      'focus-visible:border-apt-gold',
      'focus-visible:ring-2',
      'focus-visible:ring-apt-gold/25',
    )
  })

  it('textarea-007 disabled disables pointer events, shows not-allowed, 50% opacity', () => {
    const el = field({ disabled: true })
    expect(el).toBeDisabled()
    expect(el).toHaveClass(
      'disabled:pointer-events-none',
      'disabled:cursor-not-allowed',
      'disabled:opacity-50',
    )
  })

  it('textarea-008 aria-invalid turns border and ring red', () => {
    const el = field({ 'aria-invalid': true })
    expect(el).toHaveAttribute('aria-invalid', 'true')
    expect(el).toHaveClass('aria-invalid:border-apt-red', 'aria-invalid:ring-2', 'aria-invalid:ring-apt-red/25')
  })

  it('textarea-009 no autoComplete prop yields the six suppression attributes', () => {
    expectOptOut(field())
  })

  it('textarea-010 data-slot="textarea" is queryable', () => {
    const { container } = render(<Textarea />)
    expect(container.querySelector('[data-slot="textarea"]')).toBeInTheDocument()
  })

  it('textarea-011 autoComplete="off" yields the six suppression attributes', () => {
    expectOptOut(field({ autoComplete: 'off' }))
  })

  it('textarea-012 autoComplete="email" is forwarded and no vendor attribute is present', () => {
    const el = field({ autoComplete: 'email' })
    expect(el).toHaveAttribute('autocomplete', 'email')
    for (const attr of VENDOR_ATTRS) expect(el).not.toHaveAttribute(attr)
  })

  it('textarea-013 padding is px-3 py-2 (12px / 8px)', () => {
    expect(field()).toHaveClass('px-3', 'py-2')
  })

  it('textarea-014 font size is text-sm (14px)', () => {
    expect(field()).toHaveClass('text-sm')
  })

  it('textarea-015 text color is the apt-text token', () => {
    expect(field()).toHaveClass('text-apt-text')
  })

  it('textarea-016 placeholder uses the apt-text-dim token', () => {
    const el = field({ placeholder: 'Enter text' })
    expect(el).toHaveAttribute('placeholder', 'Enter text')
    expect(el).toHaveClass('placeholder:text-apt-text-dim')
  })

  it('textarea-017 native outline is removed', () => {
    expect(field()).toHaveClass('outline-none')
  })

  it('textarea-018 colors transition via transition-colors', () => {
    expect(field()).toHaveClass('transition-colors')
  })

  it('textarea-019 a conflicting width class replaces the default w-full', () => {
    const el = field({ className: 'w-1/2' })
    expect(el).toHaveClass('w-1/2')
    expect(el).not.toHaveClass('w-full')
  })

  it('textarea-020 autoComplete=" OFF " is trimmed and case-folded to the opt-out', () => {
    expectOptOut(field({ autoComplete: ' OFF ' }))
  })

  it('textarea-021 a disabled textarea does not take focus', () => {
    const el = field({ disabled: true })
    el.focus()
    expect(el).not.toHaveFocus()
    expect(document.activeElement).not.toBe(el)
  })

  it('textarea-022 aria-invalid styling applies at rest, without focus', () => {
    const el = field({ 'aria-invalid': 'true' })
    expect(el).not.toHaveFocus()
    expect(el).toHaveClass('aria-invalid:border-apt-red', 'aria-invalid:ring-apt-red/25')
  })
})
