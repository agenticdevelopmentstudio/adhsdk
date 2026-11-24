
| Check | Status | Category |
|---|---|---|
| [adc.check.artifact-formatting.recipe-formatting.rf-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6493422b-b843-5a83-85ce-bbbde1ccb576) | passed | artifact-formatting |
| [adc.check.artifact-formatting.recipe-formatting.rf-integration-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bc98f7fa-39c6-5f18-81b0-cc133ac8f529) | passed | artifact-formatting |
| [adc.check.artifact-formatting.recipe-formatting.rf-design-decisions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/4870c831-6dc5-5797-8d40-bbcf4c2bc1fe) | passed | artifact-formatting |
| [adc.check.artifact-formatting.recipe-formatting.rf-compliance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dbf80496-0968-5612-bcf7-16c1dbf60d5d) | passed | artifact-formatting |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | accessibility |
| [adc.check.platform-compliance.deep-linking-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c2a477a7-bd42-5e3f-9ebd-5a64b4b63de4) | passed | platform-compliance |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Keyboard/AT coverage rests on the source's `aria-current`, `aria-hidden`, `inert`, `aria-label` and live-region
(`role="status"`) usage throughout the rail, connector and narrow-pane code; reduced-motion is `partial`
because **respect-reduced-motion** is currently suspended by a standing product decision rather than
removed from the contract (see Design Decisions); deep-linking and native-controls-preference (the narrow
mode's platform-native navigation-controller equivalent) are both MUST requirements the source implements end
to end; and RTL fails because the layout is computed entirely in literal left/right terms (the covered peek's
leading/left cover control, the narrow slide's right-edge push/pop, `translateX` percentages) with no logical
start/end substitution anywhere in the source. `separation-of-concerns` is partial because, although selection
and layout logic is broken out into dedicated hooks and pure functions (`railOnSelect`, `structureSignature`,
`useRailFit`, `useSelectionConnectors`), the cover/pressure calculations that decide which lists are disclosed
(`CoveredStack`, `MinimizedStack`, `NarrowStack`) are computed inline in those components' render bodies rather
than extracted alongside the rest of the logic; `unit-test-coverage` is passed on the nine dedicated test files
(`hierarchicalTopicDetail`, `cascadeRules`, `cascadeInteraction`, `railAutoFit`, `detailSwapContainment`,
`htdvExitGuard`, `breadcrumbLeadingSeparator`, `detailPaneMarker`, `topicDetailCheckable`), which render the real
`HierarchicalTopicDetail` and assert its cascade, exit-guard, rail-fit, and breadcrumb behaviors directly.

