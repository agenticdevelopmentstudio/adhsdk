
- **Null and empty input**: A preview pick with no ref is refused (MUST,
  see `preview-pick-without-ref-refused`). An empty agent page (the
  gatekeeper failed closed) has no refs, so every pick in its preview is
  refused; the user can pick in the Website view instead.
- **Boundary values**: A ref whose recorded selector is empty cannot be
  saved and is refused like a missing ref. A click on blank space in the
  preview lands on the document root, whose ref the preview puts on
  `<body>`; that pick is refused too, since saving it would hide the whole
  page from the agent. In the Website view a pick of the page's root, or
  a recorded selector that names only `html`/`body`, is refused the same
  way (element picker's `this-item-not-root`). The "All items like it" scope in
  the preview uses the looser selector the gatekeeper recorded for the ref
  if it recorded one, and is disabled otherwise. The gatekeeper records no
  looser selector today, so in the preview it is always disabled.
- **Pages with no host**: On a `file:`, `about:` or `data:` page the
  button is disabled with its tooltip kept, and nothing is saved, since an
  entry's site would be `*` and hide the item from the agent everywhere
  (MUST, see `hostless-page-disabled`).
- **Agent source view**: The source view is text, with no elements to
  pick; "Select Items to Hide from the Agent" there beeps and starts
  nothing.
- **Concurrent access**: The preview may be rebuilt (navigation, setting
  change) between the click and OK; the selector saved is the one recorded
  in the agent page that was showing at click time.
- **Error states**: If the picker world cannot run in the preview (see the
  Design Decisions finding), selecting in the preview reports it with a
  beep and a logged reason, and selecting in the Website view still works.
  A picker that fails to start in either view beeps and ends selecting.
  Selecting distracting items for the user's own list starts only in the
  Website view; under an agent view it beeps and starts nothing.
- **Offline or disconnected state**: Not applicable — the preview loads
  nothing from the network by design, and the store is local.
- **Missing file or unreachable server**: Not applicable — the store's
  concern.
- **Cancellation and timeouts**: The element picker's single end routine
  applies.
- **Content the user also hid**: A node in the user list is not displayed,
  so the gatekeeper already omits it and it has no ref in the preview;
  there is nothing to pick.

