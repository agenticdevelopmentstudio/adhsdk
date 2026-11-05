/**
 * Appearance preferences — the user's color mode + accessibility choices,
 * applied to the document via a class (`dark`) and `data-*` attributes that the
 * theme CSS keys off (see styles/accessibility.css + styles/color-mode-light.css).
 * Pure, framework-agnostic logic shared by the React hook (appearance-store.tsx)
 * and the pre-paint inline script (APPEARANCE_PREPAINT_SCRIPT) so there is one
 * source of truth for the storage key, the defaults, and the DOM mapping.
 *
 * "Default" / "auto" means *follow the system* (or the theme's own default) and
 * is represented by the absence of the attribute, so an unset preference leaves
 * the document pristine and the relevant `@media` query (prefers-color-scheme,
 * prefers-reduced-motion, prefers-contrast) takes over.
 */

export type ColorModePref = "auto" | "light" | "dark"
export type ReduceMotionPref = "auto" | "on" | "off"
export type ContrastPref = "default" | "high" | "extra-high"
export type TextSizePref = "default" | "small" | "large" | "extra-large"
export type SpacingPref = "compact" | "comfortable" | "spacious"

export interface AppearancePrefs {
  colorMode: ColorModePref
  reduceMotion: ReduceMotionPref
  contrast: ContrastPref
  textSize: TextSizePref
  spacing: SpacingPref
  focusOutlines: boolean
  underlineLinks: boolean
}

// The storage key, the pref lists and the pre-paint script live in a plain .mjs so a Vite
// config (plain Node, no TypeScript) can load them too — see appearance-prepaint.mjs.
import {
  APPEARANCE_PREPAINT_SCRIPT,
  APPEARANCE_STORAGE_KEY,
  BOOL_PREFS,
  ENUM_PREF_DEFAULTS,
} from "./appearance-prepaint.mjs"

export { APPEARANCE_PREPAINT_SCRIPT, APPEARANCE_STORAGE_KEY }

export const APPEARANCE_DEFAULTS: AppearancePrefs = {
  colorMode: "auto",
  reduceMotion: "auto",
  contrast: "default",
  textSize: "default",
  spacing: "compact",
  focusOutlines: false,
  underlineLinks: false,
}

/** Merge a possibly-partial / untrusted stored object onto the defaults. */
export function normalizeAppearance(raw: unknown): AppearancePrefs {
  const next = { ...APPEARANCE_DEFAULTS }
  if (!raw || typeof raw !== "object") return next
  const r = raw as Record<string, unknown>
  if (r.colorMode === "light" || r.colorMode === "dark" || r.colorMode === "auto")
    next.colorMode = r.colorMode
  if (r.reduceMotion === "on" || r.reduceMotion === "off" || r.reduceMotion === "auto")
    next.reduceMotion = r.reduceMotion
  if (r.contrast === "high" || r.contrast === "extra-high" || r.contrast === "default")
    next.contrast = r.contrast
  if (
    r.textSize === "small" ||
    r.textSize === "large" ||
    r.textSize === "extra-large" ||
    r.textSize === "default"
  )
    next.textSize = r.textSize
  if (r.spacing === "comfortable" || r.spacing === "spacious" || r.spacing === "compact")
    next.spacing = r.spacing
  if (typeof r.focusOutlines === "boolean") next.focusOutlines = r.focusOutlines
  if (typeof r.underlineLinks === "boolean") next.underlineLinks = r.underlineLinks
  return next
}

export function readStoredAppearance(): AppearancePrefs {
  if (typeof window === "undefined") return { ...APPEARANCE_DEFAULTS }
  try {
    const raw = window.localStorage.getItem(APPEARANCE_STORAGE_KEY)
    return normalizeAppearance(raw ? JSON.parse(raw) : null)
  } catch {
    return { ...APPEARANCE_DEFAULTS }
  }
}

export function writeStoredAppearance(prefs: AppearancePrefs): void {
  if (typeof window === "undefined") return
  try {
    window.localStorage.setItem(APPEARANCE_STORAGE_KEY, JSON.stringify(prefs))
  } catch {
    /* ignore (private mode / quota) */
  }
}

/** Drop this browser's cached prefs — see `resetAppearance` (sign-out): the cache belongs to
 *  whoever was signed in, so it must not outlive their session on a shared browser. */
export function clearStoredAppearance(): void {
  if (typeof window === "undefined") return
  try {
    window.localStorage.removeItem(APPEARANCE_STORAGE_KEY)
  } catch {
    /* ignore (private mode) */
  }
}

/**
 * Apply the preferences to a document element. Non-default values set a `data-*`
 * attribute (or the `dark` class for color mode); default/"auto" values remove
 * it so the matching `@media` query governs. `systemPrefersDark` is passed in so
 * both the hook and the pre-paint script can resolve `auto` color mode without
 * each re-reading matchMedia.
 *
 * Colour mode is honoured in EVERY environment, production included. It used to be
 * pinned dark outside local/staging/testing, back when light was an unfinished
 * preview and only the hub could even express a preference; now every site reads
 * the signed-in user's saved mode (and the OS setting when signed out), so a
 * production lock would mean the setting silently did nothing where it matters most.
 */
export function applyAppearance(
  el: HTMLElement,
  prefs: AppearancePrefs,
  systemPrefersDark: boolean,
): void {
  const wantDark = prefs.colorMode === "auto" ? systemPrefersDark : prefs.colorMode === "dark"
  el.classList.toggle("dark", wantDark)
  el.dataset.colorMode = prefs.colorMode

  for (const key of Object.keys(ENUM_PREF_DEFAULTS) as (keyof typeof ENUM_PREF_DEFAULTS)[]) {
    const value = prefs[key]
    setOrRemove(el, key, value === ENUM_PREF_DEFAULTS[key] ? null : value)
  }
  for (const key of BOOL_PREFS) {
    setOrRemove(el, key, prefs[key] ? "always" : null)
  }
}

/**
 * Take the preferences off a document element again: the `dark` class, `data-color-mode`, and
 * every attribute applyAppearance (or the pre-paint script) may have set, from the SAME lists.
 * For a site that mounts the preferences on only some of its routes — a client navigation
 * keeps the same <html>, so without this they would follow the reader onto a page that never
 * asked for them.
 */
export function clearAppearance(el: HTMLElement): void {
  el.classList.remove("dark")
  delete el.dataset.colorMode
  for (const key of [...Object.keys(ENUM_PREF_DEFAULTS), ...BOOL_PREFS]) {
    setOrRemove(el, key, null)
  }
}

function setOrRemove(el: HTMLElement, dataKey: string, value: string | null): void {
  if (value === null) delete el.dataset[dataKey]
  else el.dataset[dataKey] = value
}

