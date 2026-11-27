export interface AuthRuntimeConfig {
  /** localStorage key holding the serialized AuthTokens bundle (per site). */
  storageKey: string
  /**
   * Relative path for the cookie-first refresh call. Same-origin by design and never resolved
   * through `apiUrl`: the refresh token is an HttpOnly cookie on this site's own origin, which a
   * cross-origin call to a configured API base would neither send nor receive. So this storage
   * session (AuthProvider's) needs a site with an `/api` rewrite, or a `refreshPath` the site
   * serves itself. A host with a configured API base and no rewrite (the product site) installs
   * an in-memory token source instead (ProductAdminAuthProvider, refreshing through its own
   * `<authBase>/session`), and `refreshAccessToken` then never calls this path.
   */
  refreshPath: string
}

let config: AuthRuntimeConfig = {
  storageKey: 'auth_tokens',
  refreshPath: '/api/v1/auth/sessions/refresh',
}

export function configureAuth(partial: Partial<AuthRuntimeConfig>): void {
  config = { ...config, ...partial }
}

export function authConfig(): AuthRuntimeConfig {
  return config
}
