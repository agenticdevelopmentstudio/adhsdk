
- **Decision**: `body` and `title` are plain strings, not `ReactNode`.
  **Rationale**: Site configs are commonly authored as `.ts` modules without JSX support and cannot hold JSX expressions; a string keeps that configuration format available.
  **Approved**: pending

- **Decision**: `useHelpEntry` returns `undefined` for an unknown id or when no provider is mounted, rather than throwing.
  **Rationale**: The first consumer is in the header on every page of every site, so a throw here would turn a typo into a white-screen failure that cascades to every page.
  **Approved**: pending

- **Decision**: `useHelpEntry` uses `Object.hasOwn` to exclude inherited properties (e.g. `constructor`, `toString`) rather than a bare index lookup.
  **Rationale**: `SiteHelp` is a plain object literal and inherits from `Object.prototype`; a bare index access would return function objects for those inherited names instead of `undefined`.
  **Approved**: pending

- **Decision**: `HelpContentProvider` is mounted at the document level rather than passed as a prop to the header component.
  **Rationale**: Some hosts replace the shared header entirely with their own; a prop-based approach would reach only the shared header and miss a replaced one.
  **Approved**: pending

