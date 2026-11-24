
ToggleGroup itself defines no user-facing strings, but it forwards whatever text a consumer
passes straight through with no translation layer of its own. Consumers MUST pass localized
item labels (the `children` of each `ToggleGroupItem`) and a localized `aria-label` (or
`aria-labelledby`) on the group, per **forwards-group-and-item-props**.

