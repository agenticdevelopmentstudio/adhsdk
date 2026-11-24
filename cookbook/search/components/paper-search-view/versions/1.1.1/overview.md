
Paper Search View is a React component that provides a search interface for a public paper corpus. It wraps SearchView to handle paper-specific configuration, including API endpoint setup, document type registration, and author filtering. The component is designed to be mounted on both a corpus-wide search page and on individual author index pages, with the only difference being the optional `authorSlug` prop that narrows results to a single author.

