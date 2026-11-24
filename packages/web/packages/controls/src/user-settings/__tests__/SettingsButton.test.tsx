import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { SettingsButton } from '../components/SettingsButton'

describe('SettingsButton', () => {
  it('settings-button-001: renders a button element', () => {
    render(<SettingsButton />)
    expect(screen.getByRole('button').tagName).toBe('BUTTON')
  })

  it('settings-button-002: defaults to the primary variant', () => {
    render(<SettingsButton />)
    expect(screen.getByRole('button')).toHaveClass('aws-button--primary')
  })

  it('settings-button-003: defaults type to button', () => {
    render(<SettingsButton />)
    expect(screen.getByRole('button')).toHaveAttribute('type', 'button')
  })

  it('settings-button-004: applies the base class', () => {
    render(<SettingsButton />)
    expect(screen.getByRole('button')).toHaveClass('aws-button')
  })

  it('settings-button-005: applies the variant class', () => {
    render(<SettingsButton variant="secondary" />)
    expect(screen.getByRole('button')).toHaveClass('aws-button--secondary')
  })

  it('settings-button-006: merges className after base and variant classes', () => {
    render(<SettingsButton className="custom-class" variant="primary" />)
    expect(screen.getByRole('button').className).toBe('aws-button aws-button--primary custom-class')
  })

  it('settings-button-007: renders text children', () => {
    render(<SettingsButton>Click me</SettingsButton>)
    expect(screen.getByRole('button')).toHaveTextContent('Click me')
  })

  it('settings-button-008: renders element children', () => {
    render(
      <SettingsButton>
        <span>React element</span>
      </SettingsButton>,
    )
    const span = screen.getByRole('button').querySelector('span')
    expect(span).not.toBeNull()
    expect(span?.textContent).toBe('React element')
  })

  it('settings-button-009: passes onClick and disabled through', () => {
    const onClick = vi.fn()
    const { rerender } = render(<SettingsButton onClick={onClick}>Go</SettingsButton>)
    fireEvent.click(screen.getByRole('button'))
    expect(onClick).toHaveBeenCalledTimes(1)
    rerender(
      <SettingsButton onClick={onClick} disabled>
        Go
      </SettingsButton>,
    )
    expect(screen.getByRole('button')).toBeDisabled()
    fireEvent.click(screen.getByRole('button'))
    expect(onClick).toHaveBeenCalledTimes(1)
  })

  it('settings-button-010: passes aria-label through', () => {
    render(<SettingsButton aria-label="Settings" />)
    expect(screen.getByRole('button')).toHaveAttribute('aria-label', 'Settings')
  })

  it('settings-button-011: no extra spaces without className', () => {
    render(<SettingsButton variant="primary" />)
    expect(screen.getByRole('button').className).toBe('aws-button aws-button--primary')
  })

  // vitest does not type-check at runtime; the negative check needs tsc with an uncast variant="invalid".
  it.skip('settings-button-012: variant outside the closed set fails compilation', () => {})

  it('settings-button-013: type can be overridden', () => {
    render(<SettingsButton type="submit" />)
    expect(screen.getByRole('button')).toHaveAttribute('type', 'submit')
  })

  it('settings-button-014: empty className is filtered out', () => {
    render(<SettingsButton className="" variant="primary" />)
    expect(screen.getByRole('button').className).toBe('aws-button aws-button--primary')
  })
})
