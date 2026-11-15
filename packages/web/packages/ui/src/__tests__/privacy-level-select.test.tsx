/** Unit tests for PrivacyLevelSelect (conformance vectors privacy-001..039) and the
 *  privacy-level ↔ wire-word conversion maps beside it. Real Base-UI Popover in jsdom;
 *  interactions use fireEvent. */
/// <reference types="@testing-library/jest-dom/vitest" />
import * as React from 'react'
import { render, screen, fireEvent, waitFor, within } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import {
  PrivacyLevelSelect,
  type PrivacyLevel,
  PRIVACY_WIRE_VALUE,
  PRIVACY_LEVEL_FROM_WIRE,
  PRIVACY_AUDIENCE_MASK,
} from '../components/privacy-level-select'

describe('privacy level ↔ wire word', () => {
  it('spells only-me as private on the wire', () => {
    expect(PRIVACY_WIRE_VALUE['only-me']).toBe('private')
    expect(PRIVACY_WIRE_VALUE.hub).toBe('hub')
    expect(PRIVACY_WIRE_VALUE.public).toBe('public')
  })

  it('round-trips every level', () => {
    for (const level of ['only-me', 'hub', 'public'] as const) {
      expect(PRIVACY_LEVEL_FROM_WIRE(PRIVACY_WIRE_VALUE[level])).toBe(level)
    }
  })

  it('falls back to only-me on an unknown word', () => {
    // A word the backend CHECK cannot produce must not render as "Public".
    expect(PRIVACY_LEVEL_FROM_WIRE('unlisted')).toBe('only-me')
    expect(PRIVACY_LEVEL_FROM_WIRE('')).toBe('only-me')
  })

  it('leaves the per-row mask map untouched', () => {
    // The two maps answer different questions and must not be collapsed: a per-ROW grant is an
    // integer audience mask, a PAGE switch is a stored word.
    expect(PRIVACY_AUDIENCE_MASK['only-me']).toBe(0)
  })
})

// ── PrivacyLevelSelect component: conformance vectors ────────────────────────

function trigger(): HTMLElement {
  return document.querySelector('[aria-haspopup="listbox"]') as HTMLElement
}

function listbox(): HTMLElement {
  return screen.getByRole('listbox')
}

function option(name: RegExp): HTMLElement {
  return screen.getByRole('option', { name })
}

function renderSelect(props: Partial<React.ComponentProps<typeof PrivacyLevelSelect>> = {}) {
  const onChange = vi.fn<(v: PrivacyLevel) => void>()
  const utils = render(<PrivacyLevelSelect value="only-me" onChange={onChange} {...props} />)
  return { onChange, ...utils }
}

function openByClick(): HTMLElement {
  fireEvent.click(trigger())
  return listbox()
}

