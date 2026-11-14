
- **accept-src**: Component MUST accept a `src` prop containing the public path to an `.mp4` or `.webm` video file.
- **render-video-element**: Component MUST render a single `<video>` element with the provided `src`.
- **aria-label**: Component MUST accept a `label` prop and set it as the video element's `aria-label`.
- **respect-reduced-motion**: Component MUST read the `prefers-reduced-motion` media query and adapt playback behavior accordingly.
- **autoplay-when-motion-allowed**: Component MUST set `autoPlay=true` on the video element when `prefers-reduced-motion` is false.
- **disable-autoplay-when-motion-reduced**: Component MUST set `autoPlay=false` on the video element when `prefers-reduced-motion` is true.
- **loop-when-motion-allowed**: Component MUST set `loop=true` on the video element when `prefers-reduced-motion` is false.
- **disable-loop-when-motion-reduced**: Component MUST set `loop=false` on the video element when `prefers-reduced-motion` is true.
- **show-controls-when-motion-reduced**: Component MUST set `controls=true` on the video element when `prefers-reduced-motion` is true.
- **hide-controls-when-motion-allowed**: Component MUST set `controls=false` on the video element when `prefers-reduced-motion` is false.
- **always-mute**: Component MUST set `muted=true` on the video element.
- **play-inline**: Component MUST set `playsInline=true` on the video element.
- **respond-to-preference-changes**: Component MUST pause the video immediately via an imperative `ref.current?.pause()` when `prefers-reduced-motion` changes from false to true while the page is open, including the correction that happens right after hydration. When the preference changes from true to false, no imperative action is taken, so playback that was already paused does not resume automatically.
- **accept-dimensions**: Component MUST accept optional `width` and `height` props and apply them to the video element for layout sizing before content loads.

