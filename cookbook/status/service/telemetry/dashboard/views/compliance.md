
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.localization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | partial | localization |

Separation of concerns passes: the module only derives views from sections, with fetching in the providers and caching in the sectioned-dashboard module. Unit-test coverage passes: `dashboard-views.test.ts` covers each exported area for both pages. Unicode support is partial: names are plain strings and region names come from `Intl.DisplayNames`, but the region names, the `Direct` label and the `what` labels are hardcoded English, the Vercel `(none)` referrer is matched as an English literal, and `localeCompare` is called with no locale.

