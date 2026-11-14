
Not applicable: neither file reads a flag or settings key. Every branch is
either a compile-time platform check (`#if canImport(AppKit)`) or a per-item
data value (`paint.fill`), never a runtime feature toggle.