describe('PrivacyLevelSelect conformance vectors', () => {
  it('privacy-001 trigger shows the current level label', () => {
    renderSelect({ value: 'only-me' })
    expect(trigger()).toHaveTextContent('Only me')
  })

  it('privacy-002 trigger shows a 14px chevrons-up-down icon', () => {
    renderSelect()
    const chevron = trigger().querySelector('svg.lucide-chevrons-up-down')
    expect(chevron).not.toBeNull()
    expect(chevron).toHaveAttribute('width', '14')
    expect(chevron).toHaveAttribute('height', '14')
    // Right-aligned: it is the last child of the justify-between trigger.
    expect(trigger()).toHaveClass('justify-between')
    expect(trigger().lastElementChild).toBe(chevron)
  })

  it('privacy-003 clicking the trigger opens the popover', () => {
    renderSelect()
    expect(trigger()).toHaveAttribute('aria-expanded', 'false')
    openByClick()
    expect(trigger()).toHaveAttribute('aria-expanded', 'true')
  })

  it('privacy-004 clicking an option closes the popover and calls onChange("hub")', async () => {
    const { onChange } = renderSelect()
    openByClick()
    fireEvent.click(option(/Hub members/))
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith('hub')
    await waitFor(() => expect(trigger()).toHaveAttribute('aria-expanded', 'false'))
    expect(screen.queryByRole('listbox')).toBeNull()
  })

  it('privacy-005 Escape on the listbox closes the popover', async () => {
    renderSelect()
    openByClick()
    fireEvent.keyDown(listbox(), { key: 'Escape' })
    await waitFor(() => expect(trigger()).toHaveAttribute('aria-expanded', 'false'))
  })

  it('privacy-006 ArrowDown moves the cursor from hub to public', () => {
    renderSelect({ value: 'hub' })
    const lb = openByClick()
    expect(lb).toHaveAttribute('aria-activedescendant', option(/Hub members/).id)
    fireEvent.keyDown(lb, { key: 'ArrowDown' })
    expect(lb).toHaveAttribute('aria-activedescendant', option(/Public/).id)
  })

  it('privacy-007 ArrowDown at public stays on public, never reaching Team / Org', () => {
    renderSelect({ value: 'public' })
    const lb = openByClick()
    fireEvent.keyDown(lb, { key: 'ArrowDown' })
    expect(lb).toHaveAttribute('aria-activedescendant', option(/Public/).id)
    const teamOrg = option(/Team \/ Org/)
    expect(lb.getAttribute('aria-activedescendant')).not.toBe(teamOrg.id)
  })

  it('privacy-008 Enter on only-me commits only-me and nothing else', async () => {
    const { onChange } = renderSelect({ value: 'only-me' })
    const lb = openByClick()
    fireEvent.keyDown(lb, { key: 'Enter' })
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith('only-me')
    await waitFor(() => expect(trigger()).toHaveAttribute('aria-expanded', 'false'))
  })

  it('privacy-009 Space on the trigger opens it with the cursor on the current value', () => {
    renderSelect({ value: 'hub' })
    fireEvent.keyDown(trigger(), { key: ' ' })
    expect(trigger()).toHaveAttribute('aria-expanded', 'true')
    expect(listbox()).toHaveAttribute('aria-activedescendant', option(/Hub members/).id)
  })

  it('privacy-010 three enabled options are rendered', () => {
    renderSelect()
    openByClick()
    const enabled = screen
      .getAllByRole('option')
      .filter((o) => o.getAttribute('aria-disabled') !== 'true')
    expect(enabled).toHaveLength(3)
    expect(enabled.map((o) => within(o).getByText(/^(Only me|Hub members|Public)$/).textContent)).toEqual([
      'Only me',
      'Hub members',
      'Public',
    ])
    enabled.forEach((o) => expect(o.tagName).toBe('BUTTON'))
  })

  it('privacy-011 the gold 14px check shows only on the selected option', () => {
    renderSelect({ value: 'hub' })
    openByClick()
    const checkOf = (o: HTMLElement) => o.querySelector('svg.lucide-check') as SVGElement
    expect(checkOf(option(/Hub members/))).toHaveClass('text-apt-gold')
    expect(checkOf(option(/Hub members/))).toHaveAttribute('width', '14')
    expect(checkOf(option(/Hub members/))).not.toHaveClass('opacity-0')
    expect(checkOf(option(/Only me/))).toHaveClass('opacity-0')
    expect(checkOf(option(/Public/))).toHaveClass('opacity-0')
  })

  it('privacy-012 Team / Org is disabled at 40% opacity with a Coming soon badge', () => {
    renderSelect()
    openByClick()
    const teamOrg = option(/Team \/ Org/)
    expect(teamOrg).toHaveClass('opacity-40')
    expect(teamOrg).toHaveTextContent('Coming soon')
    expect(teamOrg).toHaveTextContent('Visible to members of your organization')
  })

  it('privacy-013 hovering an option highlights it with apt-highlight/15', () => {
    renderSelect()
    openByClick()
    const pub = option(/Public/)
    expect(pub).not.toHaveAttribute('data-highlighted')
    fireEvent.mouseEnter(pub)
    expect(pub).toHaveAttribute('data-highlighted')
    expect(pub.className).toContain('data-[highlighted]:bg-apt-highlight/15')
  })

  it('privacy-014 the keyboard-focused option is highlighted with apt-highlight/15', () => {
    renderSelect({ value: 'only-me' })
    const lb = openByClick()
    fireEvent.keyDown(lb, { key: 'ArrowDown' })
    const hub = option(/Hub members/)
    expect(hub).toHaveAttribute('data-highlighted')
    expect(option(/Only me/)).not.toHaveAttribute('data-highlighted')
    expect(hub.className).toContain('data-[highlighted]:bg-apt-highlight/15')
  })

  it('privacy-015 disabled: clicking the trigger does not open and onChange is not called', () => {
    const { onChange } = renderSelect({ disabled: true })
    fireEvent.click(trigger())
    expect(screen.queryByRole('listbox')).toBeNull()
    expect(trigger()).toHaveAttribute('aria-expanded', 'false')
    expect(onChange).not.toHaveBeenCalled()
  })

  it('privacy-016 disabled trigger has 50% opacity and a not-allowed cursor', () => {
    renderSelect({ disabled: true })
    expect(trigger()).toBeDisabled()
    expect(trigger()).toHaveClass('disabled:opacity-50', 'disabled:cursor-not-allowed')
  })

  it('privacy-017 opening moves focus to the listbox surface', async () => {
    renderSelect()
    const lb = openByClick()
    await waitFor(() => expect(document.activeElement).toBe(lb))
  })

  it('privacy-018 opening resets the cursor to the current value', () => {
    renderSelect({ value: 'public' })
    const lb = openByClick()
    expect(lb).toHaveAttribute('aria-activedescendant', option(/Public/).id)
  })

  it('privacy-020 an external value change updates trigger, selection and cursor on next open', () => {
    const onChange = vi.fn()
    const { rerender } = render(<PrivacyLevelSelect value="only-me" onChange={onChange} />)
    rerender(<PrivacyLevelSelect value="public" onChange={onChange} />)
    expect(trigger()).toHaveTextContent('Public')
    expect(trigger().querySelector('svg.lucide-globe')).not.toBeNull()
    const lb = openByClick()
    expect(option(/Public/)).toHaveAttribute('aria-selected', 'true')
    expect(option(/Public/).querySelector('svg.lucide-check')).not.toHaveClass('opacity-0')
    expect(option(/Only me/)).toHaveAttribute('aria-selected', 'false')
    expect(option(/Hub members/)).toHaveAttribute('aria-selected', 'false')
    expect(lb).toHaveAttribute('aria-activedescendant', option(/Public/).id)
  })

  it('privacy-021 clicking hub calls onChange with the string "hub"', () => {
    const { onChange } = renderSelect()
    openByClick()
    fireEvent.click(option(/Hub members/))
    expect(onChange).toHaveBeenCalledWith('hub')
    expect(typeof onChange.mock.calls[0]![0]).toBe('string')
  })

  it('privacy-022 ariaLabel labels both the trigger and the listbox', () => {
    renderSelect({ ariaLabel: 'Profile visibility' })
    expect(trigger()).toHaveAttribute('aria-label', 'Profile visibility')
    openByClick()
    expect(listbox()).toHaveAttribute('aria-label', 'Profile visibility')
  })

  it('privacy-023 the trigger has aria-haspopup="listbox"', () => {
    renderSelect()
    expect(trigger()).toHaveAttribute('aria-haspopup', 'listbox')
  })

  it('privacy-024 aria-expanded tracks open and closed', async () => {
    renderSelect()
    expect(trigger()).toHaveAttribute('aria-expanded', 'false')
    openByClick()
    expect(trigger()).toHaveAttribute('aria-expanded', 'true')
    fireEvent.keyDown(listbox(), { key: 'Escape' })
    await waitFor(() => expect(trigger()).toHaveAttribute('aria-expanded', 'false'))
  })

  it('privacy-025 the listbox aria-activedescendant is the highlighted option id', () => {
    renderSelect({ value: 'hub' })
    const lb = openByClick()
    expect(lb).toHaveAttribute('aria-activedescendant', option(/Hub members/).id)
    expect(option(/Hub members/).id).not.toBe('')
  })

  it('privacy-026 the popover surface has role="listbox"', () => {
    renderSelect()
    openByClick()
    expect(screen.getAllByRole('listbox')).toHaveLength(1)
  })

  it('privacy-027 all four entries have role="option"', () => {
    renderSelect()
    openByClick()
    expect(screen.getAllByRole('option')).toHaveLength(4)
  })

  it('privacy-028 only the selected option has aria-selected="true"', () => {
    renderSelect({ value: 'only-me' })
    openByClick()
    expect(option(/Only me/)).toHaveAttribute('aria-selected', 'true')
    expect(option(/Hub members/)).toHaveAttribute('aria-selected', 'false')
    expect(option(/Public/)).toHaveAttribute('aria-selected', 'false')
    expect(option(/Team \/ Org/)).toHaveAttribute('aria-selected', 'false')
  })

  it('privacy-029 Team / Org has aria-disabled="true"', () => {
    renderSelect()
    openByClick()
    expect(option(/Team \/ Org/)).toHaveAttribute('aria-disabled', 'true')
  })

  it('privacy-030 className is merged into the trigger beside the defaults', () => {
    renderSelect({ className: 'custom-class' })
    expect(trigger()).toHaveClass('custom-class', 'h-9', 'w-full', 'rounded-lg')
  })

  it('privacy-031 ArrowDown on the trigger prevents the browser default', () => {
    renderSelect()
    const notPrevented = fireEvent.keyDown(trigger(), { key: 'ArrowDown' })
    expect(notPrevented).toBe(false)
    expect(trigger()).toHaveAttribute('aria-expanded', 'true')
  })

  it('privacy-032 ArrowUp inside the open listbox prevents the browser default', () => {
    renderSelect({ value: 'hub' })
    const lb = openByClick()
    expect(fireEvent.keyDown(lb, { key: 'ArrowUp' })).toBe(false)
    expect(lb).toHaveAttribute('aria-activedescendant', option(/Only me/).id)
  })

  it('privacy-033 two instances produce unique option ids and own their activedescendant', async () => {
    render(
      <>
        <PrivacyLevelSelect value="hub" onChange={() => {}} ariaLabel="First" />
        <PrivacyLevelSelect value="public" onChange={() => {}} ariaLabel="Second" />
      </>,
    )
    const triggers = Array.from(document.querySelectorAll('[aria-haspopup="listbox"]'))
    expect(triggers).toHaveLength(2)
    // Opening the second popover dismisses the first (outside press), so open them in turn.
    const ids: string[] = []
    for (const t of triggers) {
      fireEvent.click(t)
      const lb = screen.getAllByRole('listbox').at(-1)!
      const active = lb.getAttribute('aria-activedescendant')!
      expect(lb.querySelector(`[id="${active}"]`)).not.toBeNull()
      const own = within(lb)
        .getAllByRole('option')
        .map((o) => o.id)
        .filter((id) => id !== '')
      expect(own).toHaveLength(3)
      ids.push(...own)
      fireEvent.keyDown(lb, { key: 'Escape' })
      await waitFor(() => expect(t).toHaveAttribute('aria-expanded', 'false'))
    }
    expect(new Set(ids).size).toBe(6)
    for (const id of ids) expect(id).toMatch(/-opt-(only_me|hub|public)$/)
  })

  it.skip('privacy-034 label truncates with an ellipsis (real layout; jsdom has none)', () => {})

  it('privacy-035 an external value change while open moves the check but not the cursor', () => {
    const onChange = vi.fn()
    const { rerender } = render(<PrivacyLevelSelect value="only-me" onChange={onChange} />)
    const lb = openByClick()
    fireEvent.keyDown(lb, { key: 'ArrowDown' })
    expect(lb).toHaveAttribute('aria-activedescendant', option(/Hub members/).id)
    rerender(<PrivacyLevelSelect value="public" onChange={onChange} />)
    expect(trigger()).toHaveTextContent('Public')
    expect(option(/Public/)).toHaveAttribute('aria-selected', 'true')
    expect(option(/Public/).querySelector('svg.lucide-check')).not.toHaveClass('opacity-0')
    expect(option(/Only me/)).toHaveAttribute('aria-selected', 'false')
    expect(listbox()).toHaveAttribute('aria-activedescendant', option(/Hub members/).id)
  })

  it('privacy-036 Escape prevents the default, closes and does not call onChange', async () => {
    const { onChange } = renderSelect()
    const lb = openByClick()
    expect(fireEvent.keyDown(lb, { key: 'Escape' })).toBe(false)
    await waitFor(() => expect(trigger()).toHaveAttribute('aria-expanded', 'false'))
    expect(onChange).not.toHaveBeenCalled()
  })

  it('privacy-037 disabled turning true while open keeps the popover open, trigger disabled', () => {
    const onChange = vi.fn()
    const { rerender } = render(<PrivacyLevelSelect value="only-me" onChange={onChange} />)
    openByClick()
    rerender(<PrivacyLevelSelect value="only-me" onChange={onChange} disabled />)
    expect(screen.getByRole('listbox')).toBeInTheDocument()
    expect(trigger()).toBeDisabled()
    expect(trigger()).toHaveClass('disabled:opacity-50', 'disabled:cursor-not-allowed')
  })

  it('privacy-038 Enter on the trigger opens it, focuses the listbox, cursor on the value', async () => {
    renderSelect({ value: 'hub' })
    fireEvent.keyDown(trigger(), { key: 'Enter' })
    expect(trigger()).toHaveAttribute('aria-expanded', 'true')
    expect(listbox()).toHaveAttribute('aria-activedescendant', option(/Hub members/).id)
    await waitFor(() => expect(document.activeElement).toBe(listbox()))
  })

  it('privacy-039 Space on hub commits once with "hub" and closes', async () => {
    const { onChange } = renderSelect({ value: 'only-me' })
    const lb = openByClick()
    fireEvent.keyDown(lb, { key: 'ArrowDown' })
    fireEvent.keyDown(lb, { key: ' ' })
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith('hub')
    await waitFor(() => expect(trigger()).toHaveAttribute('aria-expanded', 'false'))
  })
})
