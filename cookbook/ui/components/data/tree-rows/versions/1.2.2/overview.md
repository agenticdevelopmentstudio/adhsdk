
Tree Rows exposes the nesting structure of hierarchical data within a flat row list. It exports a flatten algorithm that converts parent-child relationships into display order with depth metadata, a helper to compute ancestor expansion paths, and a visual row label component that renders indentation and a collapse-expand toggle. This allows tables, lists, and card grids to display hierarchy without becoming a new component — all existing column logic, sorting, selection, and keyboard behavior remain unchanged.

