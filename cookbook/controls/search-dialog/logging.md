
Subsystem: `awt` | Category: `SearchDialog`

| Event | Level | Message |
|-------|-------|---------|
| Dialog opened | debug | `SearchDialog: Opened; query reset.` |
| Query changed | debug | `SearchDialog: Query set to "{query}" (length: {count}).` |
| Results fetched | debug | `SearchDialog: {result_count} results; top 20 grouped into {section_count} sections.` |
| Result selected | info | `SearchDialog: Result selected: {slug} (section: {section}, index: {index}).` |
| Keyboard navigation | debug | `SearchDialog: Arrow key navigation; selected index now {index}.` |
| Dialog dismissed | debug | `SearchDialog: Dialog dismissed via {reason} (escape/backdrop).` |

Logging is not implemented in the component source. The events above describe suggested log points a call site or wrapper MAY add around open/close, query changes, and selection — they document a possible logging contract, not one the component enforces.

