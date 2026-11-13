'use client'

import { useEffect, useRef, type RefObject } from 'react'
import { createLens, type LensOptions } from './lens.js'

export interface UseTextLensOptions extends LensOptions {
  /** Selector for the text elements inside the container, e.g. `'.tag'`. */
  selector: string
  /** When false the lens is destroyed and the text sits at rest. Defaults to true. */
  enabled?: boolean
  /**
   * Milliseconds to wait before the FIRST sweep, to let the page settle before
   * anything starts moving. Re-enabling later starts immediately — the pause
   * belongs to the page arriving, and repeating it after every interaction
   * would read as the effect being broken rather than deferred.
   */
  startDelay?: number
}

/**
 * Run a {@link createLens} over the elements matching `selector` inside `ref`.
 *
 * The lens is built, started and destroyed by one effect, so `enabled` is the
 * whole of the API: flip it and the sweep stops and the glyphs return to rest,
 * with no second effect to keep in step with the first.
 */
export function useTextLens(
  containerRef: RefObject<HTMLElement | null>,
  options: UseTextLensOptions,
): void {
  const {
    selector,
    enabled = true,
    startDelay = 0,
    radius,
    duration,
    dwell,
    easing,
    scale,
    blur,
    fromColor,
    toColor,
    respectReducedMotion,
  } = options

  const swept = useRef(false)

  // Every option is destructured rather than depended on as one object: an
  // options literal is a fresh value each render, which would tear the lens
  // down and rebuild it on every keystroke elsewhere in the tree.
  useEffect(() => {
    const container = containerRef.current
    if (!container || !enabled) return

    const elements = [...container.querySelectorAll<HTMLElement>(selector)]
    if (elements.length === 0) return

    const lens = createLens(elements, {
      radius,
      duration,
      dwell,
      easing,
        scale,
      blur,
      fromColor,
      toColor,
      respectReducedMotion,
    })
    const timer = window.setTimeout(() => {
      swept.current = true
      lens.start()
    }, swept.current ? 0 : startDelay)

    return () => {
      window.clearTimeout(timer)
      lens.destroy()
    }
  }, [
    containerRef,
    selector,
    enabled,
    startDelay,
    radius,
    duration,
    dwell,
    easing,
    scale,
    blur,
    fromColor,
    toColor,
    respectReducedMotion,
  ])
}
