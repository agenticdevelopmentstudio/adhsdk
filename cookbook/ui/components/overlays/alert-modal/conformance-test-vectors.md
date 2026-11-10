
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| T1 | render-title | `title="Delete file?"` | `DialogTitle` contains "Delete file?" |
| T2 | render-description-when-provided | `description="This cannot be undone."` | `DialogDescription` renders the text |
| T3 | omit-description-when-absent | `description` omitted | no `DialogDescription` in the DOM |
| T4 | show-tone-icon-by-default | `showIcon` omitted | tone icon renders next to the title |
| T5 | hide-tone-icon-when-disabled | `showIcon={false}` | no tone icon in the DOM |
| T6 | mark-tone-icon-decorative | any tone, icon shown | icon element has `aria-hidden` |
| T7 | map-tone-to-icon-and-color | `tone="success"` | `CheckCircle2` renders with `text-apt-green` |
| T8 | force-error-tone-when-destructive | `tone="info"`, `destructive={true}` | `TriangleAlert` renders with `text-apt-red`, not the info icon |
| T9 | render-alert-mode-when-no-cancel-label | `cancelLabel` omitted | one full-width confirm button, no cancel button |
| T10 | render-confirm-mode-when-cancel-label-set | `cancelLabel="Cancel"` | `DialogActions` renders cancel + confirm |
| T11 | invoke-onconfirm-on-confirm-click | click confirm | `onConfirm` called once |
| T12 | invoke-oncancel-on-cancel-click | confirm mode, click cancel | `onCancel` called once |
| T13 | default-confirm-label-ok | `confirmLabel` omitted | confirm button text is "OK" |
| T14 | style-confirm-destructive-in-alert-mode | alert mode, `destructive={true}` | confirm button uses `"destructive"` variant |
| T15 | apply-confirm-variant-in-alert-mode | alert mode, `destructive={false}`, `confirmVariant="outline"` | confirm button uses `"outline"` variant |
| T16 | show-busy-spinner-in-alert-mode, default-busy-label-working | alert mode, `busy={true}` | confirm button absent; `role="status"` spinner with `aria-label="Working…"` present |
| T17 | forward-busy-to-dialog-actions | confirm mode, `busy={true}` | `DialogActions` receives `busy={true}` |
| T18 | forward-destructive-to-dialog-actions | confirm mode, `destructive={true}` | `DialogActions` receives `destructive={true}` |
| T19 | set-initial-focus-by-destructiveness | confirm mode, `destructive={true}` | `DialogActions` receives `initialFocus="cancel"` |
| T19b | set-initial-focus-by-destructiveness | confirm mode, `destructive={false}` | `DialogActions` receives `initialFocus="confirm"` |
| T20 | hide-close-affordance-when-busy-or-non-dismissible | `dismissible={false}` | `DialogContent` receives `showClose={false}` |
| T20b | hide-close-affordance-when-busy-or-non-dismissible | `dismissible={true}`, `busy={true}` | `DialogContent` receives `showClose={false}` |
| T21 | default-dismissible-true | `dismissible` omitted | `×` close affordance present (not busy) |
| T22 | block-dismissal-when-busy | `busy={true}`, press Escape | `handleOpenChange` returns without invoking `onConfirm`/`onCancel`; `open` is left unchanged by the component |
| T23 | block-dismissal-when-non-dismissible | `dismissible={false}`, press Escape | `handleOpenChange` returns without invoking `onConfirm`/`onCancel`; `open` is left unchanged by the component |
| T24 | route-escape-to-cancel-in-confirm-mode | confirm mode, `keyboard="default"`, press Escape | `onCancel` called once |
| T25 | route-escape-to-confirm-in-alert-mode | alert mode, `keyboard="default"`, press Escape | `onConfirm` called once |
| T26 | block-escape-when-keyboard-disabled | `keyboard="none"`, press Escape | neither callback called; dialog stays open |
| T27 | route-close-button-regardless-of-keyboard-policy | `keyboard="none"`, confirm mode, click ✕ | `onCancel` called once |
| T27b | route-close-button-regardless-of-keyboard-policy | `keyboard="none"`, confirm mode, click backdrop | nothing happens: `onOpenChange` never fires, `onCancel` not called, dialog stays open |
| T28 | invoke-confirm-on-enter-under-default-keyboard | `keyboard="default"`, press Enter | `onConfirm` called once; event `preventDefault` called |
| T29 | ignore-all-keys-when-keyboard-none | `keyboard="none"`, press Enter | neither callback called |
| T30 | force-keyboard-none-when-destructive | `destructive={true}`, `keyboard="default"`, press Enter | `onConfirm` not called via the keydown listener |
| T31 | honor-explicit-keyboard-map | `keyboard={{ k: "confirm" }}`, press `k` | `onConfirm` called once |
| T32 | ignore-unmapped-keys-in-explicit-map | `keyboard={{ k: "confirm" }}`, press `j` | neither callback called |
| T33 | scope-keydown-listener-to-open-and-not-busy | `open={false}`, press Enter | neither callback called (listener not attached) |
| T34 | forward-open-state-to-dialog | `open={true}` | `Dialog` root receives `open={true}` |
| T35 | forward-content-class-name | `contentClassName="sm:max-w-lg"` | `DialogContent` receives that `className` |
| T36 | tolerate-missing-oncancel | confirm mode, `onCancel` omitted, click cancel | `onCancel?.()` is a no-op; no error thrown |

