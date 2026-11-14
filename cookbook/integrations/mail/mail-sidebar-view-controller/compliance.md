
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | failed | internationalization |

The controller only displays model state and forwards one call, so separation of concerns passes. Unit-test coverage is partial: the model's mailbox building has tests, while the controller and its cells have none. Screen-reader support is partial because mailbox rows have a title label but no unread count and the account group sets no label of its own. Keyboard navigation passes through the native outline, with no custom handling. It uses `NSOutlineView` in the source list style with system fonts and colors, so native controls pass. Contrast is partial because the system secondary label colors on the sidebar material have not been measured in every appearance and selection state. Locale-aware formatting fails because the unread count is built with plain string interpolation, not a number formatter.

Known debt: the view controller has no test of its own, and `MailBrowserModelTests` covers only the data the sidebar displays (mailbox order, depth and unread counts). Planned remedy: add a controller test that builds the sidebar from a model and covers the selection echo guard, the account-and-label selection match and the symbol mapping.

