
Applicable: the component renders fixed English strings directly in its
JSX — the five section labels (`Social`, `Email`, `Phone`, `Address`,
`Personas`), the `Member since` prefix, `UserCardSkeleton`'s
`Loading profile…` label, and the `"<name>'s profile"` article `aria-label` —
plus the platform display names in `PLATFORM_LABELS`. None of these are
externalized to a resource file or accepted as a prop; there is currently no
mechanism (for example, a labels prop) for a consumer to override or
translate them, so localizing this component today requires forking it or
replacing the rendered text after the fact. `formatMemberSince` itself is
locale-aware — it calls `toLocaleDateString(undefined, …)`, which follows
the runtime's locale for month/year formatting (this casing/format choice is
locale-sensitive by design, not an invariant-culture call).

