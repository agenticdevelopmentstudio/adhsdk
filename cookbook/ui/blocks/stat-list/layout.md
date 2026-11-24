
```
StatList  (as="ul" divided)
--- divider (border-t) --------------------------------------
 (dot) app · production        (truncates…)             1h
 (dot) worker queue            (truncates…)            12m
        ^ StatusDot   ^ min-w-0 flex-1 truncate label   ^ trailing (shrink-0)
```

- Row: a horizontal, vertically centered line in the monospace face at 11 px — dot,
  then the truncating label, then the trailing group, with an 8 px gap between them.
- Trailing group: a non-shrinking inline group with an 8 px gap so multiple trailing
  bits (a count + a deep link) space consistently.
- List: a single vertical column with a 6 px row gap and no list markers, plus a top
  border and 10 px of top padding when `divided`.
- No raw hex, no `!important` — color via the theme's tokens and the composed StatusDot.
  The exact Tailwind classes are in the React/Web platform note.

