
Not applicable: The component does not log anything. A row-width mismatch (**row-width-validation**) throws synchronously, and the error propagates to the nearest error boundary (or aborts the render if none exists) rather than being written to a log.

