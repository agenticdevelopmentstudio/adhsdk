
- **React / Web (TypeScript):** Evolve `packages/web/packages/ui/src/components/alert-modal.tsx`; reuse `packages/web/packages/ui/src/components/dialog.tsx` (Base UI) unchanged. Extend (not replace) `packages/web/packages/ui/src/__tests__/alertModal.test.tsx`. Demo in the UI showcase app (a consumer of this package, outside this repo). The `equal-width-when-narrow` rule is realized by the `DialogActions` default `auto` layout (`flex-1 max-w-max`).
- **SwiftUI / Compose:** Not applicable — web-only shared system.
- **AppKit / UIKit:** Not applicable to this web-only system. A port would use `NSAlert` (AppKit) or `UIAlertController` (UIKit), which supply the focus trap, the button order and the Escape handling; map `destructive` to the platform's destructive button style and `confirm-mode-trigger` to adding a second button.
- **WinUI 3:** Port to a `ContentDialog`: `PrimaryButtonText` is the action and `CloseButtonText` is Cancel, `DefaultButton` set to `Close` for a destructive dialog (the focus rule), `IsPrimaryButtonEnabled` and `ProgressRing` for `busy`, and a `PreviewKeyDown` handler for an explicit key map. `ContentDialog` handles Escape itself, so the `Closing` event is where to apply `escape-routing`.

API. Props of `AlertModal`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | none (required) | Controlled visibility. |
| `title` | `string` | none (required) | Heading line. |
| `description` | `ReactNode` | none | Body copy. |
| `tone` | `"info" \| "success" \| "error"` | `"info"` | Leading icon and accent. |
| `confirmLabel` | `string` | `"OK"` | Action button label. |
| `confirmVariant` | `Button` variant | `"default"` | Variant of the action button. |
| `onConfirm` | `() => void` | none (required) | Action. Also fired on dismissal in alert mode. |
| `cancelLabel` | `string` | none | Presence turns on confirm mode (`confirm-mode-trigger`). |
| `onCancel` | `() => void` | none | Cancel action. Also fired on dismissal in confirm mode. |
| `busy` | `boolean` | `false` | Replaces the buttons with a spinner and blocks dismissal. |
| `keyboard` | `"default" \| "none" \| Partial<Record<string, "confirm" \| "cancel">>` | `"default"` | Keyboard policy: `"default"` (see keyboard rules), `"none"` (no shortcuts) or an explicit key to action map. |
| `destructive` | `boolean` | `false` | Action button red (`apt-red`); forces keyboard `"none"`. |

```ts
type KeyAction = "confirm" | "cancel";

interface AlertModalKeyboardAdds {
  /** "default" (see keyboard rules) | "none" (no shortcuts) | explicit key to action map. */
  keyboard?: "default" | "none" | Partial<Record<string, KeyAction>>;
  /** Destructive: action button red (apt-red); forces keyboard "none". */
  destructive?: boolean;
}
```
