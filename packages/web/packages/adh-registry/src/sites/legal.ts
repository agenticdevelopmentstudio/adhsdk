import { siteProdUrl } from './registry'

/**
 * Where the family's legal text lives: one Privacy Policy and one Terms of Use, on the hub, at
 * permanent paths of their own. Every site's footer links these absolute URLs rather than a
 * `/privacy` or `/terms` of its own, so there is one address to give an app store, a payment
 * processor or an SMS carrier, and it never moves. The hub's pages at these paths render the
 * text and nothing else — no header, menu or footer — and the hub's old `/privacy` and `/terms`
 * redirect here.
 *
 * Paths and URLs both, because the hub mounts the pages by path and everyone else links the URL.
 */
export const PRIVACY_POLICY_PATH = '/privacy-policy'
export const TERMS_OF_USE_PATH = '/terms-of-use'

export const PRIVACY_POLICY_URL = siteProdUrl('hub', PRIVACY_POLICY_PATH)
export const TERMS_OF_USE_URL = siteProdUrl('hub', TERMS_OF_USE_PATH)
