
HelpContent is a React context provider and hook system for distributing site-specific help text to UI components. A HelpContentProvider publishes a dictionary of help entries (keyed by component id) to its descendants; consuming components retrieve entries by id using the useHelpEntry hook. Each entry supports an optional title, required body text, and an optional flavor that categorizes the help type (help, info, or new).

