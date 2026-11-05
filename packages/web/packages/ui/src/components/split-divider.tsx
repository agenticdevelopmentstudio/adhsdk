"use client"

import * as React from "react"

import { cn } from "../lib/utils"

/**
 * The bare split-SEPARATOR primitive: a draggable + keyboard-operable
 * `role="separator"` that reports a new RATIO (0…1, the fraction of the split given to
 * the pane BEFORE it — above for a horizontal separator, to the left for a vertical
 * one). It owns NO panes and NO collapse state — the caller renders the regions and
 * applies the ratio (e.g. @adh-sdk/search's result-list / preview-dock stack,
 * or @adh-sdk/shipr's repository-tree / activity-log pair).
 *
 * **`orientation` is the SEPARATOR's own**, which is how `aria-orientation` defines it
 * and the opposite of how people usually say it out loud: a `"vertical"` separator is a
 * vertical line, so it splits the space LEFT/RIGHT. Everything else follows from it —
 * which axis a drag is measured on, which arrow keys move it, and which way the two
 * step buttons point. The default is `"horizontal"` (top/bottom), which is what this
 * primitive did when it had no choice.
 *
 * Relationship to {@link ResizableSplit}: ResizableSplit is the MANAGED two-pane
 * composite (it owns its top/bottom regions, localStorage persistence, and a
 * bottom-pane collapse toggle); SplitDivider is the underlying separator affordance
 * for callers that need to own their own layout and collapse semantics. Unifying
 * ResizableSplit on top of this primitive is future work — and ResizableSplit is still
 * top/bottom only, so a left/right split is this primitive's job today.
 *
 * Accessibility: `role="separator"` with `aria-orientation` matching the prop and
 * `aria-valuenow/min/max` (percent of the split given to the leading pane),
 * `tabIndex={0}`, and ArrowUp/ArrowDown (horizontal) or ArrowLeft/ArrowRight
 * (vertical) for ± step, plus Home/End (min/max) in both. Pointer drag is tracked
 * against the container rect via pointer capture; a lost/cancelled capture or a move
 * with the primary button already released ends the drag (no resize-with-button-up).
 * The step buttons are a single-pointer, NON-drag resize alternative (WCAG 2.2 SC
 * 2.5.7, Dragging Movements). The whole row/column is 24px across — the drag target
 * and the 24px step buttons are fully contained (WCAG 2.2 SC 2.5.8, Target Size,
 * Minimum) with no bleed into adjacent panes. apt-* tokens only.
 */
export interface SplitDividerProps {
  /** Current leading-pane ratio (0…1) — the fraction of the split above (horizontal) or
   *  left of (vertical) the divider. */
  ratio: number
  /** Report a new (clamped to min/max) ratio. */
  onRatioChange: (ratio: number) => void
  /** Min leading-pane ratio (default 0.2). */
  minRatio?: number
  /** Max leading-pane ratio (default 0.8). */
  maxRatio?: number
  /** Keyboard/step-button step per press (default 0.03). */
  step?: number
  /** The split container to measure pointer drags against. */
  containerRef: React.RefObject<HTMLElement | null>
  /**
   * The SEPARATOR's orientation, per `aria-orientation` (default `"horizontal"`):
   * `"horizontal"` is a horizontal line splitting top/bottom, `"vertical"` is a
   * vertical line splitting left/right.
   */
  orientation?: "horizontal" | "vertical"
  /** Accessible label for the separator. */
  label?: string
  /** Accessible label for the step button that SHRINKS the leading pane — the ▲ of a
   *  horizontal split, the ◀ of a vertical one. Defaults per orientation. */
  growBottomLabel?: string
  /** Accessible label for the step button that GROWS the leading pane — the ▼ of a
   *  horizontal split, the ▶ of a vertical one. Defaults per orientation. */
  growTopLabel?: string
  /** Extra classes on the root row/column. */
  className?: string
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value))
}

