
The module produces no text of its own except the fallback error message `status <code>`, a hardcoded English string used when the backend's error body carries no message; any backend message is passed through as sent. Views that show the read's error (the analytics view renders `query.error.message`) therefore show untranslated text. The string is not externalized in the source.

