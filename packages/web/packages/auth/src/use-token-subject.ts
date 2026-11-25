'use client'

import { useSyncExternalStore } from 'react'
import { onSessionChange, readTokenSubject } from './tokens'

function subscribe(onChange: () => void): () => void {
  const off = onSessionChange(onChange)
  // A sign-in or sign-out in ANOTHER tab of this origin writes the same storage key; `storage`
  // fires only in the tabs that did not write, which are exactly the ones `onSessionChange` misses.
  window.addEventListener('storage', onChange)
  return () => {
    off()
    window.removeEventListener('storage', onChange)
  }
}

const serverSnapshot = (): string | null => null

/**
 * The signed-in principal (`sub`) of the stored access token, or null signed out — kept current
 * across sign-in, sign-out and refresh ({@link onSessionChange}) and across tabs.
 *
 * PROVIDER-AGNOSTIC, which is why it exists beside `useAuth`: it reads the storage `authedJson`
 * sends from, so a shared component (the header's workspace menu feed) can gate an authed request
 * on sign-in under whatever auth context its host mounts — or none. Identity for gating and cache
 * scoping only, never for authorization (see {@link readTokenSubject}).
 *
 * Null on the server and on the hydrating render, then the stored subject.
 */
export function useTokenSubject(): string | null {
  return useSyncExternalStore(subscribe, readTokenSubject, serverSnapshot)
}
