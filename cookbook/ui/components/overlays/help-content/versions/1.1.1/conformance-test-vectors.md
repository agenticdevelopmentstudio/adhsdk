
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| help-content-001 | provide-context, accept-help-data, pass-children | Render `<HelpContentProvider help={{id1: {body: "text"}}} children={<Child />} />` | Child component renders and can access context via useHelpEntry |
| help-content-002 | retrieve-entry-by-id | Call `useHelpEntry("known_id")` with provider mounted and entry present | Returns HelpEntry object with `body` property |
| help-content-003 | return-undefined-on-missing-id | Call `useHelpEntry("unknown_id")` with provider mounted but no matching entry | Returns undefined |
| help-content-004 | return-undefined-on-missing-id | Call `useHelpEntry("any_id")` with `<HelpContentProvider help={{}}>` mounted | Returns undefined for any id, since the dictionary has no entries |
| help-content-005 | no-throw-on-missing-entry | Call `useHelpEntry("any_id")` with no HelpContentProvider mounted | Returns undefined; does not throw |
| help-content-006 | exclude-inherited-properties | Call `useHelpEntry("constructor")` with provider containing only user-defined entries | Returns undefined; inherited Object.prototype properties are excluded |
| help-content-007 | support-three-flavors | Pass `{body: "text", flavor: "help"}` to HelpEntry | Accepted without type error |
| help-content-008 | support-three-flavors | Pass `{body: "text", flavor: "info"}` to HelpEntry | Accepted without type error |
| help-content-009 | support-three-flavors | Pass `{body: "text", flavor: "new"}` to HelpEntry | Accepted without type error |
| help-content-010 | default-flavor-to-info | Retrieve a HelpEntry with no `flavor` property specified | useHelpEntry returns the entry unchanged with `flavor` equal to `undefined`; a consumer reading the entry MUST treat the missing `flavor` as `"info"` |
| help-content-011 | support-optional-title | Pass HelpEntry without `title` property | Entry is valid and accepted; `title` is `undefined` |
| help-content-012 | support-optional-title | Pass HelpEntry with `title: "How this works"` | Entry is valid and accepted; `title` is returned unchanged as `"How this works"` |
| help-content-013 | require-body | Attempt to create HelpEntry without `body` property | Type error; body is required |
| help-content-014 | accept-string-body | Pass `{body: "plain text"}` | Accepted; JSX or ReactNode is not accepted for `body` |
| help-content-015 | accept-string-body | Pass `{body: "multiline\ntext"}` | Accepted; JSX or ReactNode is not accepted for `body` |

