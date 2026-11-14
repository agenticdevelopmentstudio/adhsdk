
This recipe covers two independent components that cookr's name-only grouping merges
under one "progress" row, because they share no source and no API:

- **UI** (`Progress`, source: `packages/web/packages/ui/src/components/progress.tsx`):
  a self-contained determinate progress bar exported from `@adh-sdk/ui`.
- **Controls** (`Progress`/`ProgressProps`, source:
  `packages/web/packages/controls/src/user-settings/components/Progress.tsx`): a labeled,
  indeterminate-capable form-field control exported from
  `@adh-sdk/controls`'s `user-settings` module.

Every requirement, appearance note, configuration option, and test vector below is tagged
with the component (UI or Controls) it describes.

**UI**: a determinate progress bar rendered as a rounded track with an indicator filled to
`value` (a percentage, 0–100). It is a self-contained accessible element
(`role="progressbar"` carrying `aria-valuenow`/`aria-valuemin`/`aria-valuemax`) rather than a
wrapper around a primitive, so it needs no extra runtime dependency.

The fill is a full-width indicator translated horizontally so that a `value` of 0
hides it entirely (`translateX(-100%)`) and a `value` of 100 reveals it fully
(`translateX(-0%)`); the transform animates smoothly. The track uses the
`apt-surface-2` token and the fill defaults to `apt-gold`, but the fill is meant to
be re-tinted per context via `indicatorClassName` — e.g. amber while a job is
building, green once it completes.

A single export ships from `@adh-sdk/ui/components/progress`: the `Progress`
component. It carries `"use client"` (it renders an inline `style` transform) but
holds no internal state — `value` is fully controlled by the consumer.

**Controls**: a labeled form-field control — an `aws-field aws-field--progress` wrapper
around an optional `label`, the `role="progressbar"` track (`aws-progress`/
`aws-progress__bar`), and an optional `hint`. Unlike the UI bar, it supports an
`indeterminate` mode and a configurable `max`, but it does not clamp or round the value
it reports, does not forward arbitrary props, and has no `indicatorClassName` equivalent.
It ships from `@adh-sdk/controls`'s `user-settings` entry point alongside
the package's other settings-panel form controls.

