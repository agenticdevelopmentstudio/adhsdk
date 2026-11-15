// @vitest-environment jsdom
// MarkdownThemeSwitcher — conformance vectors theme-001..011.
/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, cleanup, fireEvent } from '@testing-library/react'
import { MarkdownThemeSwitcher } from '../components/MarkdownThemeSwitcher'

afterEach(() => {
  cleanup()
  vi.resetModules()
  vi.doUnmock('../themes/registry')
})

function select(): HTMLSelectElement {
  return screen.getByRole('combobox') as HTMLSelectElement
}

describe('MarkdownThemeSwitcher', () => {
  it('theme-001 selects the active theme', () => {
    render(<MarkdownThemeSwitcher activeThemeId="sepia" onThemeChange={() => {}} />)
    expect(select().value).toBe('sepia')
  })

  it('theme-002 follows a changed activeThemeId', () => {
    const { rerender } = render(<MarkdownThemeSwitcher activeThemeId="light" onThemeChange={() => {}} />)
    expect(select().value).toBe('light')
    rerender(<MarkdownThemeSwitcher activeThemeId="github" onThemeChange={() => {}} />)
    expect(select().value).toBe('github')
    expect(select().selectedOptions[0]!.textContent).toBe('GitHub')
  })

  it('theme-003 emits the selected id once', () => {
    const onChange = vi.fn()
    render(<MarkdownThemeSwitcher activeThemeId="dark" onThemeChange={onChange} />)
    fireEvent.change(select(), { target: { value: 'light' } })
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith('light')
  })

  it('theme-004 renders the four built-in options in order', () => {
    render(<MarkdownThemeSwitcher activeThemeId="dark" onThemeChange={() => {}} />)
    const opts = Array.from(select().options)
    expect(opts.map((o) => [o.value, o.textContent])).toEqual([
      ['dark', 'Dark'],
      ['light', 'Light'],
      ['sepia', 'Sepia'],
      ['github', 'GitHub'],
    ])
  })

  it('theme-005 gives each instance a distinct control id', () => {
    const { container } = render(
      <>
        <MarkdownThemeSwitcher activeThemeId="dark" onThemeChange={() => {}} />
        <MarkdownThemeSwitcher activeThemeId="dark" onThemeChange={() => {}} />
      </>,
    )
    const selects = Array.from(container.querySelectorAll('select'))
    const labels = Array.from(container.querySelectorAll('label'))
    expect(selects).toHaveLength(2)
    expect(selects[0]!.id).not.toBe(selects[1]!.id)
    expect(labels[0]!.htmlFor).toBe(selects[0]!.id)
    expect(labels[1]!.htmlFor).toBe(selects[1]!.id)
    const ids = Array.from(container.querySelectorAll('[id]')).map((e) => e.id)
    expect(new Set(ids).size).toBe(ids.length)
  })

  it('theme-006 associates the label with the select', () => {
    const { container } = render(<MarkdownThemeSwitcher activeThemeId="dark" onThemeChange={() => {}} />)
    const label = container.querySelector('label')!
    expect(label).toBeInTheDocument()
    expect(label.htmlFor).toBe(select().id)
    expect(select().id).not.toBe('')
  })

  it('theme-007 exposes the accessible name "Select reading theme"', () => {
    render(<MarkdownThemeSwitcher activeThemeId="dark" onThemeChange={() => {}} />)
    expect(screen.getByRole('combobox', { name: 'Select reading theme' })).toBeInTheDocument()
  })

  it('theme-008 wraps label and select in one group', () => {
    render(<MarkdownThemeSwitcher activeThemeId="dark" onThemeChange={() => {}} />)
    const group = screen.getByRole('group')
    expect(group).toContainElement(select())
    expect(group.querySelector('label')).not.toBeNull()
  })

  it('theme-009 selecting the active theme leaves the value and fires nothing', () => {
    const onChange = vi.fn()
    render(<MarkdownThemeSwitcher activeThemeId="light" onThemeChange={onChange} />)
    // A native <select> fires no change event when the chosen option is already selected.
    expect(select().value).toBe('light')
    expect(onChange).not.toHaveBeenCalled()
  })

  it('theme-010 renders no options when the registry is empty', async () => {
    vi.resetModules()
    vi.doMock('../themes/registry', () => ({ VIEWER_THEMES: [] }))
    const { MarkdownThemeSwitcher: Mocked } = await import('../components/MarkdownThemeSwitcher')
    expect(() => render(<Mocked activeThemeId="dark" onThemeChange={() => {}} />)).not.toThrow()
    expect(select().options).toHaveLength(0)
  })

  it('theme-011 shows the first option for an unknown id and emits only real changes', () => {
    const onChange = vi.fn()
    render(<MarkdownThemeSwitcher activeThemeId="not-a-theme" onThemeChange={onChange} />)
    // Controlled <select> with no matching option: the browser shows the first option.
    expect(select().selectedOptions[0]!.textContent).toBe('Dark')
    fireEvent.change(select(), { target: { value: 'light' } })
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith('light')
  })
})
