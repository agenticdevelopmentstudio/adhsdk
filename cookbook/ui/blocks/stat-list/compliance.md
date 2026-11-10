
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | partial | Platform Compliance |
| [adc.check.artifact-formatting.recipe-formatting.rf-compliance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dbf80496-0968-5612-bcf7-16c1dbf60d5d) | passed | Artifact Formatting |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The dot carries no `aria-label` while the label + trailing text convey the row's
meaning (screen-reader-support); `StatListRow`/`StatList` render a semantic `li`/`ul`
when `as` requests one (semantic-markup); styling is expressed entirely through
`apt-*` token classes with no raw hex or `!important`, though the dark-mode/
high-contrast wiring those tokens resolve to lives in the themes package rather
than in this source, hence `partial` (platform-theming); and this section now
matches the Check/Status/Category table format with linked, catalog check ids
(rf-compliance); `StatListRow`/`StatList` are pure presentation assembled from
`StatusDot` and caller content with no business logic (separation-of-concerns
passed), and `statList.test.tsx` directly renders both and asserts on their DOM
output (unit-test-coverage passed).

