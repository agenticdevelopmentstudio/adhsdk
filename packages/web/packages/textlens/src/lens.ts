import { resolveColor, type Rgb } from './color.js'

/** Tuning for a single lens. Every field has a usable default except the colours. */
export interface LensOptions {
  /** Half-width of the lens, in CSS pixels. Glyphs outside it are untouched. */
  radius?: number
  /** Milliseconds for one pass across the text. The return trip takes the same. */
  duration?: number
  /**
   * Milliseconds the lens holds still at each end, fully off the text, before
   * it turns back. `0` (the default) turns it round the instant it arrives.
   */
  dwell?: number
  /**
   * How the lens moves along a pass. `'cubic'` (the default) eases in and out,
   * slowing at each end — which happens off the text, so a lens that eases
   * spends the first and last stretch of every pass crawling where nothing
   * shows. `'linear'` crosses at one speed, so off the text it is gone at once
   * and the only pause is the `dwell`.
   */
  easing?: 'cubic' | 'linear'
  /** Extra scale at the centre of the lens — `0.25` means 125%. */
  scale?: number
  /** Blur in pixels at the centre of the lens. `0` disables it. */
  blur?: number
  /**
   * The colour a glyph has at rest, and the colour it reaches dead centre.
   * Either may be a CSS custom property name (`--text-muted`), which is read
   * off the element so the ramp lives in the stylesheet rather than here.
   * Give both to tint, or neither to leave colour alone.
   */
  fromColor?: string
  toColor?: string
  /** When true (the default), `prefers-reduced-motion: reduce` makes `start` a no-op. */
  respectReducedMotion?: boolean
}

/** A lens bound to a set of elements. Create it once, then start and stop freely. */
export interface Lens {
  /** Begin sweeping. Re-measures first, so it is safe to call after a reflow. */
  start(): void
  /** Stop sweeping and return every glyph to rest. */
  stop(): void
  /** Stop, and release the listeners this lens attached. */
  destroy(): void
}

interface Char {
  el: HTMLSpanElement
  cx: number
}

const DEFAULT_RADIUS = 55
const DEFAULT_DURATION = 8000
const DEFAULT_SCALE = 0.25
const DEFAULT_BLUR = 0.35

const SPLIT_FLAG = 'textlensSplit'

/**
 * Replace each element's text with one inline-block span per character.
 *
 * No span is given a width. The sweep only transforms and filters a glyph, and
 * neither moves layout, so each span's natural width is already the frozen one.
 * Measuring here and writing it back was worse than useless: the split runs in
 * a mount effect, and a row with no layout at that instant (a cold load, a
 * hidden tab) measured every glyph at 0px and pinned them there, stacking each
 * label's letters into one smudge.
 *
 * This is destructive and deliberately one-way: the split is left in place when
 * the lens is destroyed. Re-splitting on every start would re-measure every
 * glyph and visibly jitter the line, and these elements are short static labels.
 * The flag makes it idempotent, so overlapping lenses are harmless.
 */
function splitIntoChars(elements: readonly HTMLElement[]): void {
  for (const element of elements) {
    if (element.dataset[SPLIT_FLAG]) continue

    const text = element.textContent ?? ''
    element.textContent = ''

    const spans: HTMLSpanElement[] = []
    for (const character of text) {
      const span = document.createElement('span')
      // A plain space would collapse once each glyph is its own inline-block.
      span.textContent = character === ' ' ? '\u00A0' : character
      span.style.display = 'inline-block'
      element.appendChild(span)
      spans.push(span)
    }

    for (const span of spans) {
      span.style.willChange = 'transform, color, filter'
    }

    element.dataset[SPLIT_FLAG] = '1'
  }
}

function measureChars(elements: readonly HTMLElement[]): Char[] {
  const chars: Char[] = []
  for (const element of elements) {
    for (const span of element.querySelectorAll('span')) {
      const rect = span.getBoundingClientRect()
      chars.push({ el: span, cx: rect.left + rect.width / 2 })
    }
  }
  return chars
}

function restChars(chars: readonly Char[]): void {
  for (const { el } of chars) {
    el.style.transform = ''
    el.style.color = ''
    el.style.filter = ''
  }
}

function prefersReducedMotion(): boolean {
  return typeof window.matchMedia === 'function'
    ? window.matchMedia('(prefers-reduced-motion: reduce)').matches
    : false
}

function resolveRamp(
  options: LensOptions,
  element: Element,
): { from: Rgb; to: Rgb } | null {
  const { fromColor, toColor } = options
  if (fromColor === undefined && toColor === undefined) return null
  if (fromColor === undefined || toColor === undefined) {
    throw new Error('textlens: fromColor and toColor go together — give both, or neither.')
  }
  return { from: resolveColor(fromColor, element), to: resolveColor(toColor, element) }
}

