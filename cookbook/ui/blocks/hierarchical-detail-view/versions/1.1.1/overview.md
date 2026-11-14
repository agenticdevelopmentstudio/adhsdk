
Hierarchical Detail View is a context provider and routing component that selects between two hierarchical detail view implementations — a cascading menu view and a classic topic view — at the application level. It allows consumers throughout the component tree to render the same logical interface with different disclosure patterns by reading a context value, rather than threading a configuration prop through multiple layers.

The component consists of three exports: a provider component that establishes the context, a hook to read the current view choice, and a router component that consumers render in place of choosing between the two implementations directly.

