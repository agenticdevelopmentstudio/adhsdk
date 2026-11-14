
- **React / Web (TypeScript):** Evolve `packages/web/packages/ui/src/components/alert-modal.tsx`; reuse `packages/web/packages/ui/src/components/dialog.tsx` (Base UI) unchanged. Extend (not replace) `packages/web/packages/ui/src/__tests__/alertModal.test.tsx`. Demo in the UI showcase app (a consumer of this package, outside this repo). Reused by the hub `InvitationModal` (header + footer-button system).
- **Responsive:** Verify via Playwright (ui-showcase) — each variant rendered, keyboard flows exercised, at 375 / 768 / 1440.
- **SwiftUI / Compose:** Not applicable — web-only shared system.

API. Existing props (kept): `open`, `title`, `description`, `tone` (`"info" | "success" | "error"`), `confirmLabel` (default `"OK"`), `confirmVariant`, `onConfirm`, `cancelLabel` (presence ⇒ confirm mode), `onCancel`, `busy`. New props:

```ts
type KeyAction = "confirm" | "cancel";

interface AlertModalKeyboardAdds {
  /** "default" (see keyboard rules) | "none" (no shortcuts) | explicit key→action map. */
  keyboard?: "default" | "none" | Partial<Record<string, KeyAction>>;
  /** Destructive: action button red (apt-red); forces keyboard "none". */
  destructive?: boolean;
}
```

