
`InfoPanel` (`@adh-sdk/ui`) is the standard dashboard panel: a bordered,
rounded card with a consistent header over a body that is either **content-sized**
(a stat card) or a **fill + scroll** pane (a list). It is generic on purpose — the
host supplies whatever goes in the header slots and the body (icons, copy buttons,
filter controls, progress bars, rows) — so every dashboard panel across the
platform shares one frame and one header rhythm.

Header anatomy (single row):

```
[icon] [title] [count] [titleAfter]  …flex…  [center]  …flex…  [actions]
```

The header has a shared minimum height (`INFO_PANEL_HEADER_HEIGHT`, 41px), also
exported, so sibling panels laid side by side on a rail line their headers up even
when their content differs.

Two symbols ship from `@adh-sdk/ui/blocks/info-panel`:

- `InfoPanel` — the component.
- `INFO_PANEL_HEADER_HEIGHT` — the shared default header height, exported so hosts
  can align other, non-`InfoPanel` chrome to the same baseline.

