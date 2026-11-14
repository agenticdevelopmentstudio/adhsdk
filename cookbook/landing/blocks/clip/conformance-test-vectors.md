
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| clip-001 | render-video-element, accept-src | `src="https://example.com/video.mp4"` | Video element renders with `src` attribute set to the provided URL |
| clip-002 | aria-label | `label="Demo video"` | Video element has `aria-label="Demo video"` |
| clip-003 | accept-dimensions | `width={640}`, `height={360}` | Video element renders with `width="640"` and `height="360"` attributes |
| clip-004 | autoplay-when-motion-allowed, loop-when-motion-allowed, hide-controls-when-motion-allowed | `prefers-reduced-motion` is false | Video element has the `autoplay` and `loop` attributes and no `controls` attribute (`video.autoplay === true`, `video.loop === true`, `video.hasAttribute('controls') === false`) |
| clip-005 | disable-autoplay-when-motion-reduced, disable-loop-when-motion-reduced, show-controls-when-motion-reduced | `prefers-reduced-motion` is true | Video element has the `controls` attribute and no `autoplay` or `loop` attribute (`video.autoplay === false`, `video.loop === false`, `video.hasAttribute('controls') === true`) |
| clip-006 | always-mute | Any props | `video.muted === true` |
| clip-007 | play-inline | Any props | `video.playsInline === true` |
| clip-008 | pause-on-motion-reduced | Video is autoplaying with `prefers-reduced-motion` false; a mocked `matchMedia` change event fires with `matches: true` | `video.paused === true` immediately after the change event |
| clip-009 | accept-src | `src="video.webm"` | Video element's `src` attribute is set to `"video.webm"` (asserted via the DOM attribute; actual `.webm` decoding is not exercised in jsdom) |
| clip-010 | pause-on-motion-reduced | Server renders assuming `prefers-reduced-motion` is false; the client's actual OS preference is true | After hydration corrects the `usePrefersReducedMotion` snapshot to `true`, the pause effect fires and `video.paused === true` despite the SSR markup emitting `autoplay` |
| clip-011 | no-resume-on-motion-allowed | Video is paused because `prefers-reduced-motion` was true; the preference then changes to false | `video.autoplay` and `video.loop` become `true` and the `controls` attribute is removed, but `video.paused` stays `true` until the user or host calls `.play()` |

