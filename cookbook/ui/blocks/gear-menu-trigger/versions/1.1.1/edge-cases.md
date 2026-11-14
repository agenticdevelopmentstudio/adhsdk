
- **Empty or whitespace-only label**: The component does not validate or trim the `label` prop. If an empty string or whitespace-only string is passed, `aria-label` will be set to that value, and screen readers will announce it as empty or whitespace. The host is responsible for providing a non-empty label.
- **Very long label**: If `label` is a very long string, the `aria-label` will reflect that full string, but the visual trigger remains 24px and does not resize or wrap text. Screen readers announce the full label.
- **Disabled triggering dropdown**: When `disabled` is `true`, the trigger is inert and does not open the associated `DropdownMenuContent`. This is native browser behavior for a disabled button.
- **No DropdownMenuContent provided**: The component is the trigger only. If no `DropdownMenuContent` is composed as a sibling by the host, the trigger renders but has no effect when activated. The host MUST provide the menu content.
- **Multiple instances on same page**: Each instance is independent; the `label` prop distinguishes them for accessibility.
- **Rapid clicks when enabled**: If the trigger is rapidly clicked, the dropdown menu behavior is governed by the `DropdownMenuTrigger` component; repeated activations toggle or re-open the menu normally.

