
Alert (`packages/web/packages/ui/src/components/alert.tsx`) is an inline,
non-modal callout: a bordered, tonal box with an optional leading icon, a
title, and a description. Per the source comment, it is themed entirely from
`apt-*` status tokens. The module exports four names: `Alert` (the root
container), `AlertTitle` and `AlertDescription` (two positioned text
sub-components), and `alertVariants` (the standalone `cva` styling function).
Layout is CSS grid: the root reserves a first column for an optional icon and
a second column (`col-start-2`) for `AlertTitle`/`AlertDescription`; the
column layout only widens to make room for an icon when a direct `<svg>`
child is present.

