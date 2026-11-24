
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |

Native-controls-preference and platform-design-language pass because the bar
composes standard SwiftUI controls (`Button`, `Toggle`, `Text`, `Image`) with
system styles (`.borderless`, `.checkbox`) and a system `.popover`, rather
than custom-drawn chrome. Keyboard-navigable is partial: these are standard,
framework-provided controls, but the toggle button uses `.buttonStyle(.borderless)`,
and a borderless SwiftUI button on macOS is only Tab-reachable when Full
Keyboard Access is enabled; no keyboard-navigation test of this bar exists in
source. Screen-reader-support is partial: button and row labels come from visible
`Text` content with no explicit override, but the "server.rack" icon is a
separate, ungrouped accessibility element next to the button (see **Label
requirements** under Accessibility, and **icon-grouping**)
and no explicit announcement accompanies a label or toggle-state change.
String-externalization is failed because the button's three label strings
and the "Unknown" row fallback are unlocalized `String` values with no
string-table lookup (see Localization). Separation-of-concerns passes because
`MCPChipsBarViewModel` owns all registry/binding logic, leaving
`MCPChipsBar` and `MCPServerPicker` as plain rendering of that model's
published state.

`unit-test-coverage` fails because no test file or test mentions `MCPChipsBarView`, `MCPChipsBar` or `MCPChipsBarViewModel` under the Apple test targets, so the active-server toggle logic (`isActive`, `toggle`) is untested.

