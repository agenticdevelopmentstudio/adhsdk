
| State | Appearance change |
|---|---|
| Loading | `UserCardSkeleton` — shimmer blocks replace all sections |
| Identity only | No separator, no gated sections; only the header area is shown |
| Full card | Separator + all populated gated sections visible |
| No avatar | `AvatarFallback` with two-letter initials or `UserIcon` placeholder |
| Long display name | Wraps inside the `min-w-0 flex-1` column; never truncated |

