import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ContentOverlay } from '../components/ContentOverlay'

describe('ContentOverlay', () => {
  it('renders with open class when open', () => {
    const { container } = render(
      <ContentOverlay open onClose={() => {}}>
        <div>child</div>
      </ContentOverlay>,
    )
    expect(container.querySelector('.pc-content-overlay.open')).toBeInTheDocument()
  })

  it('omits open class when closed', () => {
    const { container } = render(
      <ContentOverlay open={false} onClose={() => {}}>
        <div>child</div>
      </ContentOverlay>,
    )
    const overlay = container.querySelector('.pc-content-overlay')
    expect(overlay).toBeInTheDocument()
    expect(overlay?.classList.contains('open')).toBe(false)
  })

  it('calls onClose when close button is clicked', () => {
    const onClose = vi.fn()
    render(
      <ContentOverlay open onClose={onClose}>
        <div>child</div>
      </ContentOverlay>,
    )
    fireEvent.click(screen.getByText(/back/))
    expect(onClose).toHaveBeenCalled()
  })

  it('renders children', () => {
    render(
      <ContentOverlay open onClose={() => {}}>
        <div data-testid="kid">payload</div>
      </ContentOverlay>,
    )
    expect(screen.getByTestId('kid')).toHaveTextContent('payload')
  })

  describe('conformance vectors', () => {
    const css = readFileSync(
      resolve(__dirname, '../css/components/content-overlay.css'),
      'utf8',
    )
    afterEach(() => {
      document.head.querySelectorAll('style[data-overlay-test]').forEach((n) => n.remove())
    })
    const root = (c: HTMLElement) => c.querySelector('.pc-content-overlay') as HTMLElement

    it('overlay-001: closed overlay keeps its parts, drops the open class and is invisible and pointer-inert by CSS', () => {
      const style = document.createElement('style')
      style.setAttribute('data-overlay-test', '')
      style.textContent = css
      document.head.appendChild(style)
      const onClose = vi.fn()
      const { container } = render(
        <ContentOverlay open={false} onClose={onClose}>
          <div>child</div>
        </ContentOverlay>,
      )
      expect(container.querySelector('.pc-content-overlay-header')).toBeInTheDocument()
      expect(container.querySelector('.pc-content-overlay-close')).toBeInTheDocument()
      expect(container.querySelector('.pc-content-overlay-body')).toBeInTheDocument()
      expect(root(container).classList.contains('open')).toBe(false)
      const cs = getComputedStyle(root(container))
      expect(cs.opacity).toBe('0')
      expect(cs.pointerEvents).toBe('none')
    })

    it('overlay-002: open=true gives class "pc-content-overlay open"', () => {
      const { container } = render(<ContentOverlay open onClose={() => {}}>x</ContentOverlay>)
      expect(root(container).className).toBe('pc-content-overlay open')
    })

    it('overlay-003: open=false gives class "pc-content-overlay"', () => {
      const { container } = render(
        <ContentOverlay open={false} onClose={() => {}}>x</ContentOverlay>,
      )
      expect(root(container).className).toBe('pc-content-overlay')
    })

    it('overlay-004: clicking close calls onClose once', () => {
      const onClose = vi.fn()
      const { container } = render(<ContentOverlay open onClose={onClose}>x</ContentOverlay>)
      fireEvent.click(container.querySelector('.pc-content-overlay-close')!)
      expect(onClose).toHaveBeenCalledTimes(1)
    })

    it('overlay-005: children render inside the body element', () => {
      const { container } = render(
        <ContentOverlay open onClose={() => {}}>
          <div>test content</div>
        </ContentOverlay>,
      )
      expect(container.querySelector('.pc-content-overlay-body')).toHaveTextContent('test content')
    })

    it('overlay-006: closeLabel is shown on the close button', () => {
      const { container } = render(
        <ContentOverlay open onClose={() => {}} closeLabel="Custom Label">x</ContentOverlay>,
      )
      expect(container.querySelector('.pc-content-overlay-close')).toHaveTextContent('Custom Label')
    })

    it('overlay-007: default close label is "← back"', () => {
      const { container } = render(<ContentOverlay open onClose={() => {}}>x</ContentOverlay>)
      expect(container.querySelector('.pc-content-overlay-close')!.textContent).toBe('← back')
    })

    it('overlay-008: className is added to the root', () => {
      const { container } = render(
        <ContentOverlay open onClose={() => {}} className="custom-style">x</ContentOverlay>,
      )
      expect(root(container).classList.contains('custom-style')).toBe(true)
      expect(root(container).className).toBe('pc-content-overlay open custom-style')
    })

    it('overlay-009: empty closeLabel renders an empty, clickable button', () => {
      const onClose = vi.fn()
      const { container } = render(
        <ContentOverlay open onClose={onClose} closeLabel="">x</ContentOverlay>,
      )
      const btn = container.querySelector('.pc-content-overlay-close') as HTMLElement
      expect(btn).toBeInTheDocument()
      expect(btn.textContent).toBe('')
      fireEvent.click(btn)
      expect(onClose).toHaveBeenCalledTimes(1)
    })

    it('overlay-010: three rapid clicks call onClose three times', () => {
      const onClose = vi.fn()
      const { container } = render(<ContentOverlay open onClose={onClose}>x</ContentOverlay>)
      const btn = container.querySelector('.pc-content-overlay-close')!
      fireEvent.click(btn)
      fireEvent.click(btn)
      fireEvent.click(btn)
      expect(onClose).toHaveBeenCalledTimes(3)
    })

    it('overlay-011: null children render an empty body without throwing', () => {
      const { container } = render(<ContentOverlay open onClose={() => {}}>{null}</ContentOverlay>)
      const body = container.querySelector('.pc-content-overlay-body')!
      expect(body).toBeInTheDocument()
      expect(body.childNodes.length).toBe(0)
    })

    it.skip('overlay-012: Enter on a focused close button while closed calls onClose (jsdom does not synthesize the Enter-to-click activation of a native button)', () => {})

    it('overlay-013: no className leaves the class exactly "pc-content-overlay open"', () => {
      const { container } = render(<ContentOverlay open onClose={() => {}}>x</ContentOverlay>)
      expect(root(container).className).toBe('pc-content-overlay open')
      expect(root(container).className).not.toContain('undefined')
    })
  })
})
