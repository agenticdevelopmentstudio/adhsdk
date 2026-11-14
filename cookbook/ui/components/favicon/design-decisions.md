
- **Decision**: Try a list of known icon paths in order instead of asking only for `/favicon.ico`.
  **Rationale**: The source comment states there is no single place a site keeps its icon; a Next.js app that declares `app/icon.svg` or `app/icon.png` serves it there and may have no `.ico`, and an icon generated from `app/icon.tsx` is served at the bare `/icon` or `/apple-icon`, which has no extension and no static copy at the other paths.
  **Approved**: pending

- **Decision**: Request the icon from the site itself and never through a third-party favicon service.
  **Rationale**: The source comment states that drawing a link then does not tell anyone else which links a page draws.
  **Approved**: pending

- **Decision**: Re-check a finished image that decoded to nothing after mount, in addition to handling the error event.
  **Rationale**: The source comment states a failed load can happen before hydration, because the server-rendered image starts fetching as soon as the HTML arrives, and React never sees that error event; a finished image with a natural width of zero is what a pre-hydration failure leaves behind.
  **Approved**: pending

- **Decision**: Render a new image element for each candidate by keying on the attempt counter.
  **Rationale**: The source comment states one element per candidate makes a new source a new load with its own events.
  **Approved**: pending

