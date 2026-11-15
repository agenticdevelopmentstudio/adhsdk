import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, waitFor, cleanup, act } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {
  Tooltip,
  TooltipTrigger,
  TooltipContent,
  TooltipProvider,
} from '../components/tooltip'

afterEach(() => {
  cleanup()
  document.documentElement.removeAttribute('dir')
})

const sleep = (ms: number) => act(() => new Promise<void>((r) => setTimeout(r, ms)))
const content = () => document.querySelector('[data-slot="tooltip-content"]')

function Basic({
  delay,
  contentProps,
  children = 'Help text',
}: {
  delay?: number
  contentProps?: React.ComponentProps<typeof TooltipContent>
  children?: string
}) {
  return (
    <TooltipProvider delay={delay}>
      <Tooltip>
        <TooltipTrigger>Trigger</TooltipTrigger>
        <TooltipContent {...contentProps}>{children}</TooltipContent>
      </Tooltip>
    </TooltipProvider>
  )
}

describe('Tooltip conformance', () => {
  it('tooltip-001 opens on hover after the default 200ms delay', async () => {
    const user = userEvent.setup()
    render(<Basic />)
    await user.hover(screen.getByText('Trigger'))
    expect(content()).toBeNull()
    await waitFor(() => expect(content()).not.toBeNull(), { timeout: 1500 })
    expect(screen.getByText('Help text')).toBeInTheDocument()
  })

  it('tooltip-002 opens on keyboard focus', async () => {
    const user = userEvent.setup()
    render(<Basic />)
    await user.tab()
    expect(screen.getByText('Trigger')).toHaveFocus()
    await waitFor(() => expect(content()).not.toBeNull(), { timeout: 1500 })
  })

  it('tooltip-003 honours a custom provider delay of 500ms', async () => {
    const user = userEvent.setup()
    render(<Basic delay={500} />)
    await user.hover(screen.getByText('Trigger'))
    await sleep(300)
    expect(content()).toBeNull()
    await waitFor(() => expect(content()).not.toBeNull(), { timeout: 1500 })
  })

  it('tooltip-004 portals the content out of an overflow:hidden ancestor', async () => {
    const user = userEvent.setup()
    render(
      <div data-testid="clip" style={{ overflow: 'hidden' }}>
        <Basic delay={0} />
      </div>,
    )
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    expect(screen.getByTestId('clip').contains(content())).toBe(false)
    expect(document.body.contains(content())).toBe(true)
  })

  it.skip('tooltip-005 places the tooltip 8px below the trigger (jsdom has no layout)', () => {})

  it.skip('tooltip-006 aligns the leading edges (jsdom has no layout)', () => {})

  it('tooltip-007 merges a consumer className onto the content', async () => {
    const user = userEvent.setup()
    render(<Basic delay={0} contentProps={{ className: 'custom-bg' }} />)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    expect(content()).toHaveClass('custom-bg')
    expect(content()).toHaveClass('bg-apt-surface-2')
  })

  it('tooltip-008 renders the arrow by default', async () => {
    const user = userEvent.setup()
    render(<Basic delay={0} />)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    expect(content()!.querySelector('.rotate-45')).not.toBeNull()
  })

  it('tooltip-009 omits the arrow when arrow={false}', async () => {
    const user = userEvent.setup()
    render(<Basic delay={0} contentProps={{ arrow: false }} />)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    expect(content()!.querySelector('.rotate-45')).toBeNull()
    expect(content()!.children.length).toBe(0)
  })

  it('tooltip-010 renders the children text inside the content', async () => {
    const user = userEvent.setup()
    render(<Basic delay={0} />)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    expect(content()).toHaveTextContent('Help text')
  })

  it('tooltip-011 closes on Escape', async () => {
    const user = userEvent.setup()
    render(<Basic delay={0} />)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    await user.keyboard('{Escape}')
    await waitFor(() => expect(content()).toBeNull())
  })

  it.skip('tooltip-012 stays open over the content (Base UI hover-bridge uses a safe-polygon over real element geometry; jsdom rects are all zero)', () => {})

  it('tooltip-013 closes when the pointer leaves trigger and content', async () => {
    const user = userEvent.setup()
    render(<Basic delay={0} />)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    await user.unhover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).toBeNull(), { timeout: 1500 })
  })

  it('tooltip-014 sets the align data attribute under dir=rtl (RTL geometry is not measurable in jsdom)', async () => {
    document.documentElement.setAttribute('dir', 'rtl')
    const user = userEvent.setup()
    render(<Basic delay={0} contentProps={{ align: 'start' }} />)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    expect(content()).toHaveAttribute('data-align', 'start')
  })

  it('tooltip-015 renders with empty content and no visible text', async () => {
    const user = userEvent.setup()
    render(<Basic delay={0} contentProps={{ arrow: false }}>{''}</Basic>)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    expect(content()).toHaveTextContent('')
  })

  it('tooltip-016 caps the content width with max-w-xs so long text wraps', async () => {
    const user = userEvent.setup()
    render(<Basic delay={0}>{'word '.repeat(200)}</Basic>)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    expect(content()).toHaveClass('max-w-xs')
  })

  it('tooltip-017 only one tooltip is open when moving between two triggers', async () => {
    const user = userEvent.setup()
    render(
      <TooltipProvider delay={0}>
        <Tooltip>
          <TooltipTrigger>One</TooltipTrigger>
          <TooltipContent>First</TooltipContent>
        </Tooltip>
        <Tooltip>
          <TooltipTrigger>Two</TooltipTrigger>
          <TooltipContent>Second</TooltipContent>
        </Tooltip>
      </TooltipProvider>,
    )
    await user.hover(screen.getByText('One'))
    await user.hover(screen.getByText('Two'))
    await waitFor(() => expect(screen.queryByText('Second')).not.toBeNull())
    await waitFor(() => expect(screen.queryByText('First')).toBeNull(), { timeout: 1500 })
    expect(document.querySelectorAll('[data-slot="tooltip-content"]').length).toBe(1)
  })

  it.skip('tooltip-018 flips near the viewport edge (needs real layout and viewport geometry)', () => {})

  it('tooltip-019 the arrow carries the rotate-[225deg] class for side=bottom', async () => {
    const user = userEvent.setup()
    render(<Basic delay={0} contentProps={{ side: 'bottom' }} />)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    const arrow = content()!.querySelector('.rotate-45') as HTMLElement
    expect(arrow.className).toContain('data-[side=bottom]:rotate-[225deg]')
    expect(content()!.closest('[data-side]')).toHaveAttribute('data-side', 'bottom')
  })

  it('tooltip-020 an open tooltip stays open when the trigger becomes disabled', async () => {
    const user = userEvent.setup()
    function Harness({ disabled }: { disabled: boolean }) {
      return (
        <TooltipProvider delay={0}>
          <Tooltip>
            <TooltipTrigger disabled={disabled}>Trigger</TooltipTrigger>
            <TooltipContent>Help text</TooltipContent>
          </Tooltip>
        </TooltipProvider>
      )
    }
    const { rerender } = render(<Harness disabled={false} />)
    await user.hover(screen.getByText('Trigger'))
    await waitFor(() => expect(content()).not.toBeNull())
    rerender(<Harness disabled />)
    await sleep(300)
    expect(content()).not.toBeNull()
  })
})
