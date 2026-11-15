"use client"

import { Toast as ToastPrimitive } from "@base-ui/react/toast"
import { X } from "lucide-react"

import { cn } from "../lib/utils"

// Base UI toast. Wrap the app (or a subtree) in <ToastProvider>, render
// <Toaster/> once inside it, and call `useToast().add({ title, description })`
// from any descendant to enqueue a toast.
const ToastProvider = ToastPrimitive.Provider
const useToast = ToastPrimitive.useToastManager

function ToastList({ closeLabel }: { closeLabel: string }) {
  const { toasts } = ToastPrimitive.useToastManager()
  return toasts.map((toast) => (
    <ToastPrimitive.Root
      key={toast.id}
      toast={toast}
      className={cn(
        "relative flex flex-col gap-1 rounded-lg border border-apt-border bg-apt-surface-2 p-4 pe-11 text-sm shadow-lg outline-none",
        "transition-all motion-reduce:transition-none data-ending-style:opacity-0 data-starting-style:opacity-0",
      )}
    >
      <ToastPrimitive.Title className="text-sm font-medium text-apt-text" />
      <ToastPrimitive.Description className="text-sm text-apt-text-muted" />
      <ToastPrimitive.Close
        aria-label={closeLabel}
        // size-11 is a 44x44 hit area; the 16px icon sits centred in it, near where it sat before.
        className="absolute top-0 end-0 inline-flex size-11 items-center justify-center rounded-lg text-apt-text-muted transition-colors motion-reduce:transition-none outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40"
      >
        <X className="size-4" />
      </ToastPrimitive.Close>
    </ToastPrimitive.Root>
  ))
}

interface ToasterProps {
  /** Accessible label for each toast's close button; pass the caller's localized string. */
  closeLabel?: string
}

function Toaster({ closeLabel = "Close" }: ToasterProps = {}) {
  return (
    <ToastPrimitive.Portal>
      <ToastPrimitive.Viewport className="fixed end-4 bottom-4 z-50 flex w-80 max-w-[calc(100vw-2rem)] flex-col gap-2">
        <ToastList closeLabel={closeLabel} />
      </ToastPrimitive.Viewport>
    </ToastPrimitive.Portal>
  )
}

export { ToastProvider, Toaster, useToast }
export type { ToasterProps }
