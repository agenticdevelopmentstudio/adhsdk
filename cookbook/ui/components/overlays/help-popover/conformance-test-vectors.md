
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| help-001 | entry-prop | `entry={ flavor: "help", title: "Help", body: "This is a help message" }` | Component renders without error; body text "This is a help message" appears in the popover |
| help-002 | flavor-icon | `entry={ flavor: "help", title: "", body: "Text" }` | The icon associated with the "help" flavor renders, marked decorative to assistive technology |
| help-003 | flavor-icon | `entry={ flavor: "info", title: "", body: "Text" }` | The icon associated with the "info" flavor renders, marked decorative to assistive technology |
| help-004 | flavor-icon | `entry={ flavor: "new", title: "", body: "Text" }` | The icon associated with the "new" flavor renders, marked decorative to assistive technology |
| help-005 | flavor-icon | `entry={ flavor: undefined, title: "", body: "Text" }` | The "info" flavor icon renders (default flavor) |
| help-006 | body-text | `entry={ flavor: "info", title: "", body: "Help text content" }` | Body text "Help text content" is rendered in a paragraph using the `apt-text-muted` color token |
| help-007 | optional-title | `entry={ flavor: "info", title: "Getting Started", body: "Learn how to use this feature" }` | Title text "Getting Started" renders as a distinct, visually emphasized element positioned above the body text |
| help-008 | optional-title | `entry={ flavor: "info", title: "", body: "Body only" }` | No title element is rendered; only body text appears |
| help-009 | fixed-width | `entry={ flavor: "info", title: "Title", body: "Longer body text that might wrap across multiple lines should still respect the 320px width constraint" }` | Popover panel renders at a fixed width of 320px |
| help-010 | accessible-name | `entry={ flavor: "help", title: "Getting Started", body: "Text" }` | The popover panel's accessible name is `"Help: Getting Started"` |
| help-011 | accessible-name | `entry={ flavor: "info", title: "", body: "Information text" }` | The popover panel's accessible name is `"Information"` |
| help-012 | decorative-icon | `entry={ flavor: "new", title: "Feature Launch", body: "Text" }` | Icon is marked decorative to assistive technology; screen reader skips the icon and announces the panel's accessible name |
| help-013 | color-tokens | `entry={ flavor: "info", title: "Title", body: "Body" }` | Title uses the `apt-text` color token; icon and body use the `apt-text-muted` color token |
| help-014 | side-prop | `side="top"` | Popover positions above anchor |
| help-015 | side-prop | `side="left"` | Popover positions left of anchor |
| help-016 | side-prop | (side prop not provided) | Popover positions below anchor (`"bottom"` default) |
| help-017 | align-prop | `align="center"` | Popover centers along the positioning axis |
| help-018 | align-prop | `align="end"` | Popover aligns to the end of the positioning axis |
| help-019 | align-prop | (align prop not provided) | Popover aligns to the start of the positioning axis (`"start"` default) |
| help-020 | arrow | (any valid entry) | An arrow renders connecting the popover to the anchor |
| help-021 | optional-title | `entry={ flavor: "info", body: "Body only" }` (title omitted entirely) | No title element is rendered; only body text appears — same outcome as an empty-string title |
| help-022 | flavor-icon | `entry={ flavor: null, title: "", body: "Text" }` | The "info" flavor icon renders (default flavor) |
| help-023 | body-text | `entry={ flavor: "info", title: "", body: "" }` | An empty paragraph is rendered for the body; no error occurs |
| help-024 | flavor-icon | `entry={ flavor: "urgent", title: "", body: "Text" }` (a value outside the `HelpFlavor` union) | Component throws while looking up the icon and label; callers MUST NOT pass a flavor outside `"help" \| "info" \| "new"` |

