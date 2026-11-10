
- **accept-mode-prop**: Component MUST accept a `mode` prop with value `'inline'`, `'three-pane'`, or `'mobile'`.
- **route-by-mode**: Component MUST render `InlineChat` when `mode` is `'inline'`, `ThreePaneChat` when `mode` is `'three-pane'`, and `MobileChat` when `mode` is `'mobile'`.
- **accept-backend**: Component MUST accept and forward a `backend` prop (type `ChatBackend`) to the rendered chat layout.
- **accept-persona**: Component MUST accept and forward a `persona` prop (type `ChatParticipant`) to the rendered chat layout.
- **accept-user**: Component SHOULD accept an optional `user` prop (type `ChatParticipant`) and forward it to the rendered chat layout when provided.
- **accept-welcome-message**: Component SHOULD accept an optional `welcomeMessage` prop (type `string`) and forward it to the rendered chat layout when provided.
- **accept-class-name**: Component SHOULD accept an optional `className` prop (type `string`) and forward it to the rendered chat layout when `mode` is `'inline'` or `'three-pane'`. `MobileChat` does not accept a `className` prop, so it is not forwarded in `'mobile'` mode.
- **accept-sizing-inline**: Component SHOULD accept an optional `sizing` prop (type `InlineChatSizing`) for `inline` mode, forwarding it only when `mode` is `'inline'`, controlling active/inactive sizing behavior and transitions.
- **handle-mobile-open**: Component SHOULD accept an optional `open` prop (type `boolean`, default `false`) for `mobile` mode, forwarding it to control overlay visibility.
- **handle-mobile-close**: Component SHOULD accept an optional `onClose` callback (type `() => void`, default no-op) for `mobile` mode, forwarding it to handle overlay dismissal.

