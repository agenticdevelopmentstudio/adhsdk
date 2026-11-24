
`CRUD_LETTER` exports the compact single-letter labels `"C"`, `"R"`, `"U"`, `"D"` as hardcoded English, with no localization lookup. The source uses them as short labels: on the permission toggles and in the joined summary of a grant. They are not translated, so a surface that wants a localized label would supply its own, keyed by `CrudKey`, rather than change these values.
