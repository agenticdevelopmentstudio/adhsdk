import type { ProfilePrincipal } from './types'

/**
 * The two wire bodies a `ProfilePrincipal` can arrive as, and the ONE place that knows they are
 * differently shaped.
 *
 * This is a module of its own rather than a private helper inside `server.ts` because THREE call
 * sites need it, on both sides of the server/client line: `fetchPublicPrincipal` (server,
 * `/v1/users` and `/v1/organizations`), `ProfileFallback` (client, `/api/v1/...`) and
 * `useViewerPrincipal` (client, the same routes with a bearer token). An earlier shape of this
 * task normalized only in `server.ts`, which left the two client fetchers spreading the raw org
 * body into a `ProfilePrincipal` — and `UserCard` reads `user.socialLinks.length`,
 * `user.emails.length`, `user.phones.length`, `user.addresses.length` and `user.personas.length`
 * unguarded, so an organization opened from the browser would have thrown on `undefined.length`
 * rather than rendered. One normalizer, three callers.
 *
 * It is deliberately NOT re-exported from the `./profile` barrel: it is wire plumbing, and the
 * public surface of this package is the four components, the hook and the principal type.
 */

/** One persona roster entry as /v1 sends it (`PublicPersonaSummary`): `created` is unix seconds. */
export type PersonaSummaryWire = {
  slug: string
  name: string
  description: string | null
  visibility: 'public' | 'hub'
  created: number
}

/** One address of the user card as /v1 sends it (`PublicAddress`). */
export type AddressWire = {
  label: string
  line1: string
  line2: string
  city: string
  region: string
  postal_code: string
  country: string
}

/**
 * `GET /v1/users?handle=:slug` answers the user card (`PublicUserProfile`) in /v1's snake_case,
 * with `created` in unix seconds. It is the same card whether the visitor is anonymous or
 * entitled: the gateway picks the public or the authed legacy route behind it. It is the
 * `ProfilePrincipal` minus the discriminator, which is a fact about WHICH endpoint answered and
 * never travels on the wire.
 */
export type UserCardBody = {
  object?: 'user'
  slug: string
  display_name: string | null
  avatar_url: string | null
  created: number
  social_links: ProfilePrincipal['socialLinks']
  emails: string[]
  phones: string[]
  addresses: AddressWire[]
  personas: PersonaSummaryWire[]
}

/**
 * `GET /v1/organizations?slug=:slug` answers `PublicOrgProfile` (backend `routes/org-card.ts`)
 * in snake_case, which is narrower than the user card in FIVE places — no `avatar_url` and
 * none of the four privacy-granted collections — and wider in one, `description`.
 *
 * The narrowness is deliberate on the backend and documented there twice: those four collections
 * are privacy-GRANTED sections keyed to a customer, and an org has no grants to admit, so
 * carrying them as permanently-empty arrays would advertise a gate that does not exist. That
 * argument is about the WIRE; it does not transfer to the presentation layer, where `UserCard`
 * guards every one of those sections on `.length > 0` and renders nothing for an empty array. So
 * the filling-in happens here, on the way in, and this is the one function to delete if orgs ever
 * gain those fields.
 *
 * `personas` is the field that is NOT missing — both endpoints carry a roster.
 */
export type OrgCardBody = {
  object?: 'organization'
  slug: string
  display_name: string
  description: string | null
  created: number
  personas: PersonaSummaryWire[]
}

/** The /v1 `created` (unix seconds) as the ISO string `UserCardDto` carries. This file is
 *  imported by server components, so it cannot take `unixToIso` from `@adh-sdk/auth/client`
 *  (a `'use client'` module); the conversion is one line. */
function iso(seconds: number): string {
  return new Date(seconds * 1000).toISOString()
}

function personasFromWire(rows: PersonaSummaryWire[]): ProfilePrincipal['personas'] {
  return rows.map((p) => ({
    slug: p.slug,
    name: p.name,
    description: p.description,
    visibility: p.visibility,
    createdAt: iso(p.created),
  }))
}

/** The user branch: maps the snake_case card onto the principal and stamps the discriminator. */
export function principalFromUserCard(body: UserCardBody): ProfilePrincipal {
  return {
    slug: body.slug,
    displayName: body.display_name,
    avatarUrl: body.avatar_url,
    createdAt: iso(body.created),
    socialLinks: body.social_links,
    emails: body.emails,
    phones: body.phones,
    addresses: body.addresses.map((a) => ({
      label: a.label,
      line1: a.line1,
      line2: a.line2,
      city: a.city,
      region: a.region,
      postalCode: a.postal_code,
      country: a.country,
    })),
    personas: personasFromWire(body.personas),
    kind: 'user',
  }
}

/** The org branch: supplies the five fields the org card does not carry, passes `description`
 *  through, and stamps the discriminator. See `OrgCardBody` for why the backend is narrow. */
export function principalFromOrgCard(body: OrgCardBody): ProfilePrincipal {
  return {
    slug: body.slug,
    displayName: body.display_name,
    createdAt: iso(body.created),
    description: body.description,
    personas: personasFromWire(body.personas),
    avatarUrl: null,
    socialLinks: [],
    emails: [],
    phones: [],
    addresses: [],
    kind: 'organization',
  }
}
