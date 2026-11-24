
- **Null and empty input**: A blank tab shows the gatekeeper's empty page:
  an empty preview and the minimal HTML in the source view.
- **Boundary values**: A very large page's source is shown whole in a
  scrolling text view; a page the walker cannot finish in time is shown as
  the unavailable reason (MUST, `unavailable-shown-as-reason`).
- **Concurrent access**: View work runs on the main thread, except the
  gatekeeper's decode, build and concealment and the source view's lex,
  which run off it and land back on it. A rebuild
  that finishes after a newer one was started is discarded, so the view
  never shows an older page than the latest trigger asked for.
- **Error states**: Every gatekeeper failure is shown as its reason, never
  as the live page (MUST, `unavailable-shown-as-reason`).
- **Offline or disconnected state**: Not applicable — the preview makes
  no network load by design (`preview-blocks-network`), so connectivity
  changes nothing.
- **Missing file or unreachable server**: The block-everything rule list
  failing to compile MUST leave the preview showing nothing rather than an
  unblocked document.
- **Cancellation and timeouts**: Closing the tab or switching it to
  Website mode cancels a pending rebuild; the gatekeeper's walker timeout
  bounds each rebuild.
- **Navigation while an agent view is shown**: The view rebuilds when the
  navigation finishes; until then it keeps the previous page's content.
- **Entering from Website**: The view shows the blank page until its
  rebuild lands; an earlier agent page never passes for the current one
  (MUST, `entering-from-website-blank`). Moving between Agent preview and
  Agent source keeps the current page shown meanwhile.
- **Rebuilds in quick succession**: A second preview load started before
  WebKit asked about the first is still let through, so the preview ends
  on the newest page rather than cancelling it (MUST,
  `preview-no-navigation`).

