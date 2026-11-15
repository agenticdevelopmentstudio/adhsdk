
- **Null and empty input**: A preview pick with no ref is refused (MUST,
  see `preview-pick-without-ref-refused`). An empty agent page (the
  gatekeeper failed closed) has no refs, so every pick in its preview is
  refused; the user can pick in the Website view instead.
- **Boundary values**: A ref whose recorded selector is empty cannot be
  saved and is refused like a missing ref. The "All items like it" scope in
  the preview uses the looser selector the gatekeeper recorded for the ref
  if it recorded one, and is disabled otherwise.
- **Concurrent access**: The preview may be rebuilt (navigation, setting
  change) between the click and OK; the selector saved is the one recorded
  in the agent page that was showing at click time.
- **Error states**: If the picker world cannot run in the preview (see the
  Design Decisions finding), selecting in the preview reports it with a
  beep and a logged reason, and selecting in the Website view still works.
- **Offline or disconnected state**: Not applicable — the preview loads
  nothing from the network by design, and the store is local.
- **Missing file or unreachable server**: Not applicable — the store's
  concern.
- **Cancellation and timeouts**: The element picker's single end routine
  applies.
- **Content the user also hid**: A node in the user list is not displayed,
  so the gatekeeper already omits it and it has no ref in the preview;
  there is nothing to pick.

