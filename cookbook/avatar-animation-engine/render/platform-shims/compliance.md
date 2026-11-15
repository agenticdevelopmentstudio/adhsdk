
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | Performance |
| [adc.check.performance.animation-frame-rate](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9eb9b4fc-2e44-5391-9445-d6e78caa874e) | partial | Performance |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Neither file swallows an error: `CGColor.avatarInk` returns `nil` and
`CGPath.avatarItem` throws, both propagated to the caller rather than
absorbed (explicit-error-handling). `PlatformShims.swift`'s entire structure
is one file isolating AppKit/UIKit specifics from the rest of the package,
and `svg.ts` isolates DOM/string paint decisions behind one `attrsOf`
function used by both render paths (separation-of-concerns). All operations
in both files are small, synchronous, and O(items) per frame, with no I/O or
network call in the render path (main-thread-freedom). This is the render
path for a per-frame, `CADisplayLink`/animation-loop-driven `DisplayList`,
but neither file measures or enforces a per-frame time budget — the
node-reuse design (one `<path>`/layer per id, rewritten rather than rebuilt)
supports a 60fps target without proving it from source alone
(animation-frame-rate: partial). `unit-test-coverage` is partial (`svg.test.ts` now passes vectors 005-012 and 014, one test each; the Swift-only vectors 001-004 and 013 are skipped on the web):
`RenderTests.swift` exercises the `CGAffineTransform`/`CGColor.avatarInk`/
`CGPath.avatarItem`/`StrokeStyle` bridges and `svg.test.ts` exercises
`svg.ts`'s `createSvgRenderer`/`renderToString` against real engine output,
but no vector covers the host-view lifecycle (`host-visibility-*`,
`main-actor-isolation`), `host-layer-access`, `display-link-creation`, the
recognizer-creation requirements, `pointer-location-*`, `focus-check-*`,
`occlusion-notification-name`, `on-screen-check-*`, `svg-data-id-write-once`,
or `svg-renderer-single-svg-element`. Those depend on a live window or an AppKit/UIKit runtime.
