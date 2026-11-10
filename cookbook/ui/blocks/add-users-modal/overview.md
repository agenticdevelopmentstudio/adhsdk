
A modal in `@adh-sdk/ui` for building a list of users to add. It composes
`Dialog` + `DataTable` + `Input` + `UnsavedChangesAlert` + `Button`. Each "Add" appends
the entry row to a table above; the dialog's final "Add" hands the rows to a
caller callback (`onAdd`).

It is a controlled dialog: a growing `DataTable` of staged users on top, an
inline entry row (name / email / phone / admin note) below it with an **Add**
button, and a footer (Cancel / Add).

