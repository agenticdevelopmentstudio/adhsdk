
The FAQ component renders a list of questions and answers as a disclosure
list: collapsible widgets where, unlike an accordion, more than one entry can
be open at the same time. Each question appears in a clickable summary;
clicking expands to reveal the answer. Built entirely from native HTML
`<details>` and `<summary>` elements, it requires no JavaScript logic for
expand/collapse behavior. The component supports setting one or more entries
to start in the expanded state. It remains open when printed, and question
text plus the content of any currently open entry is searchable with the
browser's Find function. See [adhsdk.ingredient.ui.components.layout.accordion](cookbook:85ce8c4b-5233-48af-9268-30cddd4747f9) for a
single-open variant of this pattern, and [adhsdk.ingredient.ui.components.layout.disclosure](cookbook:c99e2822-f5a9-4e84-8740-9341880bb82a)
for a single collapsible section.

