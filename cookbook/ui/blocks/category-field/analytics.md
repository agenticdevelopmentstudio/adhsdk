
Not applicable: CategoryField does not emit analytics events. The host is responsible for instrumentation. If the host needs to track category selection, rename actions, or browse-dialog usage, they must wire callbacks at the host level (onChange, onRename callbacks) to their analytics service.

