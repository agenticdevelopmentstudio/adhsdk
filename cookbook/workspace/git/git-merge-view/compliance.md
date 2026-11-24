
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the view edits choices and reports intents; the file write and the staging are the session's and the model's. `unit-test-coverage` passes: `GitMergeLineModelsTests` covers alignment, fillers, gutters, backgrounds before and after each choice, the result against `resolved` and the colours; `GitMergeViewControllerTests` covers identifiers, navigation and scrolling, the side and base buttons, Save and Cancel, a second show and colouring.
