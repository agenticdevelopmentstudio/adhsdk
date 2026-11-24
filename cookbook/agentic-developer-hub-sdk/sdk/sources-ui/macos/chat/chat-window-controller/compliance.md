
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | Reliability |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`keyboard-navigable` and `focus-management` rest on the `windowBecameKey`/`focusInput()` first-responder handling that puts the composer in the key chain without requiring a pointer; `state-recovery` rests on `setFrameUsingName(_:)` restoring the saved frame and centering as a fallback; `string-externalization` is `partial` because `ChatWindowConfiguration.backdropToggleTitle` defaults to the hardcoded English literal `"Background animation"` (see Localization) even though every other user-facing string is host-supplied. separation-of-concerns passes because `ChatWindowController` delegates appearance state to `ChatWindowAppearanceController` and layout to `ChatContentViewController`/`ChatContainerView`, keeping only window-lifecycle plumbing (frame autosave, first-responder focus) in the controller itself, and unit-test-coverage passes because `ChatWindowTests.swift` exercises frame namespacing, theme-scope propagation, and the backdrop switch's conditional presence with meaningful assertions.

