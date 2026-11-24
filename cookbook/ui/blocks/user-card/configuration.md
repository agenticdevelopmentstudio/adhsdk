
**Import path:**
```ts
import { UserCard, UserCardSkeleton, type UserCardDto } from '@adh-sdk/ui/blocks/user-card';
```

**Props:**

| Prop | Type | Required | Description |
|---|---|---|---|
| `user` | `UserCardDto` | yes | The profile DTO from the backend. |
| `className` | `string` | no | Extra Tailwind classes applied to the root `<article>`. |

**`UserCardDto` shape:**

| Field | Type | Description |
|---|---|---|
| `slug` | `string` | Unique user slug. Used as fallback display name. |
| `displayName` | `string \| null` | User's chosen display name. |
| `avatarUrl` | `string \| null` | Avatar image URL (arbitrary origin; not run through Next.js optimizer). |
| `createdAt` | `string \| null \| undefined` | ISO 8601 timestamp; rendered as "Member since Month Year". Omitted (e.g. an owner's own preview where no account date is available) hides the line. |
| `socialLinks` | `UserCardSocialLink[]` | Visible social links from the privacy-gated set. |
| `emails` | `string[]` | Visible email addresses. |
| `phones` | `string[]` | Visible phone numbers. |
| `addresses` | `UserCardAddress[]` | Visible physical addresses. |
| `personas` | `UserCardPersona[]` | Visible personas (public or unlisted). |

**`UserCardSocialLink` shape:**

| Field | Type | Description |
|---|---|---|
| `platform` | `string` | Platform key, looked up case-insensitively in `PLATFORM_LABELS`. An unknown key is shown as-is (the raw `platform` string). |
| `url` | `string` | Link target, used as the `href` unchanged. |
| `handle` | `string` | Handle shown beside the label in monospace; omitted from the DOM when empty. |

**`PLATFORM_LABELS`** maps lowercase platform keys to display names: `instagram` (Instagram), `facebook` (Facebook), `x` (X), `tiktok` (TikTok), `bluesky` (Bluesky), `linkedin` (LinkedIn), `substack` (Substack), `github` (GitHub), `youtube` (YouTube), `mastodon` (Mastodon), `threads` (Threads), `twitch` (Twitch), `discord` (Discord), `website` (Website).

**`UserCardAddress` shape:**

| Field | Type | Description |
|---|---|---|
| `label` | `string` | Optional heading above the address (for example "Home"); omitted when empty. |
| `line1`, `line2` | `string` | Street lines, each shown as its own line when non-empty. |
| `city`, `region`, `postalCode` | `string` | Non-empty values are joined with `", "` into one line (for example `Austin, TX, 78701`). |
| `country` | `string` | Shown as the last line when non-empty. |

Lines render in the order line1, line2, city/region/postal line, country; empty fields are skipped.

**`UserCardPersona` shape:**

| Field | Type | Description |
|---|---|---|
| `slug` | `string` | Unique persona slug, used as the list key. |
| `name` | `string` | Persona name. |
| `description` | `string \| null` | Shown under the name when non-empty. |
| `visibility` | `'public' \| 'hub'` | Shown in a badge; `public` uses the success style and `hub` the neutral style. |
| `createdAt` | `string` | Part of the type; the card does not render it. |

**`UserCardSkeleton` props:**

| Prop | Type | Required | Description |
|---|---|---|---|
| `className` | `string` | no | Extra classes on the skeleton root. |
