
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-confirm | `confirmLabel="Save"`, click confirm | `onConfirm` called once |
| T2 | render-cancel-when-labeled | `cancelLabel="Cancel"`, click cancel | cancel button present; `onCancel` called once |
| T3 | render-cancel-when-labeled | no `cancelLabel` | no cancel button in the DOM |
| T4 | equal-width-when-narrow (Playwright) | `auto` in a container narrower than the sum of both buttons' natural widths | both buttons split the row evenly, each capped at its own natural width; row fills the container |
| T5 | natural-width-when-wide (Playwright) | `auto` in a container at least as wide as both buttons' natural widths combined | both at natural width; row right-justified |
| T6 | cap-growth-at-natural-width | `auto` | both buttons carry `flex-1 max-w-max`; the row carries `justify-end` |
| T7 | settle-before-interactive (Playwright) | sample the cancel button's bounding box every frame from before the dialog opens | exactly one distinct box — the final one — for the dialog's whole life |
| T8 | follow-the-container (Playwright) | render narrow (even split), widen the container past the combined natural width of both buttons | layout becomes natural, right-justified |
| T8b | honor-forced-layout | `layout="equal"` in a wide container | equal-width, uncapped; no natural flip when resized |
| T9 | focus-initial-on-mount + default-focus-to-safe-button | mount non-destructive | confirm button is `document.activeElement` |
| T10 | default-focus-to-safe-button | mount with `destructive` | cancel button is `document.activeElement` |
| T11 | suppress-focus-on-mount | mount with `focusOnMount={false}` | neither button receives focus |
| T12 | show-busy-indicator | `busy`, attempt to click | `role="status"` spinner present; no buttons; `onConfirm`/`onCancel` not called |
| T13 | style-confirm-destructive | `destructive` | confirm button uses destructive variant |
| T14 | settle-before-interactive | mount, then fire a window resize | the row's and buttons' class lists are byte-identical before and after |
| T15 | apply-confirm-disabled | `confirmDisabled=true`, click confirm | confirm button disabled; `onConfirm` not called |
| T16 | show-busy-indicator | `confirmDisabled=true` and `busy=true` | spinner renders; buttons not visible; `confirmDisabled` ignored |
| T17 | focus-fallback-to-other-button | mount with `initialFocus="confirm"` where the confirm button is disabled at mount | cancel button is `document.activeElement` |
| T18 | quiet-ring-for-destructive-cancel | mount with `destructive`, inspect the cancel button's focus-visible classes | cancel carries `focus-visible:border-apt-text focus-visible:ring-apt-text/40`, not the default ring token |

