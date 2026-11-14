
```
bare (no trailing)
  RECENT ACTIVITY
  Deployed build #147 to staging.

with trailing (justify-between row)
  MONITORED SITES                             [ Refresh ]
  57 sites · all green.
```

- Label element: `sectionLabelClass`, defined once in `#requirements/applies-display-treatment`.
- Bare form: `<div className={cn(sectionLabelClass, className)}>{children}</div>`.
- Trailing form: `<div className={cn("flex items-center justify-between gap-2", className)}><span className={sectionLabelClass}>{children}</span>{trailing}</div>` — an outer row `div` wrapping the label `span` plus the `trailing` node.
- Token-driven color (`apt-text-dim`); no raw hex, no `!important`.

