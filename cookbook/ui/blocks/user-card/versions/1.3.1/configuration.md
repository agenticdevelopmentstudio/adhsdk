
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

**`UserCardSkeleton` props:**

| Prop | Type | Required | Description |
|---|---|---|---|
| `className` | `string` | no | Extra classes on the skeleton root. |

