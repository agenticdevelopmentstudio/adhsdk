
Not fully inert: `CRUD_LETTER` exports the single-letter labels `"C"`, `"R"`, `"U"`, `"D"` as hardcoded English identifiers with no localization lookup. These values MUST be treated as internal identifiers, not user-facing text — a caller MUST NOT display `CRUD_LETTER`'s values directly to end users without localizing them first, and SHOULD instead expose its own localizable label keyed by `CrudKey`.

