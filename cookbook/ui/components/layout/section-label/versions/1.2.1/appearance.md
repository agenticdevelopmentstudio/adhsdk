
```
bare (no trailing)
  RECENT ACTIVITY
  Deployed build #147 to staging.

with trailing (justify-between row)
  MONITORED SITES                             [ Refresh ]
  57 sites · all green.
```

- Label element: `sectionLabelClass` =
  `font-mono text-[0.625rem] font-medium uppercase tracking-[0.1em] text-apt-text-dim`.
- Bare form: `<div className={cn(sectionLabelClass, className)}>{children}</div>`.
- Trailing form: an outer `flex items-center justify-between gap-2` row wrapping
  the same label div plus the `trailing` node.
- Token-driven color (`apt-text-dim`); no raw hex, no `!important`.

