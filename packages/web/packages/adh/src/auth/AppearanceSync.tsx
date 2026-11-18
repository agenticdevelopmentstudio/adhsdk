'use client'

import { useEffect, useRef } from 'react'
import { reportUnexpectedAuthError, useAuth } from '@adh-sdk/auth'
import { authedJson } from '@adh-sdk/auth/client'
import { adoptAppearance, normalizeAppearance, resetAppearance } from '@adh-sdk/themes'
import {
  APPEARANCE_INCLUDE_URL,
  appearanceFromWire,
  type AccountAppearanceBody,
} from './appearanceWire'

/**
 * Makes the family's theming follow the PERSON, not the browser.
 *
 * Every adh site mounts this (it rides inside the shared AuthProvider — see wired-provider.tsx —
 * which is the one component they all mount and the only place `useAuth()` is guaranteed to
 * resolve). The rule it enforces is the whole feature:
 *
 *   signed in  → the colour mode + a11y prefs saved against the USER (GET /api/v1/account?include[]=appearance)
 *   signed out → no prefs to speak of, so follow the OPERATING SYSTEM (colour mode 'auto')
 *
 * It has to be a server round-trip rather than a cookie or localStorage: the ~45 brand sites live
 * on as many registrable domains, so nothing browser-local can cross from one to the next. What
 * localStorage still does is absorb the LATENCY — the pre-paint script (APPEARANCE_PREPAINT_SCRIPT,
 * emitted by AdhThemeStyle into every site's <head>) repaints from the cached copy before first
 * paint, and this component corrects it a moment later if the server disagrees. A first visit to a
 * new site has no cache, so it paints in the OS mode and then settles into the user's — one
 * correction, once per site, rather than a flash on every page.
 *
 * Sign-out CLEARS the cache, so the next person to use the browser starts from their OS setting
 * instead of inheriting a stranger's theme.
 */
export function AppearanceSync(): null {
  const { isAuthenticated, isLoading, user } = useAuth()
  // The identity the document is currently themed for: a user id, `null` for signed-out, and
  // `undefined` before anything has been applied. Keyed by id so SWITCHING accounts in one tab
  // re-fetches (the id changes) while a re-render for any other reason does not.
  const themedFor = useRef<string | null | undefined>(undefined)

  useEffect(() => {
    // Say nothing while auth is still resolving: the pre-paint script has already painted the
    // cached (or OS) mode, and guessing "signed out" here would flash a signed-in user's theme away
    // and back on every single page load.
    if (isLoading) return

    const identity = isAuthenticated ? (user?.id ?? null) : null
    if (themedFor.current === identity) return
    themedFor.current = identity

    if (!identity) {
      resetAppearance() // signed out ⇒ the OS setting, cache cleared
      return
    }

    let live = true
    authedJson<AccountAppearanceBody>(APPEARANCE_INCLUDE_URL)
      .then((account) => {
        const prefs = appearanceFromWire(account.appearance?.prefs)
        // `normalizeAppearance` merges onto the defaults and drops anything it doesn't recognize,
        // so a user who has never saved (the `{}` a fresh account gets back) lands on 'auto' — the
        // OS setting — and a row written by a newer client can't poison this one.
        if (live) adoptAppearance(normalizeAppearance(prefs))
      })
      .catch((err) => {
        // The prefs are cosmetic: if they can't be fetched, leave the document as the pre-paint
        // script painted it rather than yanking the user's theme out from under them. Reported, not
        // swallowed — a persistently failing appearance include is a real (if quiet) regression.
        // Through the auth gate, though, not straight to the reporter: a 4xx here is a session that
        // died (authedJson already tried the refresh, and it 401'd too), which AuthProvider handles
        // by signing out — not a bug. Reporting it unconditionally put every expired session in
        // GlitchTip as `AuthHttpError: invalid or expired token` (#246). Network errors and 5xx
        // still report, deduped per minute.
        if (!live) return
        themedFor.current = undefined // let a later render retry
        reportUnexpectedAuthError(err, { feature: 'appearance', step: 'fetchPrefs' })
      })
    return () => {
      live = false
    }
  }, [isAuthenticated, isLoading, user?.id])

  return null
}
