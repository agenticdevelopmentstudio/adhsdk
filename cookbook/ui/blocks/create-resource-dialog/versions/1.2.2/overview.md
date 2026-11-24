
A reusable modal dialog component for creating new resources. The dialog renders a form via a callback, validates input on save, invokes an async creation function, and guards against accidental data loss via an unsaved-changes alert. The dialog is portal-rendered to the document body to avoid stacking context issues from ancestor overflow constraints or inert state.

