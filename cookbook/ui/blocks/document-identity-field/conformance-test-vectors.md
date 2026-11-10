
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-id-001 | render-two-inputs | Component mounted with title="Test" slug="test" | Title and slug inputs both render |
| doc-id-002 | render-title-label, render-slug-label | Component with default labels | "Title" caption sits beside the title input in the shared label column; "Slug" caption sits beside the slug input in the same column |
| doc-id-003 | accept-title-prop | title="Custom Title" | Title input value is "Custom Title" |
| doc-id-004 | accept-slug-prop | slug="custom-slug" | Slug input value is "custom-slug" |
| doc-id-005 | title-change-callback | User types "New" in title input | onTitleChange callback fires with the new title string on each keystroke |
| doc-id-006 | slug-change-callback | User types "new-slug" in slug input | onSlugChange fires once per keystroke; the last call receives the full string "new-slug" |
| doc-id-007 | slug-follows-title | title="" slug="" not touched, slugify=(t)=>t.toLowerCase(); user types "Hello World" | onTitleChange and onSlugChange both fire; slug becomes "hello world" |
| doc-id-008 | stop-auto-slugify-after-manual-edit | User types "Hello" (slug becomes "hello"), then manually edits slug to "custom", then title changes to "New" | Slug remains "custom", does not become "new" |
| doc-id-009 | accept-verdict | verdict={{status:"available", reason:null}} | Status message displays "Available" |
| doc-id-010 | display-verdict-reason | verdict={{status:"unavailable", reason:"Already taken"}} | Status message displays "Already taken", not "Unavailable" |
| doc-id-011 | announce-status-changes | verdict changes from idle to checking to available | aria-live region content changes, assistive tech announces "Checking…" then "Available" |
| doc-id-012 | accept-disabled-prop | disabled=true | Both title and slug inputs have disabled attribute; user cannot edit either |
| doc-id-013 | position-status-in-slug-row | Component rendered | Status message is horizontally adjacent to slug input (same row), not below it |
| doc-id-014 | use-monospace-slug-font | Component rendered | Slug input uses a monospace font at a smaller size than the title input |
| doc-id-015 | container-class-name | className="custom-class" | Container element's class list includes "custom-class" in addition to its own layout classes |
| doc-id-016 | render-title-label, render-slug-label | titleLabel="Document Name" slugLabel="URL Slug" | Title caption reads "Document Name"; slug caption reads "URL Slug" |
| doc-id-017 | display-status-message | verdict left at default ({status:"idle", reason:null}) | Status message renders no text (null) in the slug row |
| doc-id-018 | announce-status-changes | verdict={{status:"unavailable", reason:"Already taken"}} | Slug input's aria-describedby references the status element's id; the status element's text is "Already taken" |

