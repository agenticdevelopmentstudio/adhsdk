
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| clip-001 | render-video-element, accept-src | `src="https://example.com/video.mp4"` | Video element renders with `src` attribute set to the provided URL |
| clip-002 | aria-label | `label="Demo video"` | Video element has `aria-label="Demo video"` |
| clip-003 | accept-dimensions | `width={640}`, `height={360}` | Video element renders with `width="640"` and `height="360"` attributes |
| clip-004 | autoplay-when-motion-allowed, loop-when-motion-allowed, hide-controls-when-motion-allowed | `prefers-reduced-motion` is false | Video element has `autoPlay={true}`, `loop={true}`, `controls={false}` |
| clip-005 | disable-autoplay-when-motion-reduced, disable-loop-when-motion-reduced, show-controls-when-motion-reduced | `prefers-reduced-motion` is true | Video element has `autoPlay={false}`, `loop={false}`, `controls={true}` |
| clip-006 | always-mute | Any props | Video element has `muted={true}` |
| clip-007 | play-inline | Any props | Video element has `playsInline={true}` |
| clip-008 | respond-to-preference-changes | Video is autoplaying with `prefers-reduced-motion` false; a mocked `matchMedia` change event fires with `matches: true` | Video element pauses immediately via `ref.current?.pause()` |
| clip-009 | accept-src | `src="video.webm"` | Video element's `src` attribute is set to `"video.webm"` (asserted via the DOM attribute; actual `.webm` decoding is not exercised in jsdom) |
| clip-010 | respond-to-preference-changes | Server renders assuming `prefers-reduced-motion` is false; the client's actual OS preference is true | After hydration corrects the `usePrefersReducedMotion` snapshot to `true`, the pause effect fires and the video ends up paused despite the SSR markup emitting `autoPlay` |
| clip-011 | respond-to-preference-changes | Video is paused because `prefers-reduced-motion` was true; the preference then changes to false | `autoPlay`/`loop` update to `true` and `controls` to `false`, but playback does not resume automatically — the video stays paused until the user or host calls `.play()` |

