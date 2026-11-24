
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| list-001 | semantic-list, data-slot | Render `<List />` | Output contains `<ul data-slot="list">` |
| list-002 | semantic-item, data-slot | Render `<ListItem />` | Output contains `<li data-slot="list-item">` |
| list-003 | classname-merge | Render `<List className="custom-class" />` | Output element has both base classes and `custom-class` applied |
| list-004 | classname-merge | Render `<ListItem className="custom-item" />` | Output element has both base classes and `custom-item` applied |
| list-005 | prop-forwarding | Render `<List id="test-list" role="region" />` | Output `<ul>` contains `id="test-list"` and `role="region"` attributes |
| list-006 | prop-forwarding | Render `<ListItem id="item-1" data-test="value" />` | Output `<li>` contains `id="item-1"` and `data-test="value"` attributes |
| list-007 | classname-merge | Render `<ListItem className="px-6" />` | Output `<li>` class list contains `px-6` and does not contain the conflicting base class `px-3` |

