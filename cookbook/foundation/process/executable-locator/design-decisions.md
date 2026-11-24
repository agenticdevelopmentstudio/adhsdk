
**Decision**: `PATH` first, then the extra directories.
**Rationale**: A user who put a tool earlier on their own `PATH` meant that copy; the extra directories only rescue a GUI app whose inherited `PATH` lacks them.
**Approved**: pending

**Decision**: The locator holds no tool-specific location.
**Rationale**: It is a shared foundation component (Build From Shared Components); a caller that knows its own tool keeps its installer and version-manager locations beside its own lookup and can pass them in.
**Approved**: pending

**Decision**: `isExecutable` is injected.
**Rationale**: Tests answer from a set of paths and record what was asked, so order and de-duplication are asserted without touching the file system.
**Approved**: pending

