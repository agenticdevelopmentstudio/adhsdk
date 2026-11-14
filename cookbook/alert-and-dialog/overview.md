
The canonical styled alert / confirm / modal-dialog treatment for ADH. It is
realized by evolving `@adh-sdk/ui`'s existing `AlertModal`
(`packages/web/packages/ui/src/components/alert-modal.tsx`) **backward-compatibly** —
existing call-sites and tests keep working. Larger modal dialogs reuse the same
header + footer-button system on top of the base `Dialog`.

It is one controlled component for two common shapes — **Alert** (single action,
full-width gold `[ OK ]`) and **Confirm** (two actions `[ Cancel ][ OK ]`, equal
width, OK gold) — plus a **destructive** mode (red action, no keyboard shortcuts)
and a caller-configurable keyboard policy. The same header style and footer-button
rules are exposed for composed dialogs so everything looks uniform.

