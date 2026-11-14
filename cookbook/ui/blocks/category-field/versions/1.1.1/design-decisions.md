
- **Decision**: Present the combobox and entity chooser as a flat list of category names rather than a tree walk.
  **Rationale**: Names are unique per owner across the entire hierarchy, so typing a few characters to find a category is faster than navigating a nested tree; breadcrumbs reveal the hierarchy afterwards, making the flat pick legible and showing every place a multi-filed category sits.
  **Approved**: pending

- **Decision**: Rename a category node directly from its breadcrumb, via a modal, rather than only from a separate management screen.
  **Rationale**: Keeps the hierarchy edit co-located with the form and is faster than switching screens; the modal confirm step prevents a stray click on a breadcrumb from renaming a category everywhere it is used.
  **Approved**: pending

- **Decision**: Use a modal dialog (CategoryRenameDialog) for the rename rather than inline editing of the breadcrumb text.
  **Rationale**: Inline editing would require managing edit state, blur/focus behavior, and validation within CategoryField itself; a modal centralizes that complexity, provides a dedicated space for error messages and retry, and keeps the interaction explicit (open, edit, confirm or cancel).
  **Approved**: pending

- **Decision**: Display every filing path as a separate breadcrumb trail, up to a cap of 4 trails (`MAX_TRAILS`), when a category has multiple parents (DAG), rather than picking one to show or walking the whole DAG unbounded.
  **Rationale**: Answers "where is this category filed?" without requiring navigation or a separate view, and is more discoverable than hiding all but one path; a DAG has exponentially many paths, and past a handful the breadcrumb stops being the thing that made the name legible in what is otherwise just a form row, so `categoryTrails` stops walking at 4.
  **Approved**: pending

- **Decision**: Give leaf breadcrumbs a distinct accent color and ancestor breadcrumbs a muted color.
  **Rationale**: Draws attention to the selected category while de-emphasizing the hierarchy above it, following a common breadcrumb-navigation pattern that aids scanning.
  **Approved**: pending

