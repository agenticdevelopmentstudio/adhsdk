
Not marked not-applicable: the package's own English strings are user-facing
and hardcoded, with no localization mechanism in the given sources.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (required-field) | `Required.` | Shown under a required field left empty (`validation.ts` `REQUIRED_MESSAGE`). |
| (unlisted-choice) | `"<value>" is not one of the available choices.` | Shown under a `select` field holding a value off its own option list (`validation.ts` `unlistedChoiceMessage`). |
| (layout-duplicate) | `These fields are laid out in more than one section: <keys>.` | Runtime layout-fault text, also logged (`container.tsx`). |
| (layout-uncovered) | `These fields are declared but no section lays them out: <keys>.` | Runtime layout-fault text, also logged (`container.tsx`). |
| (layout-unknown) | `Section "<title>" lays out unknown field "<key>".` | Runtime layout-fault text, also logged (`container.tsx`). |
| (repair-prompt-title) | `Repair required` | Title of the non-dismissible repair acknowledgement (`container.tsx` `repairAlert`). |
| (repair-prompt-description) | `This data needs some repair and will be saved.` | Body of the repair prompt and its busy state (`container.tsx` `repairAlert`). |
| (repair-succeeded-title) | `Repair succeeded` | Title of the dismissible success acknowledgement (`container.tsx` `repairAlert`). |
| (repair-failed-title) | `Repair failed` | Title of the dismissible failure acknowledgement; its description is the caller's own error/fault message, not a fixed string (`container.tsx` `repairAlert`). |
| (unknown-error-fallback) | `Unknown error.` | Shown when a rejected `onSave`/`onRepair` throws something that is neither an `Error` nor a string (`container.tsx` `messageOf`). |
| (default-alert-confirm) | `OK` | `EditingAlertProps.confirmLabel` default, applied by the platform's `AlertModal` (`host.tsx` `PlatformAlert`). |

