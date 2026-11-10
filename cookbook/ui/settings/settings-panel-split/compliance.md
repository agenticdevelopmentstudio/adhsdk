
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |

Statuses rest on: this file overriding only the four properties that differ
from its base class and delegating every other behavior to
`SplitViewController` rather than reimplementing it
(separation-of-concerns); this file adding no keyboard handling of its own
that could remove a control from the tab order or block default activation,
while the actual keyboard path (search-field arrow keys, split-view tab
order) is inherited and evaluated by `SplitViewController`'s own recipe —
hence `partial` here rather than `passed` (keyboard-navigable); this file
introducing no accessibility role, label, or announcement of its own to
regress, while the rendered role/label surface is likewise
`SplitViewController`'s and `PanelListViewController`'s to evaluate — hence
`partial` here as well (screen-reader-support); and this file rendering no
custom-drawn chrome, composing only inherited AppKit split-view behavior
(native-controls-preference).

`unit-test-coverage` is failed because no test references `SettingsPanelSplitViewController`; the only split-view tests, `ThemedSplitViewOrientationTests.swift`, build its base class `SplitViewController` and assert nothing about the four properties this type overrides.

