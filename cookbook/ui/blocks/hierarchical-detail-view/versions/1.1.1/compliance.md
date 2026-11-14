
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.artifact-formatting.ingredient-formatting.if-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/083aeeb8-a2fa-5fbc-a3e6-82df9a653872) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-design-decisions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f5b5cbe6-22e8-5954-a18d-0362ee387941) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-change-history](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/14bf2d1d-875b-5e58-b43d-be492c9f941a) | passed | Artifact Formatting |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on this recipe document itself: all required frontmatter fields are present, the Behavioral Requirements use RFC 2119 keywords with subject-only kebab-case names, the Conformance Test Vectors table maps every requirement to at least one ID, Design Decisions follow the Decision/Rationale/Approved format, and the file ends with a Change History table. `separation-of-concerns` passes because `hierarchical-detail-view.tsx` is a thin switch that only picks between `HierarchicalTopicDetail` and `HierarchicalMenuDetail`, with no business logic of its own beyond that dispatch; `unit-test-coverage` fails because no test file imports or renders `HierarchicalDetailView`.

