
The shared `SectionLabel` in `@adh-sdk/ui` — the **display micro-heading**: the
quiet, wide-tracked uppercase-mono label that heads a pane or an in-card section
("RECENT ACTIVITY", "SOCIAL LINKS", "MONITORED SITES"). It ships as two exports
from `@adh-sdk/ui/components/section-label`: the `sectionLabelClass` string (so
any element can wear the treatment) and the `SectionLabel` component (the div
that applies it, with an optional trailing slot).

The treatment is `font-mono text-[0.625rem] font-medium uppercase
tracking-[0.1em] text-apt-text-dim` — smaller, dimmer, and wider-tracked than a
form caption. When a `trailing` node is given, the label lays out as a
`justify-between` row so an action (a "Refresh" button, a gear) sits opposite the
label on the same baseline; with no trailing node it is a bare div.

**This is one of three deliberately distinct heading treatments — keep them apart:**

| Treatment | Home | Role | Look |
|---|---|---|---|
| `sectionLabelClass` / `SectionLabel` | `components/section-label.tsx` | **Display** in-pane / in-card micro-heading | `text-[0.625rem]` mono, `apt-text-dim`, `tracking-[0.1em]` |
| `fieldCaptionClass` | `lib/typography.ts` | **Form** caption / group title / column header | `text-[0.7rem]` mono, `apt-text-muted`, `tracking-wider` |
| `SectionHeader` | `blocks/section-header.tsx` | **Page/section title** (with `?` help + actions) | `text-sm` mono, **`apt-gold`**, `font-medium` |

SectionLabel is the *quietest* of the three: dimmer and smaller than a field
caption, and a different element entirely from the gold page title. Reach for
`fieldCaptionClass` when labeling a form field; reach for `SectionHeader` for the
gold headline of a page area; reach for `SectionLabel` for the muted label inside
a pane or card. It is a stateless div with no `"use client"` directive.

