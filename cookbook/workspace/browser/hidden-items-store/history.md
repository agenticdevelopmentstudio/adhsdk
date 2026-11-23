
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.3 | 2026-11-23 | Mike Fullerton | Moved to the database tier behind BrowserHiddenItemsStoring; the launch store is current (openCurrent, currentStore, hasCurrent). |
| 0.1.2 | 2026-11-16 | Mike Fullerton | Opened off the main thread at launch; reads wait for the open; launch-time callers await sharedStore(). |
| 0.1.1 | 2026-11-16 | Mike Fullerton | Implemented: opened at launch into BrowserHiddenItemsStore.shared; an unopenable file leaves no store. |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
