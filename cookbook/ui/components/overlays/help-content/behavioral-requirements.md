
- **provide-context**: HelpContentProvider MUST create and provide a React context containing a SiteHelp dictionary to all descendant components.
- **accept-help-data**: HelpContentProvider MUST accept a `help` prop of type `Record<string, HelpEntry>`.
- **pass-children**: HelpContentProvider MUST render its `children` prop unchanged within the context provider.
- **retrieve-entry-by-id**: useHelpEntry MUST retrieve and return the HelpEntry object for a given id string from the context.
- **return-undefined-on-missing-id**: useHelpEntry MUST return undefined when the id does not exist in the help dictionary or no HelpContentProvider is mounted.
- **no-throw-on-missing-entry**: useHelpEntry MUST NOT throw an error when called without a provider or with an unknown id.
- **exclude-inherited-properties**: useHelpEntry MUST return undefined for an id that is not an own property of the help dictionary, even when that id names an inherited `Object.prototype` member (e.g. `constructor`, `toString`). A suggested implementation is `Object.hasOwn`, rather than a bare index lookup.
- **support-three-flavors**: The HelpFlavor type MUST support exactly three values: "help", "info", "new".
- **default-flavor-to-info**: HelpEntry's `flavor` property is optional; when it is absent, a consumer reading the entry MUST treat it as `"info"`. useHelpEntry returns the entry unchanged — a TypeScript interface cannot carry a runtime default — so the default is applied by the consumer, not by the hook.
- **support-optional-title**: HelpEntry MUST accept an optional `title` property; it MAY be omitted.
- **require-body**: HelpEntry MUST require a `body` property as a non-optional field.
- **accept-string-body**: HelpEntry `body` MUST be a string, not a ReactNode or JSX element.

