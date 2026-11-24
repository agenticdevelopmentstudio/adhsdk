
The strings `"OK"` (default confirm label) and `"Working…"` (busy spinner label) are hardcoded in English in `alert-modal.tsx` with no i18n key lookup. The `title`, `description`, `confirmLabel`, and `cancelLabel` props accept caller-supplied strings, permitting localization at the call site. A full i18n framework integration would require centralizing string keys and moving them to a shared resource file.

