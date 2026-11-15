"use client";

import * as React from "react";
import { ChevronRight } from "lucide-react";

import { cn } from "../lib/utils";

/**
 * A self-contained collapsible section: a clickable header row (with a rotating
 * chevron) that shows/hides its children. Themed with the family `apt-*` tokens.
 * Uncontrolled by default (`defaultOpen`); pass `open`/`onOpenChange` to control
 * it. The header can carry trailing content (`actions`) that does not toggle the
 * disclosure — useful for per-section buttons.
 */
export function Disclosure({
  title,
  subtitle,
  actions,
  defaultOpen = false,
  open: openProp,
  onOpenChange,
  className,
  headerClassName,
  children,
}: {
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  actions?: React.ReactNode;
  defaultOpen?: boolean;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  className?: string;
  headerClassName?: string;
  children: React.ReactNode;
}) {
  const [internalOpen, setInternalOpen] = React.useState(defaultOpen);
  const isControlled = openProp !== undefined;
  const open = isControlled ? openProp : internalOpen;
  const bodyId = React.useId();

  function toggle() {
    const next = !open;
    if (!isControlled) setInternalOpen(next);
    onOpenChange?.(next);
  }

  return (
    <div className={cn("rounded-lg border border-apt-border bg-apt-surface", className)}>
      <div className={cn("flex items-center gap-2 px-3 py-2", headerClassName)}>
        <button
          type="button"
          onClick={toggle}
          aria-expanded={open}
          aria-controls={open ? bodyId : undefined}
          className="flex min-w-0 flex-1 items-center gap-2 text-left outline-none focus-visible:ring-2 focus-visible:ring-apt-gold/40 rounded"
        >
          <ChevronRight
            className={cn(
              "size-4 shrink-0 text-apt-text-muted transition-transform motion-reduce:transition-none",
              // Collapsed, the chevron points toward the inline end: right in LTR,
              // left under dir="rtl". Open, it points down in both directions.
              open ? "rotate-90" : "rtl:rotate-180",
            )}
          />
          <span className="flex min-w-0 flex-col">
            <span className="truncate text-sm font-medium text-apt-text">{title}</span>
            {subtitle && (
              <span className="truncate text-xs text-apt-text-muted">{subtitle}</span>
            )}
          </span>
        </button>
        {actions && <div className="flex shrink-0 items-center gap-2">{actions}</div>}
      </div>
      {open && <div id={bodyId} className="border-t border-apt-border px-3 py-3">{children}</div>}
    </div>
  );
}