/**
 * Bind a lens to `elements`.
 *
 * Each lens owns its own animation frame and its own state; nothing is shared
 * between them. Two lenses over the same text will both run and fight over the
 * inline styles, so a caller that wants one at a time says so by only starting
 * one at a time — the alternative, a module-level "active lens", makes that
 * decision invisibly and from the wrong place.
 */
export function createLens(elements: readonly HTMLElement[], options: LensOptions = {}): Lens {
  const radius = options.radius ?? DEFAULT_RADIUS
  const duration = options.duration ?? DEFAULT_DURATION
  const dwell = options.dwell ?? 0
  const easing = options.easing ?? 'cubic'
  const scaleDepth = options.scale ?? DEFAULT_SCALE
  const blurDepth = options.blur ?? DEFAULT_BLUR
  const respectReducedMotion = options.respectReducedMotion ?? true

  const targets = [...elements]
  splitIntoChars(targets)

  let chars: Char[] = []
  let ramp: { from: Rgb; to: Rgb } | null = null
  let frameId: number | null = null
  let running = false
  let paused = false

  // The lens holding still under the pointer: the glyph you are reading should
  // not be swelling and blurring while you decide whether to click it.
  const pause = (): void => {
    paused = true
  }
  const resume = (): void => {
    paused = false
  }
  for (const element of targets) {
    element.addEventListener('pointerenter', pause)
    element.addEventListener('pointerleave', resume)
  }

  function apply(centre: number): void {
    for (const { el, cx } of chars) {
      const distance = Math.abs(cx - centre)
      if (distance > radius) {
        el.style.transform = ''
        el.style.color = ''
        el.style.filter = ''
        continue
      }

      // Smoothstep, so a glyph eases into the lens instead of snapping at the edge.
      const linear = 1 - distance / radius
      const t = linear * linear * (3 - 2 * linear)

      el.style.transform = `scale(${(1 + t * scaleDepth).toFixed(3)})`
      const blur = t * blurDepth
      el.style.filter = blur > 0.03 ? `blur(${blur.toFixed(2)}px)` : ''
      if (ramp) {
        const [fr, fg, fb] = ramp.from
        const [tr, tg, tb] = ramp.to
        const r = Math.round(fr + (tr - fr) * t)
        const g = Math.round(fg + (tg - fg) * t)
        const b = Math.round(fb + (tb - fb) * t)
        el.style.color = `rgb(${r},${g},${b})`
      }
    }
  }

  function stop(): void {
    running = false
    paused = false
    if (frameId !== null) {
      cancelAnimationFrame(frameId)
      frameId = null
    }
    restChars(chars)
  }

  function start(): void {
    if (running) return
    if (respectReducedMotion && prefersReducedMotion()) return

    // Re-measure every start: the text may have wrapped, scrolled or reflowed
    // since the last one, and stale centres put the lens over the wrong glyphs.
    chars = measureChars(targets)
    const first = chars[0]
    const last = chars[chars.length - 1]
    if (!first || !last) return

    ramp = resolveRamp(options, first.el)

    const leftEdge = first.cx - radius
    const rightEdge = last.cx + radius
    const span = rightEdge - leftEdge
    const startedAt = performance.now()

    running = true

    const step = (now: number): void => {
      if (!running) return
      frameId = requestAnimationFrame(step)

      if (paused) {
        restChars(chars)
        return
      }

      // Each leg is one pass of `duration` followed by a hold of `dwell` at the
      // far end, where progress stays pinned at 1.
      const elapsed = now - startedAt
      const legLength = duration + dwell
      const leg = Math.floor(elapsed / legLength)
      const progress = Math.min((elapsed % legLength) / duration, 1)

      // Cubic ease in/out, so the lens slows at each end rather than bouncing.
      const eased =
        easing === 'linear'
          ? progress
          : progress < 0.5
            ? 4 * progress * progress * progress
            : 1 - Math.pow(-2 * progress + 2, 3) / 2

      // Even legs travel left to right, odd legs come back.
      apply(leg % 2 === 0 ? leftEdge + eased * span : rightEdge - eased * span)
    }

    frameId = requestAnimationFrame(step)
  }

  function destroy(): void {
    stop()
    for (const element of targets) {
      element.removeEventListener('pointerenter', pause)
      element.removeEventListener('pointerleave', resume)
    }
  }

  return { start, stop, destroy }
}
