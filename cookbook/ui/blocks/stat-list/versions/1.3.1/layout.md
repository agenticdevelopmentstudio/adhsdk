
```
StatList  (as="ul" divided)
--- divider (border-t) --------------------------------------
 (dot) app · production        (truncates…)             1h
 (dot) worker queue            (truncates…)            12m
        ^ StatusDot   ^ min-w-0 flex-1 truncate label   ^ trailing (shrink-0)
```

- Row: `flex items-center gap-2 font-mono text-[11px]` — dot, then the truncating
  label, then the trailing group.
- Trailing group: `inline-flex shrink-0 items-center gap-2` so multiple trailing
  bits (a count + a deep link) space consistently.
- List: `flex list-none flex-col gap-1.5`, plus `border-t border-apt-border pt-2.5`
  when `divided`.
- No raw hex, no `!important` — color via `apt-*` tokens and the composed StatusDot.

