
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The group holds list, selection and panel state and leaves windows, shelf
drawing and persistence to other types, so it meets separation-of-concerns. A
search of the package's tests finds none that construct `ProjectWindowGroup`
or `ProjectShelfPanel`, so unit-test coverage fails and the vectors above are
unasserted. The list, selection and persisted state can disagree because
the group itself does not check that the selected id is in the list (the
requirement `selection-not-validated`); the window manager repairs a persisted
selection on restore, so data integrity is partial. The tooltip titles and
placeholders are English literals, so no-hardcoded-strings fails.

