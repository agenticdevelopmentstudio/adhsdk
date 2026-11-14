
Not applicable — this is a persistence adapter, not a visual component. The runtime state is two last-seen values (the themes data and the active id) that start as what the domain held at `init` and are updated by this object's own writes and by each detected foreign change; they are covered under Behavioral Requirements.

