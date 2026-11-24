/**
 * `Field` — the shared caption + control row, `layout="inline"` in particular.
 *
 * "Labels right-aligned in a shared column" is a stated requirement (see the component's own
 * docblock) with no assertion anywhere: jsdom resolves no layout, so a rendered-pixel test is
 * not possible here — but the WIRING that produces the alignment (the caption's own alignment
 * classes, and the footnote landing in the label's second grid column) is exactly what three
 * separate mutations (drop `justify-self-end`, drop the footnote's `col-start-2`, drop the
 * inline caption classes entirely) broke while `categoriesAndTags.test.tsx` — which never
 * passes `hint`/`error` through to a `Field`, so its `FieldFootnote` never even renders — stayed
 * green throughout. This file exercises `Field` directly instead.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, cleanup } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, afterEach } from 'vitest'

import { Field, FIELD_LABEL_GROUP_CLASS } from '../blocks/field'

afterEach(cleanup)

describe('Field — layout="inline"', () => {
  it('right-aligns the caption in the shared label column', () => {
    render(
      <Field label="Slug" layout="inline">
        <input aria-label="Slug" />
      </Field>,
    )
    const caption = screen.getByText('Slug')
    expect(caption).toHaveClass('justify-self-end')
    expect(caption).toHaveClass('text-right')
  })

  it('puts the footnote in the second grid column, alongside the control', () => {
    render(
      <Field label="Slug" layout="inline" hint="Lowercase letters, numbers and dashes only.">
        <input aria-label="Slug" />
      </Field>,
    )
    const footnote = screen.getByText('Lowercase letters, numbers and dashes only.')
    expect(footnote).toHaveClass('col-start-2')
  })
})

describe('Field — layout="stacked" (the default)', () => {
  it('does NOT right-align the caption — inline alignment is specific to the inline layout', () => {
    render(
      <Field label="Slug">
        <input aria-label="Slug" />
      </Field>,
    )
    const caption = screen.getByText('Slug')
    expect(caption).not.toHaveClass('justify-self-end')
    expect(caption).not.toHaveClass('text-right')
  })

  it('does not pin the footnote to a grid column it does not have', () => {
    render(
      <Field label="Slug" hint="A hint.">
        <input aria-label="Slug" />
      </Field>,
    )
    expect(screen.getByText('A hint.')).not.toHaveClass('col-start-2')
  })
})

describe('Field — conformance vectors', () => {
  it('T1 one label wraps the uppercase-mono caption and the input; clicking the caption focuses the input', async () => {
    const { container } = render(
      <Field label="Name">
        <input />
      </Field>,
    )
    const labels = container.querySelectorAll('label')
    expect(labels).toHaveLength(1)
    const caption = screen.getByText('Name')
    expect(labels[0]!).toContainElement(caption)
    expect(labels[0]!).toContainElement(screen.getByRole('textbox'))
    expect(caption).toHaveClass('font-mono', 'uppercase')
    await userEvent.click(caption)
    expect(screen.getByRole('textbox')).toHaveFocus()
  })

  it('T2 the control renders between the caption and the supporting line', () => {
    const { container } = render(
      <Field label="Name" hint="A hint">
        <input data-testid="ctl" />
      </Field>,
    )
    const kids = Array.from(container.querySelector('label')!.children)
    expect(kids.map((k) => k.textContent || k.tagName)).toEqual(['Name', 'INPUT', 'A hint'])
  })

  it('T3 a dim-mono hint renders below the control when there is no error', () => {
    render(
      <Field label="Name" hint="Shown to teammates">
        <input />
      </Field>,
    )
    const hint = screen.getByText('Shown to teammates')
    expect(hint).toHaveClass('font-mono', 'text-apt-text-dim')
    expect(screen.getByRole('textbox').compareDocumentPosition(hint)).toBe(
      Node.DOCUMENT_POSITION_FOLLOWING,
    )
  })

  it('T4 a red-mono error renders and the hint is absent', () => {
    render(
      <Field label="Name" hint="Shown to teammates" error="Required">
        <input />
      </Field>,
    )
    expect(screen.getByText('Required')).toHaveClass('font-mono', 'text-apt-red')
    expect(screen.queryByText('Shown to teammates')).not.toBeInTheDocument()
  })

  it('T5 no supporting line renders when neither hint nor error is set', () => {
    const { container } = render(
      <Field label="Name">
        <input />
      </Field>,
    )
    expect(container.querySelectorAll('label > span')).toHaveLength(1)
    expect(container.querySelector('label')!.lastElementChild).toBe(screen.getByRole('textbox'))
  })

  it('T6 className merges onto the root, keeping the layout classes', () => {
    const { container } = render(
      <Field label="Name" className="mt-4">
        <input />
      </Field>,
    )
    expect(container.querySelector('label')).toHaveClass('flex', 'flex-col', 'mt-4')
  })

  it('T7 inline layout is a grid reading --apt-field-label-w, caption right-aligned in column 1, control and footnote in column 2', () => {
    expect(FIELD_LABEL_GROUP_CLASS).toBe('[--apt-field-label-w:6.5rem]')
    const { container } = render(
      <div className={FIELD_LABEL_GROUP_CLASS}>
        <Field label="Name" layout="inline" hint="A hint">
          <input />
        </Field>
      </div>,
    )
    const root = container.querySelector('label')!
    expect(root).toHaveClass('grid')
    expect(root.className).toContain('grid-cols-[var(--apt-field-label-w,')
    expect(screen.getByText('Name')).toHaveClass('justify-self-end', 'text-right')
    const cell = screen.getByRole('textbox').parentElement!
    expect(cell.parentElement).toBe(root)
    expect(cell).toHaveClass('min-w-0')
    expect(screen.getByText('A hint')).toHaveClass('col-start-2')
  })

  it('T8 errorId names the error span; a hint span gets no id', () => {
    const { rerender } = render(
      <Field label="Name" errorId="name-error" error="Required">
        <input />
      </Field>,
    )
    const err = screen.getByText('Required')
    expect(err.tagName).toBe('SPAN')
    expect(err).toHaveAttribute('id', 'name-error')
    rerender(
      <Field label="Name" errorId="name-error" hint="Shown to teammates">
        <input />
      </Field>,
    )
    expect(screen.getByText('Shown to teammates')).not.toHaveAttribute('id')
  })

  it('T9 no element carries the errorId when only a hint is set', () => {
    const { container } = render(
      <Field label="Name" errorId="name-error" hint="Shown to teammates">
        <input />
      </Field>,
    )
    expect(container.querySelector('#name-error')).toBeNull()
  })

  it('T10 the caption is uppercased by CSS text-transform, not by an invariant uppercase call', () => {
    render(
      <div lang="de">
        <Field label="straße">
          <input />
        </Field>
      </div>,
    )
    const caption = screen.getByText('straße')
    expect(caption.textContent).toBe('straße')
    expect(caption).toHaveClass('uppercase')
  })

  it('T11 Field adds no opacity or dimming class of its own around a disabled control', () => {
    const { container } = render(
      <Field label="Name">
        <input disabled />
      </Field>,
    )
    const root = container.querySelector('label')!
    const classes = [root, ...Array.from(root.querySelectorAll('span'))].map((e) => e.className)
    for (const c of classes) expect(c).not.toMatch(/(^|\s)(opacity-|disabled:)/)
    expect(screen.getByRole('textbox')).toBeDisabled()
  })
})
