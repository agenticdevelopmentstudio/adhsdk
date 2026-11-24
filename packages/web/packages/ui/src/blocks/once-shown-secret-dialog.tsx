"use client"

import { useState, type ReactNode } from "react"

import { AlertModal } from "../components/alert-modal"
import { Button } from "../components/button"
import { CopyButton } from "../components/copy-button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "../components/dialog"
import { Input } from "../components/input"

export interface OnceShownSecretDialogProps {
  /** The raw value, or null when there is nothing to show (the dialog is closed). */
  secret: string | null
  title: string
  /** What the secret is for and where it goes. "It won't be shown again" is said for you. */
  description?: ReactNode
  /** Names the field and its copy button ("Trigger secret" reads "Copy trigger secret"). */
  label: string
  /** Called once the person has closed it: by Done, or by confirming a close without copying. */
  onClose: () => void
}

/**
 * A secret the backend returns once (an inbound trigger's secret, a machine's token): shown with a
 * copy button. Closing it before it was copied (Done, Escape or a click outside) asks first,
 * because a value dropped here can never be shown again; once copied, it closes without asking.
 * The same reveal the worker token form has inline, as a dialog of its own.
 */
export function OnceShownSecretDialog({
  secret,
  title,
  description,
  label,
  onClose,
}: OnceShownSecretDialogProps) {
  const [copied, setCopied] = useState(false)
  const [confirmingDrop, setConfirmingDrop] = useState(false)

  const close = () => {
    setCopied(false)
    setConfirmingDrop(false)
    onClose()
  }
  const requestClose = () => {
    if (copied) close()
    else setConfirmingDrop(true)
  }

  return (
    <Dialog open={secret !== null} onOpenChange={(open) => !open && requestClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>
            Copy it now; it won&apos;t be shown again.{description ? <> {description}</> : null}
          </DialogDescription>
        </DialogHeader>
        <div className="flex flex-col gap-4">
          <div className="flex items-center gap-2">
            <Input
              aria-label={label}
              readOnly
              value={secret ?? ""}
              className="font-mono text-xs"
              onFocus={(e) => e.currentTarget.select()}
              onCopy={() => setCopied(true)}
            />
            {/* CopyButton takes no click handler; the capture marks the copy without wrapping it. */}
            <span className="contents" onClickCapture={() => setCopied(true)}>
              <CopyButton label={`Copy ${label.toLowerCase()}`} getText={() => secret ?? ""} />
            </span>
          </div>
          <DialogFooter>
            <Button type="button" size="sm" onClick={requestClose}>
              Done
            </Button>
          </DialogFooter>
        </div>
        <AlertModal
          open={confirmingDrop}
          tone="error"
          title="Close without copying?"
          description="This won't be shown again. If you haven't copied it, you will have to make a new one."
          confirmLabel="Close"
          cancelLabel="Keep open"
          onConfirm={close}
          onCancel={() => setConfirmingDrop(false)}
        />
      </DialogContent>
    </Dialog>
  )
}