export function SplitDivider({
  ratio,
  onRatioChange,
  minRatio = 0.2,
  maxRatio = 0.8,
  step = 0.03,
  containerRef,
  orientation = "horizontal",
  label = "Resize split",
  growBottomLabel,
  growTopLabel,
  className,
}: SplitDividerProps): React.ReactElement {
  const vertical = orientation === "vertical"
  const shrinkLabel = growBottomLabel ?? (vertical ? "Grow right pane" : "Grow bottom pane")
  const growLabel = growTopLabel ?? (vertical ? "Grow left pane" : "Grow top pane")
  const dragging = React.useRef(false)

  const commit = React.useCallback(
    (next: number): void => onRatioChange(clamp(next, minRatio, maxRatio)),
    [onRatioChange, minRatio, maxRatio],
  )

  const onPointerDown = React.useCallback(
    (event: React.PointerEvent<HTMLDivElement>): void => {
      dragging.current = true
      event.currentTarget.setPointerCapture?.(event.pointerId)
    },
    [],
  )

  const onPointerMove = React.useCallback(
    (event: React.PointerEvent<HTMLDivElement>): void => {
      if (!dragging.current) return
      // Robustness: if the primary button is no longer down (the pointerup landed
      // elsewhere, or capture was silently dropped), END the drag instead of
      // resizing with the button up.
      if ((event.buttons & 1) === 0) {
        dragging.current = false
        return
      }
      const rect = containerRef.current?.getBoundingClientRect()
      if (!rect) return
      // The measured axis is the one the separator TRAVELS along, which is the one it is
      // not drawn on. A zero extent means the container has not been laid out yet, and
      // dividing by it would pin the ratio to a NaN that no later drag recovers from.
      const extent = vertical ? rect.width : rect.height
      if (extent === 0) return
      const offset = vertical ? event.clientX - rect.left : event.clientY - rect.top
      commit(offset / extent)
    },
    [commit, containerRef, vertical],
  )

  const onPointerUp = React.useCallback(
    (event: React.PointerEvent<HTMLDivElement>): void => {
      dragging.current = false
      event.currentTarget.releasePointerCapture?.(event.pointerId)
    },
    [],
  )

  // A cancelled gesture (touch scroll takeover, window blur…) or lost capture must
  // end the drag too — otherwise the next stray pointermove resumes resizing.
  const onPointerAbort = React.useCallback((): void => {
    dragging.current = false
  }, [])

  const onKeyDown = React.useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>): void => {
      // The arrow pair is the one that points ALONG the axis the separator travels; the
      // other pair is deliberately left alone, so it still does whatever it would do
      // over any other focusable element.
      const shrink = vertical ? "ArrowLeft" : "ArrowUp"
      const grow = vertical ? "ArrowRight" : "ArrowDown"
      switch (event.key) {
        case shrink:
          event.preventDefault()
          commit(ratio - step)
          break
        case grow:
          event.preventDefault()
          commit(ratio + step)
          break
        case "Home":
          event.preventDefault()
          commit(minRatio)
          break
        case "End":
          event.preventDefault()
          commit(maxRatio)
          break
      }
    },
    [commit, ratio, step, minRatio, maxRatio, vertical],
  )

  const shrinkLeading = React.useCallback(
    (): void => commit(ratio - step),
    [commit, ratio, step],
  )
  const growLeading = React.useCallback(
    (): void => commit(ratio + step),
    [commit, ratio, step],
  )

  return (
    // The row/column is 24px across (h-6 / w-6): the WHOLE of it is the drag target
    // (≥24 CSS px, WCAG 2.2 SC 2.5.8) with the thin visual line centred in it, and the
    // 24px step buttons are fully contained — nothing bleeds into the adjacent panes.
    <div
      className={cn(
        "relative flex shrink-0 items-center",
        vertical ? "h-full w-6 flex-col" : "h-6 w-full",
        className,
      )}
    >
      <div
        role="separator"
        aria-orientation={orientation}
        aria-label={label}
        aria-valuenow={Math.round(ratio * 100)}
        aria-valuemin={Math.round(minRatio * 100)}
        aria-valuemax={Math.round(maxRatio * 100)}
        tabIndex={0}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerAbort}
        onLostPointerCapture={onPointerAbort}
        onKeyDown={onKeyDown}
        className={cn(
          "group flex h-full w-full touch-none select-none items-center justify-center rounded-sm outline-none focus-visible:ring-2 focus-visible:ring-apt-gold/40",
          vertical ? "cursor-col-resize" : "cursor-row-resize",
        )}
      >
        {/* The thin visual line, centred in the 24px grab row/column. */}
        <span
          aria-hidden
          className={cn(
            "pointer-events-none rounded-full bg-apt-border transition-colors group-hover:bg-apt-border-strong group-focus-visible:bg-apt-border-strong",
            vertical ? "h-full w-[3px]" : "h-[3px] w-full",
          )}
        />
      </div>
      {/* WCAG 2.2 SC 2.5.7 (Dragging Movements): a single-pointer, NON-drag resize
          alternative — step buttons nudge the split by one step on click/tap, so a
          pointer user who can't perform a sustained drag can still resize. They are
          SIBLINGS of the separator (a button inside role="separator" would be invalid
          ARIA), sized 24px to also meet SC 2.5.8, and fully contained in the 24px row. */}
      <div
        className={cn(
          "pointer-events-none absolute z-10 flex items-center gap-2",
          vertical ? "inset-x-0 bottom-1 flex-col" : "inset-y-0 right-1",
        )}
      >
        <button
          type="button"
          aria-label={shrinkLabel}
          onClick={shrinkLeading}
          className="pointer-events-auto flex size-6 items-center justify-center rounded text-[10px] leading-none text-apt-text-muted outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40"
        >
          <span aria-hidden>{vertical ? "◀" : "▲"}</span>
        </button>
        <button
          type="button"
          aria-label={growLabel}
          onClick={growLeading}
          className="pointer-events-auto flex size-6 items-center justify-center rounded text-[10px] leading-none text-apt-text-muted outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40"
        >
          <span aria-hidden>{vertical ? "▶" : "▼"}</span>
        </button>
      </div>
    </div>
  )
}
