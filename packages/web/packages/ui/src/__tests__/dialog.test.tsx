/**
 * Conformance tests for the Dialog recipe (ui/components/overlays/dialog), vectors T1-T10.
 * Uses the real base-ui dialog wrapped by components/dialog.tsx.
 */
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { useState } from 'react'
import { describe, it, expect } from 'vitest'
import {
  Dialog,
  DialogTrigger,
  DialogContent,
  DialogTitle,
  DialogDescription,
} from '../components/dialog'

function Sample({
  showClose,
  withTitle = true,
  rootProps = {},
}: {
  showClose?: boolean
  withTitle?: boolean
  rootProps?: Record<string, unknown>
}) {
  return (
    <Dialog {...rootProps}>
      <DialogTrigger>Open it</DialogTrigger>
      <DialogContent {...(showClose === undefined ? {} : { showClose })}>
        {withTitle && <DialogTitle>The title</DialogTitle>}
        {withTitle && <DialogDescription>The description</DialogDescription>}
        <button type="button">inside</button>
      </DialogContent>
    </Dialog>
  )
}

const openIt = async (): Promise<ReturnType<typeof userEvent.setup>> => {
  const user = userEvent.setup()
  await user.click(screen.getByText('Open it'))
  await screen.findByRole('dialog')
  return user
}

describe('Dialog conformance vectors', () => {
  it('T1 centered-modal: popup and backdrop carry the centering classes', async () => {
    render(<Sample />)
    await openIt()
    const popup = screen.getByRole('dialog')
    for (const c of ['fixed', 'top-1/2', 'left-1/2', '-translate-x-1/2', '-translate-y-1/2']) {
      expect(popup.classList.contains(c)).toBe(true)
    }
    const backdrop = document.querySelector('.bg-black\\/30')
    expect(backdrop).not.toBeNull()
    for (const c of ['fixed', 'inset-0', 'bg-black/30', 'backdrop-blur-sm']) {
      expect(backdrop!.classList.contains(c)).toBe(true)
    }
  })

  it('T2 backdrop-dismissal-disabled (default): clicking the backdrop leaves it open', async () => {
    render(<Sample />)
    const user = await openIt()
    const backdrop = document.querySelector('.bg-black\\/30') as HTMLElement
    await user.click(backdrop)
    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  it('T3 escape-closes (default): Escape closes the dialog', async () => {
    render(<Sample />)
    const user = await openIt()
    await user.keyboard('{Escape}')
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
  })

  it('T4 close-affordance (default): the close button renders by default', async () => {
    render(<Sample />)
    await openIt()
    expect(screen.getByRole('button', { name: 'Close' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Close' }).className).toContain('top-3.5')
    expect(screen.getByRole('button', { name: 'Close' }).className).toContain('right-3.5')
  })

  it('T4b close-affordance (activate): clicking the close button closes the dialog', async () => {
    render(<Sample />)
    const user = await openIt()
    await user.click(screen.getByRole('button', { name: 'Close' }))
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
  })

  it('T5 close-affordance (hidden): showClose={false} renders no close button', async () => {
    render(<Sample showClose={false} />)
    await openIt()
    expect(screen.queryByRole('button', { name: 'Close' })).toBeNull()
  })

  it('T6 focus-trap: focus moves into the dialog and returns to the trigger on close', async () => {
    render(<Sample />)
    const trigger = screen.getByText('Open it')
    const user = await openIt()
    const popup = screen.getByRole('dialog')
    await waitFor(() => expect(popup.contains(document.activeElement)).toBe(true))
    await user.tab()
    await user.tab()
    // Base UI parks focus on a visually hidden guard at the edge, never on the page behind.
    const active = document.activeElement as HTMLElement
    expect(popup.contains(active) || active.hasAttribute('data-type')).toBe(true)
    expect(active).not.toBe(trigger)
    await user.keyboard('{Escape}')
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
    await waitFor(() => expect(document.activeElement).toBe(trigger))
  })

  it('T7 dialog-labelling: aria-labelledby and aria-describedby resolve to title and description', async () => {
    render(<Sample />)
    await openIt()
    const popup = screen.getByRole('dialog')
    const labelId = popup.getAttribute('aria-labelledby')
    const descId = popup.getAttribute('aria-describedby')
    expect(labelId).toBeTruthy()
    expect(descId).toBeTruthy()
    expect(document.getElementById(labelId!)).toHaveTextContent('The title')
    expect(document.getElementById(descId!)).toHaveTextContent('The description')
  })

  it('T8 backdrop-dismissal-disabled (opt-in): disablePointerDismissal={false} lets a backdrop click close', async () => {
    render(<Sample rootProps={{ disablePointerDismissal: false }} />)
    await openIt()
    const backdrop = document.querySelector('.bg-black\\/30') as HTMLElement
    fireEvent.pointerDown(backdrop)
    fireEvent.mouseDown(backdrop)
    fireEvent.pointerUp(backdrop)
    fireEvent.mouseUp(backdrop)
    fireEvent.click(backdrop)
    await waitFor(() => expect(screen.queryByRole('dialog')).toBeNull())
  })

  it('T9 escape-overridable: a composing onOpenChange that cancels on Escape keeps it open', async () => {
    function Composed() {
      const [open, setOpen] = useState(false)
      return (
        <Dialog
          open={open}
          onOpenChange={(next, details) => {
            if (details.reason === 'escape-key') {
              details.cancel()
              return
            }
            setOpen(next)
          }}
        >
          <DialogTrigger>Open it</DialogTrigger>
          <DialogContent>
            <DialogTitle>The title</DialogTitle>
          </DialogContent>
        </Dialog>
      )
    }
    render(<Composed />)
    const user = await openIt()
    await user.keyboard('{Escape}')
    await new Promise((r) => setTimeout(r, 50))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  it('T10 dialog-labelling (missing title): no aria-labelledby without a DialogTitle', async () => {
    render(<Sample withTitle={false} />)
    await openIt()
    expect(screen.getByRole('dialog').hasAttribute('aria-labelledby')).toBe(false)
  })
})
