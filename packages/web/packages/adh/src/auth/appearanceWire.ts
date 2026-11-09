import type { AppearancePrefs } from '@adh-sdk/themes'

/**
 * The /v1 wire form of the appearance preferences, in both directions.
 *
 * The account object folds them in as an include: `GET /api/v1/account?include[]=appearance`
 * answers `{object:'account', ..., appearance: {prefs: {color_mode, ...}}}`, and
 * `POST /api/v1/account` takes `{appearance: {color_mode, ...}}`. Both are snake_case; the
 * toolkit's `AppearancePrefs` is camelCase, so the keys are mapped one by one here (the set is
 * closed, so there is no generic converter to get a key wrong).
 */
export const APPEARANCE_INCLUDE_URL = '/api/v1/account?include[]=appearance'
export const APPEARANCE_WRITE_URL = '/api/v1/account'

export interface AppearanceWire {
  color_mode?: AppearancePrefs['colorMode']
  reduce_motion?: AppearancePrefs['reduceMotion']
  contrast?: AppearancePrefs['contrast']
  text_size?: AppearancePrefs['textSize']
  spacing?: AppearancePrefs['spacing']
  focus_outlines?: AppearancePrefs['focusOutlines']
  underline_links?: AppearancePrefs['underlineLinks']
}

/** The body of `GET /api/v1/account?include[]=appearance` (only the part read here). */
export interface AccountAppearanceBody {
  appearance?: { prefs?: AppearanceWire }
}

/** Wire -> camelCase prefs; absent keys stay absent so `normalizeAppearance` can default them. */
export function appearanceFromWire(wire: AppearanceWire | undefined): Partial<AppearancePrefs> {
  const w = wire ?? {}
  const out: Partial<AppearancePrefs> = {}
  if (w.color_mode !== undefined) out.colorMode = w.color_mode
  if (w.reduce_motion !== undefined) out.reduceMotion = w.reduce_motion
  if (w.contrast !== undefined) out.contrast = w.contrast
  if (w.text_size !== undefined) out.textSize = w.text_size
  if (w.spacing !== undefined) out.spacing = w.spacing
  if (w.focus_outlines !== undefined) out.focusOutlines = w.focus_outlines
  if (w.underline_links !== undefined) out.underlineLinks = w.underline_links
  return out
}

/** camelCase prefs -> the snake_case wire object. */
export function appearanceToWire(prefs: AppearancePrefs): AppearanceWire {
  return {
    color_mode: prefs.colorMode,
    reduce_motion: prefs.reduceMotion,
    contrast: prefs.contrast,
    text_size: prefs.textSize,
    spacing: prefs.spacing,
    focus_outlines: prefs.focusOutlines,
    underline_links: prefs.underlineLinks,
  }
}
