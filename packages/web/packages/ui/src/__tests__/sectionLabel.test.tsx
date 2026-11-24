/** Conformance vectors for the SectionLabel recipe (cookbook/ui/components/layout/section-label). */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { SectionLabel, sectionLabelClass } from '../components/section-label'
import { fieldCaptionClass } from '../lib/typography'
import { SectionHeader } from '../blocks/section-header'

const tokens = (s: string): string[] => s.split(' ').filter(Boolean)

describe('SectionLabel conformance vectors', () => {
  it('T1 renders the children with every token of sectionLabelClass', () => {
    render(<SectionLabel>Recent activity</SectionLabel>)
    const label = screen.getByText('Recent activity')
    for (const t of tokens(sectionLabelClass)) expect(label).toHaveClass(t)
  })

  it('T2 without trailing it is a single div with no row wrapper', () => {
    const { container } = render(<SectionLabel>Recent activity</SectionLabel>)
    expect(container.children).toHaveLength(1)
    const root = container.firstElementChild!
    expect(root.tagName).toBe('DIV')
    expect(root).toHaveTextContent('Recent activity')
    expect(root.children).toHaveLength(0)
    expect(root.className).not.toContain('justify-between')
  })

  it('T3 with trailing, label and trailing node are direct children of the flex row', () => {
    const { container } = render(<SectionLabel trailing={<button>gear</button>}>Stats</SectionLabel>)
    const wrapper = container.firstElementChild!
    expect(wrapper.className).toContain('flex items-center justify-between gap-2')
    expect(screen.getByText('Stats').parentElement).toBe(wrapper)
    expect(screen.getByRole('button', { name: 'gear' }).parentElement).toBe(wrapper)
  })

  it('T4 sectionLabelClass is a string carrying the whole treatment', () => {
    expect(typeof sectionLabelClass).toBe('string')
    for (const t of ['font-mono', 'text-[0.625rem]', 'font-medium', 'uppercase', 'tracking-[0.1em]', 'text-apt-text-dim']) {
      expect(tokens(sectionLabelClass)).toContain(t)
    }
  })

  it('T5 className merges onto the label alongside the treatment', () => {
    render(<SectionLabel className="mb-2">Env</SectionLabel>)
    expect(screen.getByText('Env')).toHaveClass('mb-2', 'text-apt-text-dim')
  })

  it('T6 sectionLabelClass differs from fieldCaptionClass', () => {
    expect(sectionLabelClass).not.toBe(fieldCaptionClass)
    expect(sectionLabelClass).toContain('text-[0.625rem]')
    expect(sectionLabelClass).toContain('text-apt-text-dim')
    expect(fieldCaptionClass).toContain('text-[0.7rem]')
    expect(fieldCaptionClass).toContain('text-apt-text-muted')
  })

  it('T7 sectionLabelClass shares no gold or text-sm token with the SectionHeader title', () => {
    render(<SectionHeader title="x" />)
    const h2 = screen.getByRole('heading', { level: 2 })
    expect(h2).toHaveClass('text-apt-gold', 'text-sm')
    expect(sectionLabelClass).not.toContain('apt-gold')
    expect(tokens(sectionLabelClass)).not.toContain('text-sm')
  })
})
