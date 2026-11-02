'use client'

import { useEffect } from 'react'
import { startPostHog } from './startPostHog'

/**
 * Starts the shared PostHog config for the page. Mount it once in a site's root layout;
 * it renders nothing. Inert until the site has a NEXT_PUBLIC_POSTHOG_KEY.
 */
export function PostHogAnalytics(): null {
  useEffect(() => {
    startPostHog()
  }, [])
  return null
}
