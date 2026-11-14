
Vectors dh-001 to dh-003 are derived from `detailHeaderActions.test.tsx`, which checks that `detailActions` lands inside `[data-slot="detail-header"]` immediately before `[data-adh-detail-api-slot]`, with no toolbar strip and exactly one link. The remaining vectors follow from the source; `PersonaEditor.test.tsx`, `buttonBarApiSlot.test.tsx` and `detailTitle.test.tsx` use the block through their panes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dh-001 | actions-box, row-hook, slot-order (test: detail actions land in the header) | Provider with `actions` holding one link, a row | The actions box is inside `[data-slot="detail-header"]` and immediately precedes `[data-adh-detail-api-slot]` |
| dh-002 | actions-box (test: no toolbar strip) | Same | No separate toolbar strip exists above or beside the row |
| dh-003 | actions-box (test: exactly one link) | Same | Exactly one link is in the document |
| dh-004 | api-fallback, help-fallback | Provider, no claimants, no `fallbackHelp` | API slot holds a disabled API button; help slot holds a disabled help button |
| dh-005 | help-fallback | Provider with `fallbackHelp` set, no claimants | Help slot holds `fallbackHelp`, not the disabled help button |
| dh-006 | portal-claims, portal-renders-in-slot | Provider; a portal of kind api with a button | The button is inside `[data-adh-detail-api-slot]`; the disabled API button is gone |
| dh-007 | last-claimant-wins, portal-yields | Two api portals mounted in order A then B | Only B's control is in the slot; A renders nothing; exactly one API control is present |
| dh-008 | claim-withdraw-own | A then B mounted; B unmounts | A's control reappears in the slot |
| dh-009 | claim-withdraw-own | A then B mounted; A unmounts | B's control stays in the slot |
| dh-010 | portal-claims | The only api portal unmounts | The disabled API button returns |
| dh-011 | portal-inline, has-header-hook, header-hook | A portal and a hook probe outside any provider | The portal's children render inline; `useHasDetailHeader` is false; `useDetailHeader` is null |
| dh-012 | has-header-hook, header-hook | The same probe inside a provider | `useHasDetailHeader` is true; `useDetailHeader` returns a host |
| dh-013 | no-provider-fallback | A row outside any provider | A disabled API button and a disabled help button; no `data-adh-detail-api-slot` |
| dh-014 | actions-omitted | `actions` is undefined, then null, then false | No actions box in any case |
| dh-015 | lead-optional, lead-cell, row-padding | `lead` given with `leadCell`; then without `leadCell`; then no lead | Lead in a 32px cell with right padding only; lead inline with side padding; no lead and side padding |
| dh-016 | title-cell, title-spacer | A row with `title`; then without | The title cell is rendered in the row; then an empty flexible spacer |
| dh-017 | disabled-api-name, disabled-api-tooltip | `DisabledApiButton` with no reason; then reason "Pick an endpoint" | Name and tooltip read "API — This view has no API endpoint" and "This view has no API endpoint"; then "API — Pick an endpoint" and "Pick an endpoint" |
| dh-018 | disabled-help-name, disabled-help-tooltip, disabled-help-class | `DisabledHelpButton` with no reason and `triggerClassName="x"` | Name "About this section — No help for this view"; tooltip "No help for this view"; the button's classes include "x" |
| dh-019 | slots-are-state, portal-renders-in-slot | A portal mounted in the same commit as the provider | The control reaches the slot after the slot element mounts (it does not stay invisible) |
| dh-020 | claim-idempotent | Claim the same id and kind twice, release an unheld id | The claim list is unchanged; no extra re-render |
| dh-021 | claim-by-kind | One api claimant and one help claimant | Each slot holds its own claimant's control; the kinds do not interfere |
| dh-022 | portal-claims | A portal's `kind` prop changes from api to help | The api claim is released and the help claim is made |

