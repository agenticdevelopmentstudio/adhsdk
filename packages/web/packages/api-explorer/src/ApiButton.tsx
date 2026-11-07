'use client'

import { Suspense, lazy, useState } from 'react'
import { Code2, Loader2 } from 'lucide-react'
import { Button } from '@adh-sdk/ui/components/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@adh-sdk/ui/components/dialog'
import type { ApiBrowserProps } from './ApiBrowser'

// Lazy: the browser pulls in the generated metadata + shiki. Splitting it here
// keeps that payload out of the host page until the user opens it.
const ApiBrowser = lazy(() => import('./ApiBrowser').then((m) => ({ default: m.ApiBrowser })))

export interface ApiButtonProps extends ApiBrowserProps {
  /** Button label. Defaults to "API". */
  label?: string
  /** Button variant — defaults to a subtle outline. */
  variant?: React.ComponentProps<typeof Button>['variant']
  size?: React.ComponentProps<typeof Button>['size']
  buttonClassName?: string
  /** Dialog heading; defaults to "API reference". */
  title?: string
  /** What the host page says about these endpoints, shown under the heading, above the browser. */
  intro?: React.ReactNode
}

/**
 * The "API" affordance: a small button that opens the full {@link ApiBrowser} in a
 * large centered modal, focused on the given endpoint. Drop it next to whatever a
 * user is configuring.
 */
export function ApiButton({
  label = 'API',
  variant = 'outline',
  size = 'xs',
  buttonClassName,
  title,
  intro,
  ...browserProps
}: ApiButtonProps) {
  const [open, setOpen] = useState(false)

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <Button type="button" variant={variant} size={size} onClick={() => setOpen(true)} className={buttonClassName}>
        <Code2 size={14} aria-hidden />
        {label}
      </Button>
      {/* Near-fullscreen — a big browser element, only a thin margin to the window
          edge. The browser scrolls internally, not the modal. */}
      <DialogContent className="flex h-[96vh] w-[98vw] max-w-none flex-col gap-0 overflow-hidden p-0">
        <DialogHeader className="shrink-0 border-b border-apt-border px-5 py-4">
          <DialogTitle>{title ?? 'API reference'}</DialogTitle>
          <DialogDescription>
            {/* Nothing here about highlighted endpoints: only the browser knows whether any matched,
                and it says so itself. */}
            {browserProps.readOnly ? 'Browse the API.' : 'Browse the API and try any endpoint, authenticated as you.'}
          </DialogDescription>
          {intro ? (
            <div className="mt-2 flex max-h-40 flex-col gap-2 overflow-y-auto text-sm text-apt-text" data-testid="api-intro">
              {intro}
            </div>
          ) : null}
        </DialogHeader>
        <div className="min-h-0 flex-1 overflow-hidden">
          {open && (
            <Suspense
              fallback={
                <div className="flex items-center gap-2 p-6 text-sm text-apt-text-muted">
                  <Loader2 size={16} className="animate-spin" aria-hidden /> Loading API…
                </div>
              }
            >
              <ApiBrowser {...browserProps} />
            </Suspense>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
