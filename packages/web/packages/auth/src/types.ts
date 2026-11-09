export interface AuthTokens {
  accessToken: string
  refreshToken: string
}

// authMethods/attributes are returned by the backend but not read by either
// site; typed as open records to avoid guessing field names we don't consume.
export type UserAuthMethod = Record<string, unknown>
export type UserAttribute = Record<string, unknown>

/** Canonical user from the temporal backend (`shared/model/User.kt`). */
export interface AuthUser {
  id: string
  email: string
  name: string
  avatarUrl: string
  /** The user's public profile slug — backend-persisted (PATCH /auth/me) and returned by
   *  GET /auth/me since the customer identity gained public profiles; optional so user
   *  objects cached in storage before this field was typed stay valid. */
  slug?: string | null
  capabilities: string[]
  authMethods: UserAuthMethod[]
  attributes: UserAttribute[]
}

export function hasCapability(user: Pick<AuthUser, 'capabilities'> | null | undefined, capability: string): boolean {
  return !!user?.capabilities?.includes(capability)
}

export function isAdmin(user: Pick<AuthUser, 'capabilities'> | null | undefined): boolean {
  return hasCapability(user, 'admin')
}

/** The /v1 `User` object — what `GET /v1/account` and the session responses carry. */
export interface V1User {
  id: string
  email: string
  name: string
  avatar_url?: string | null
  slug?: string | null
  capabilities?: string[]
}

/** A /v1 user as the site's {@link AuthUser}. /v1 does not carry `authMethods` or
 *  `attributes` (neither site reads them), so they are empty rather than guessed. */
export function userFromV1(raw: V1User): AuthUser {
  return {
    id: raw.id,
    email: raw.email,
    name: raw.name,
    avatarUrl: raw.avatar_url ?? '',
    slug: raw.slug ?? null,
    capabilities: raw.capabilities ?? [],
    authMethods: [],
    attributes: [],
  }
}
